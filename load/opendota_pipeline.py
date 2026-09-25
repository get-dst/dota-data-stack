"""Load Dota 2 pro matches from OpenDota with dlt.

Three kinds of resource:

- ``pro_matches``: the pro-match list, walked backwards from the newest match until
  ``DOTA_SINCE_DAYS`` ago. One call returns 100 matches, so a 90-day window is under
  a hundred calls. Merged on match_id, so re-runs are idempotent.
- ``match_details``: the full record for each pro match not fetched before — one call
  per match, the expensive part. The set of fetched ids lives in dlt state, and each
  run spends at most ``DOTA_MAX_DETAIL_CALLS``, newest first, so a backfill completes
  over a few runs inside the free tier. dlt unnests ``players``, ``picks_bans`` and
  ``objectives`` into child tables.
- ``public_matches``: a sample of public games, ``DOTA_PUBLIC_PAGES`` × 100 per run,
  kept for ``DOTA_PUBLIC_KEEP_DAYS``.
- dimensions (``heroes``, ``items``, ``patches``, ``leagues``, ``teams``, ``pro_players``,
  ``patch_notes``, ``game_modes``, ``lobby_types``): replaced on every run.

Money: OpenDota bills a hundredth of a cent per call on a key and nothing without one
(3 000 a day, 60 a minute). So the key rides only the match-detail calls, where speed
is the point; everything else goes keyless and free. Paid calls are counted in the
``api_usage`` table and stop at ``DOTA_PAID_CALLS_MONTH`` (default 90 000 ≈ $9) —
the cap is in the warehouse, not in a runner's memory, so a fresh CI job cannot
forget it.

Run: ``uv run python load/opendota_pipeline.py``. Target from DSTACK_TARGET (see
.env.example).
"""

from __future__ import annotations

import os
import sys
import time
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import dlt
import requests
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

API = "https://api.opendota.com/api"
SESSION = requests.Session()
_KEY = os.environ.get("OPENDOTA_API_KEY") or None
_FREE_INTERVAL_S = 1.05  # keyless: 60 a minute
_PAID_INTERVAL_S = 0.05  # keyed: 3 000 a minute allowed; no reason to use it
_last_call = 0.0
CALLS = {"free": 0, "paid": 0}
_PAID = {"remaining": int(os.environ.get("DOTA_PAID_CALLS_MONTH", "90000"))}


class PaidBudgetExhausted(RuntimeError):
    """The month's paid-call cap is spent. Loud, never silent: the run stops
    fetching details and says so; everything keyless still runs."""


# Match-detail fields that are large per-second arrays, chat, or cosmetics — not
# analytics. Dropped before the row is stored; everything else is kept.
_DROP_MATCH = {
    "chat",
    "cosmetics",
    "all_word_counts",
    "my_word_counts",
    "teamfights",
    "draft_timings",
    "radiant_gold_adv",
    "radiant_xp_adv",
    "od_data",
    "metadata",
    "pauses",
    "replay_url",
    "replay_salt",
    "engine",
    "flags",
    "radiant_logo",
    "dire_logo",
}
_DROP_PLAYER = {
    "ability_targets",
    "ability_upgrades_arr",
    "ability_uses",
    "actions",
    "benchmarks",
    "buyback_log",
    "connection_log",
    "cosmetics",
    "damage",
    "damage_inflictor",
    "damage_inflictor_received",
    "damage_targets",
    "damage_taken",
    "dn_t",
    "gold_reasons",
    "gold_t",
    "hero_damage_t",
    "hero_healing_t",
    "hero_hits",
    "item_usage",
    "item_uses",
    "item_win",
    "kill_streaks",
    "killed",
    "killed_by",
    "kills_log",
    "lane_pos",
    "lh_t",
    "life_state",
    "max_hero_hit",
    "multi_kills",
    "obs",
    "obs_left_log",
    "obs_log",
    "permanent_buffs",
    "pings",
    "purchase",
    "purchase_time",
    "runes",
    "runes_log",
    "sen",
    "sen_left_log",
    "sen_log",
    "times",
    "xp_reasons",
    "xp_t",
    "first_purchase_time",
    "deaths_log",
    "camps_stacked_t",
    "healing",
    "neutral_tokens_log",
    "neutral_item_history",
    "networth_t",
}


class Unavailable(RuntimeError):
    """OpenDota answered 5xx for this path after retries. The key never rides the
    message: requests puts the full URL in its errors, and the URL carries it."""


def get(path: str, *, paid: bool = False, **params: Any) -> Any:
    global _last_call
    paid = paid and _KEY is not None
    if paid and _PAID["remaining"] <= 0:
        raise PaidBudgetExhausted("DOTA_PAID_CALLS_MONTH reached for this month")
    wait = (_PAID_INTERVAL_S if paid else _FREE_INTERVAL_S) - (time.monotonic() - _last_call)
    if wait > 0:
        time.sleep(wait)
    if paid:
        params["api_key"] = _KEY
    # A 5xx from OpenDota on a match is nearly always "cannot fetch this one", not a
    # blip: one quick retry, then give the id up for this run. A run that slept a
    # minute per bad match once crawled for nine hours on a few hundred of them.
    last = "no attempt"
    for attempt in range(3):
        try:
            r = SESSION.get(f"{API}/{path}", params=params, timeout=60)
        except requests.RequestException as exc:
            time.sleep(2 * (attempt + 1))
            last = f"{type(exc).__name__}"
            continue
        _last_call = time.monotonic()
        if r.status_code == 429:
            time.sleep(10 * (attempt + 1))
            last = "HTTP 429"
            continue
        if r.status_code >= 500:
            last = f"HTTP {r.status_code}"
            if attempt >= 1:
                break
            time.sleep(2)
            continue
        if r.status_code >= 400:
            raise Unavailable(f"{path}: HTTP {r.status_code}")
        CALLS["paid" if paid else "free"] += 1
        if paid:
            _PAID["remaining"] -= 1
        return r.json()
    raise Unavailable(f"{path}: {last}")


@dlt.resource(primary_key="match_id", write_disposition="merge")
def pro_matches(since_days: int) -> Iterator[list[dict[str, Any]]]:
    cutoff = time.time() - since_days * 86400
    before: int | None = None
    while True:
        page = get("proMatches", **({"less_than_match_id": before} if before else {}))
        if not page:
            return
        keep = [m for m in page if m["start_time"] >= cutoff]
        if keep:
            yield keep
        if len(keep) < len(page) or len(page) < 100:
            return
        before = page[-1]["match_id"]


# Detail calls spent in THIS process — the per-run budget. The fetched-id set is
# the durable state; this counter must not be, or a second run would start spent.
_SPENT = {"calls": 0, "started": time.monotonic()}


@dlt.resource(primary_key="match_id", write_disposition="merge")
def public_matches(pages: int) -> Iterator[list[dict[str, Any]]]:
    """A sample of public matchmaking games: the newest ``pages`` × 100 at run time,
    walked backwards. One call carries the winner, duration, average rank tier and
    the ten hero ids — enough for hero win rates by bracket, matchups and duos,
    with no per-match detail call. Rows still in progress (duration 0, hero ids
    0) are skipped; they come back complete on a later run. Sampling is by run
    time, so an hourly schedule spreads it across the day; the lens says
    "a sample", never "all public matches"."""
    before: int | None = None
    for _ in range(pages):
        page = get("publicMatches", **({"less_than_match_id": before} if before else {}))
        if not page:
            return
        done = [
            m
            for m in page
            if m.get("duration")
            and all(m.get("radiant_team") or [0])
            and all(m.get("dire_team") or [0])
        ]
        if done:
            yield done
        if len(page) < 100:
            return
        before = page[-1]["match_id"]


def _trim(match: dict[str, Any]) -> dict[str, Any]:
    out = {k: v for k, v in match.items() if k not in _DROP_MATCH}
    out["players"] = [
        {k: v for k, v in p.items() if k not in _DROP_PLAYER} for p in match.get("players") or []
    ]
    for side in ("radiant_team", "dire_team", "league"):
        if isinstance(out.get(side), dict):
            out[side] = {
                k: v
                for k, v in out[side].items()
                if k in ("team_id", "name", "tag", "leagueid", "tier")
            }
    return out


@dlt.transformer(data_from=pro_matches, primary_key="match_id", write_disposition="merge")
def match_details(matches: list[dict[str, Any]], max_calls: int) -> Iterator[dict[str, Any]]:
    """One detail call per match not fetched before; newest first; bounded per run."""
    state = dlt.current.resource_state()
    fetched: set[int] = set(state.setdefault("fetched_ids", []))
    failed: dict[str, int] = state.setdefault("failed_ids", {})
    for m in sorted(matches, key=lambda x: -x["match_id"]):
        mid = m["match_id"]
        if mid in fetched or failed.get(str(mid), 0) >= 2:
            continue  # fetched, or unavailable twice: OpenDota does not have it
        if _SPENT["calls"] >= max_calls:
            return
        try:
            d = get(f"matches/{mid}", paid=True)
        except PaidBudgetExhausted as exc:
            print(f"match_details: stopped — {exc}")
            return
        except Unavailable:
            # One bad match must not sink the run; it gets one more try next run.
            failed[str(mid)] = failed.get(str(mid), 0) + 1
            state["failed_ids"] = failed
            _SPENT["calls"] += 1
            continue
        _SPENT["calls"] += 1
        if not d.get("players"):
            continue  # not parsed yet on OpenDota's side; try again next run
        fetched.add(mid)
        state["fetched_ids"] = sorted(fetched)
        if _SPENT["calls"] % 100 == 0:
            elapsed = time.monotonic() - _SPENT["started"]
            print(
                f"match_details: {_SPENT['calls']} calls, {elapsed:.0f}s, "
                f"{_SPENT['calls'] / max(elapsed, 1):.1f}/s",
                file=sys.stderr,
                flush=True,
            )
        yield _trim(d)


def _dimension(name: str, path: str, *, key: str) -> Any:
    @dlt.resource(name=name, primary_key=key, write_disposition="replace")
    def rows() -> Iterator[list[dict[str, Any]]]:
        data = get(path)
        if isinstance(data, dict):  # constants come keyed by id
            data = [
                {key: k, **(v if isinstance(v, dict) else {"value": v})} for k, v in data.items()
            ]
        yield data

    return rows


@dlt.resource(name="patch_notes", write_disposition="replace")
def patch_notes() -> Iterator[list[dict[str, Any]]]:
    """OpenDota's patch notes, one row per line: patch, section (general | items |
    heroes), subject (a hero or item key, or 'general'), the ability or heading the
    line sits under when there is one, and the note. Hero notes nest one level
    (hero -> ability -> lines); the flattening keeps that as ``heading``."""
    data = get("constants/patchnotes")
    rows: list[dict[str, Any]] = []

    def lines(node: Any, heading: str | None) -> Iterator[tuple[str | None, str]]:
        if isinstance(node, str):
            yield heading, node
        elif isinstance(node, list):
            for item in node:
                yield from lines(item, heading)
        elif isinstance(node, dict):
            for key, val in node.items():
                yield from lines(val, str(key))

    for patch_key, sections in data.items():
        patch_name = patch_key.replace("_", ".")
        if not isinstance(sections, dict):
            continue
        for section, body in sections.items():
            subjects = body.items() if isinstance(body, dict) else [("general", body)]
            for subject, notes in subjects:
                for i, (heading, text) in enumerate(lines(notes, None)):
                    if text.strip() in ("", "<br>"):
                        continue
                    rows.append(
                        {
                            "patch_name": patch_name,
                            "section": section,
                            "subject": subject,
                            "heading": heading,
                            "line_no": i,
                            "note": text,
                        }
                    )
    yield rows


@dlt.source
def opendota(since_days: int, max_calls: int, public_pages: int) -> Any:
    return [
        pro_matches(since_days),
        pro_matches(since_days) | match_details(max_calls),
        public_matches(public_pages),
        _dimension("heroes", "heroes", key="id"),
        _dimension("items", "constants/items", key="name"),
        _dimension("patches", "constants/patch", key="id"),
        _dimension("leagues", "leagues", key="leagueid"),
        _dimension("teams", "teams", key="team_id"),
        _dimension("pro_players", "proPlayers", key="account_id"),
        patch_notes(),
        _dimension("game_modes", "constants/game_mode", key="id"),
        _dimension("lobby_types", "constants/lobby_type", key="id"),
    ]


def destination() -> Any:
    target = os.environ.get("DSTACK_TARGET", "duckdb")
    if target == "postgres":
        url = os.environ["DATABASE_URL"]
        return dlt.destinations.postgres(url)
    if target == "motherduck":
        # One MotherDuck database holds raw + marts; the token is a read-write one.
        return dlt.destinations.motherduck(
            credentials={
                "database": os.environ.get("MOTHERDUCK_DATABASE", "dota"),
                "password": os.environ["MOTHERDUCK_TOKEN"],
            }
        )
    path = Path(os.environ.get("DSTACK_DUCKDB_PATH", "data/dota.duckdb"))
    path.parent.mkdir(parents=True, exist_ok=True)
    return dlt.destinations.duckdb(str(path))


def main() -> None:
    since = int(os.environ.get("DOTA_SINCE_DAYS", "90"))
    budget = int(os.environ.get("DOTA_MAX_DETAIL_CALLS", "2500"))
    public_pages = int(os.environ.get("DOTA_PUBLIC_PAGES", "60"))
    pipeline = dlt.pipeline(
        pipeline_name="opendota",
        destination=destination(),
        dataset_name="raw",
        pipelines_dir=str(Path(__file__).resolve().parent / ".dlt"),
    )
    month = time.strftime("%Y-%m")
    keep_days = int(os.environ.get("DOTA_PUBLIC_KEEP_DAYS", "60"))
    with pipeline.sql_client() as c:
        try:
            used = c.execute_sql(
                "SELECT coalesce(sum(paid_calls), 0) FROM api_usage WHERE month = %s", month
            )[0][0]
        except Exception:  # first run: no usage table yet
            used = 0
        _PAID["remaining"] -= int(used or 0)
    print(f"paid calls this month so far: {used}; remaining under the cap: {_PAID['remaining']}")

    src = opendota(since, budget, public_pages)
    info = pipeline.run(src)
    print(info)
    pipeline.run(
        [
            {
                "month": month,
                "run_at": time.time(),
                "paid_calls": CALLS["paid"],
                "free_calls": CALLS["free"],
            }
        ],
        table_name="api_usage",
        write_disposition="append",
    )
    print(f"this run: {CALLS['paid']} paid calls, {CALLS['free']} free calls")

    cutoff = int(time.time() - keep_days * 86400)
    with pipeline.sql_client() as c:
        for child in ("public_matches__radiant_team", "public_matches__dire_team"):
            c.execute_sql(
                f"DELETE FROM {child} WHERE _dlt_parent_id IN "
                f"(SELECT _dlt_id FROM public_matches WHERE start_time < {cutoff})"
            )
        c.execute_sql(f"DELETE FROM public_matches WHERE start_time < {cutoff}")
    with pipeline.sql_client() as c:
        tables = ("pro_matches", "match_details", "match_details__players", "public_matches")
        for t in tables:
            try:
                n = c.execute_sql(f"SELECT count(*) FROM {t}")[0][0]
                print(f"{t}: {n}")
            except Exception as exc:  # table absent on a first partial run
                print(f"{t}: - ({str(exc)[:60]})")


if __name__ == "__main__":
    main()

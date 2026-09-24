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
- dimensions (``heroes``, ``items``, ``patches``, ``leagues``, ``teams``, ``game_modes``,
  ``lobby_types``): replaced on every run.

Run: ``uv run python load/opendota_pipeline.py``. Target from DSTACK_TARGET (see
.env.example).
"""

from __future__ import annotations

import os
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
# Free tier: 60/min. Space calls so a run never trips it; a key removes the wait.
_MIN_INTERVAL_S = 0.0 if _KEY else 1.05
_last_call = 0.0

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
    "purchase_log",
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


def get(path: str, **params: Any) -> Any:
    global _last_call
    wait = _MIN_INTERVAL_S - (time.monotonic() - _last_call)
    if wait > 0:
        time.sleep(wait)
    if _KEY:
        params["api_key"] = _KEY
    for attempt in range(4):
        r = SESSION.get(f"{API}/{path}", params=params, timeout=60)
        _last_call = time.monotonic()
        if r.status_code == 429:
            time.sleep(10 * (attempt + 1))
            continue
        r.raise_for_status()
        return r.json()
    raise RuntimeError(f"OpenDota kept rate-limiting {path}")


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
_SPENT = {"calls": 0}


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
    for m in sorted(matches, key=lambda x: -x["match_id"]):
        mid = m["match_id"]
        if mid in fetched:
            continue
        if _SPENT["calls"] >= max_calls:
            return
        d = get(f"matches/{mid}")
        _SPENT["calls"] += 1
        if not d.get("players"):
            continue  # not parsed yet on OpenDota's side; try again next run
        fetched.add(mid)
        state["fetched_ids"] = sorted(fetched)
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


@dlt.source
def opendota(since_days: int, max_calls: int) -> Any:
    return [
        pro_matches(since_days),
        pro_matches(since_days) | match_details(max_calls),
        _dimension("heroes", "heroes", key="id"),
        _dimension("items", "constants/items", key="name"),
        _dimension("patches", "constants/patch", key="id"),
        _dimension("leagues", "leagues", key="leagueid"),
        _dimension("teams", "teams", key="team_id"),
        _dimension("game_modes", "constants/game_mode", key="id"),
        _dimension("lobby_types", "constants/lobby_type", key="id"),
    ]


def destination() -> Any:
    target = os.environ.get("DSTACK_TARGET", "duckdb")
    if target == "postgres":
        url = os.environ["DATABASE_URL"]
        return dlt.destinations.postgres(url)
    path = Path(os.environ.get("DSTACK_DUCKDB_PATH", "data/dota.duckdb"))
    path.parent.mkdir(parents=True, exist_ok=True)
    return dlt.destinations.duckdb(str(path))


def main() -> None:
    since = int(os.environ.get("DOTA_SINCE_DAYS", "90"))
    budget = int(os.environ.get("DOTA_MAX_DETAIL_CALLS", "2500"))
    pipeline = dlt.pipeline(
        pipeline_name="opendota",
        destination=destination(),
        dataset_name="raw",
        pipelines_dir=str(Path(__file__).resolve().parent / ".dlt"),
    )
    src = opendota(since, budget)
    info = pipeline.run(src)
    print(info)
    with pipeline.sql_client() as c:
        for t in ("pro_matches", "match_details", "match_details__players", "heroes", "patches"):
            try:
                n = c.execute_sql(f"SELECT count(*) FROM {t}")[0][0]
                print(f"{t}: {n}")
            except Exception as exc:  # table absent on a first partial run
                print(f"{t}: - ({str(exc)[:60]})")


if __name__ == "__main__":
    main()

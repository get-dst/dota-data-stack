# dota-data-stack

Dota 2 match data, from OpenDota's API to a governed answer in your own AI. Four tools,
each doing one job: **dlt** loads, **dbt** transforms, **MotherDuck** holds it, and
**dst (data serve tool)** serves it to Claude, ChatGPT or any MCP client, with the SQL and
a receipt on every answer.

![OpenDota → dlt → MotherDuck (raw → dbt → marts) → dst → your AI](docs/architecture.svg)

On 25 September 2026 the warehouse held 1,587 professional matches (every pro match since
27 June, with full match detail), 15,870 player rows, and 34,620 public matchmaking games
with their rank bracket. A GitHub Actions job adds whatever is new every hour.

## Ask it

Real questions against the live warehouse, answered by the lenses in `serve/`, verbatim
except where cut with `…`.

**A typed answer.** Every slot of the query (metric, filters, bracket) was picked from the
declared semantic layer, so the SQL is compiled, not written by a model.

```
pub_meta › What is Anti-Mage's win rate at Divine?

Anti-Mage's win rate at Divine is 0.4803921568627451, per the hero_win_rate definition
(total wins divided by total games). …ranked All Pick only — Turbo and unranked games
are excluded.

status ok · typed · tag declared · confidence verified · data as of 2026-09-25
SELECT pub_hero_stats.bracket_name AS bracket_name,
       CAST(SUM(pub_hero_stats.wins) AS DOUBLE) / NULLIF(SUM(pub_hero_stats.games), 0) AS hero_win_rate
FROM marts.pub_hero_stats AS pub_hero_stats
WHERE pub_hero_stats.bracket_name = 'Divine' AND pub_hero_stats.hero_name = 'Anti-Mage'
  AND (pub_hero_stats.game_type = 'ranked_all_pick')
GROUP BY pub_hero_stats.bracket_name
```

The `game_type = 'ranked_all_pick'` line is not in the question. The table declares that
population, so every query over it carries the filter.

**A ranking over a governed term.** "The current patch" is a declared fact from the
patches table, not a guess from match dates.

```
pro_meta › Which hero was banned most on the current patch?

On the current patch (7.41), Lone Druid was banned most, with 880 total bans — ahead of
Treant Protector (830) and Shadow Fiend (676) …

status ok · typed · tag declared · confidence verified · data as of 2026-09-25
```

**A question that does not type, answered and disclosed.** A team can be the Radiant or the
Dire side, which the typed path cannot express, so the lens falls back to model-written
SQL and says so on the answer.

```
pro_meta › How many matches did Team Spirit play?

Team Spirit played 44 matches, counting distinct match IDs in the player-match data …

status ok · untyped · tag inferred · data as of 2026-09-25
UNTYPED: served by raw-SQL generation — the question did not type: The question names
'Team Spirit', a stored value of dire_team_name, radiant_team_name, but no filter of the
answer uses it. …
```

**A refusal.** The public sample is ranked All Pick only. A question about Turbo is
refused before any query runs, with the reason, instead of returning an empty ranking.

```
pub_meta › What is the best hero in Turbo?

I can't answer this from this lens's data: The public-sample tables are governed by a
required filter of game_type = 'ranked_all_pick' and explicitly exclude Turbo games, so
hero performance in Turbo cannot be answered from this model.

status refused
```

## The four layers

**dlt** (`load/opendota_pipeline.py`) pulls the pro-match list, one detail record per
match with its purchase log, the newest public matchmaking games with their rank tier, and
the dimension tables: heroes, items, patches, patch notes, leagues, teams, pro players.
Rows merge on their keys, so a re-run changes nothing it already loaded. Only the
match-detail calls need an OpenDota key. Before buying details, each run reads which
matches the warehouse already holds and skips them; every paid call is counted in an
`api_usage` table and a monthly ceiling (`DOTA_PAID_CALLS_MONTH`) stops the run when
reached. `.github/workflows/load.yml` runs load and transform every hour.

**dbt** (`transform/`) turns 29 raw tables into 12 staging views and 22 marts: one row
per pro match, one per player per match with a derived position, every pick and ban, item
builds and timings per hero, team head-to-head, league standings, patch notes; and over
the public sample, hero stats by rank bracket, matchups, duos, daily trends, and win rate
by game length. 25 tests pin the grains. Every model and all 261 mart columns are
documented, and `persist_docs` writes those descriptions into the warehouse as comments.
Match dates are the UTC date, pinned in SQL, whoever runs dbt.

**MotherDuck** holds both the raw tables and the marts in one database, `md:dota`. dlt and
dbt write with a read-write token; dst reads through its own connection, opened read-only,
so nothing served can write. Switching dlt and dbt between MotherDuck, a local DuckDB
file and Postgres is one variable, `DSTACK_TARGET`; dst's side is the `warehouse` block in
`serve/dst.yaml`.

**dst** (`serve/`) declares what the marts mean: 21 entities with their metrics, the 32
joins between them, 16 governed terms (bracket, position, counter, synergy, the current
patch, the minimum-games rule), what each lens must refuse (MMR, prize money, personal
match history, items in pubs), and which end of a metric is the better one. Three lenses:
`pro_meta` over professional matches, `pro_players` over the players in them, and
`pub_meta` over the public sample. Answers are typed first, compiled from the declared
layer, and fall back to disclosed model-written SQL only when a question cannot be typed.
`dst probe` reads the warehouse's own column descriptions, value lists for the declared
dimensions (127 heroes, every team), and each table's freshness.

## Tests on every pull request

`.github/workflows/dst-test.yml` runs on every pull request that touches `serve/` or
`transform/`: it starts a throwaway dst server, applies the semantic layer, and runs
every lens's test suite against the live warehouse. What an enthusiast asks must answer;
what the data cannot carry must refuse by name. A failing case fails the pull request, and
an empty suite fails it too, since a suite that ran nothing proved nothing.

## Run it yourself

```
cp .env.example .env              # MotherDuck token, or DSTACK_TARGET=duckdb for a local file
uv sync
make load                         # keyless works: 3,000 calls a day; a key speeds up match details
make transform
```

To serve, dst needs a Postgres of its own for its state and a model. Fill
`DST_API_KEY_DEEPSEEK` and `DST_API_KEY_JEV` in `serve/.env` (or change the providers in
`serve/dst.yaml`), then:

```
pip install 'dst-core[local-embed]'
cd serve && dst dev               # Postgres up + migrate + serve
dst bootstrap --org dota          # once: an org and an admin token, saved to .env
dst probe                         # column descriptions, value lists, freshness
dst apply                         # entities, joins, terms, lenses; runs the eval gate
dst query pro_meta "Which hero was banned most on the current patch?"
dst test pub_meta
```

`dst apply` probes the warehouse before anything lands and blocks a lens whose test
suite got worse than the version it would replace.

## Where the governed layer earns its keep

The data has the traps a semantic layer exists for. "Win rate" needs a denominator: a
hero's games, a team's matches, or the Radiant side of every match, and the terms in
`serve/semantic/definitions/` say which. "The current patch" is a declared fact from the
patches table, not a guess from match dates. The public numbers come from a sample, and
every answer over them says so. A rate over three games is noise, so the lenses carry a
minimum-games rule and report rates with their counts. Turbo is a different game and never
blends into the ranked meta. Pro matches carry no MMR and no prize money, and the public
feed carries no items and no player identities, so each lens refuses those questions
instead of approximating them. Each of those is a file in `serve/`, and each is a place
where the answer would otherwise have been plausible and wrong.

## Layout

```
load/opendota_pipeline.py        dlt: OpenDota → raw
transform/                       dbt: raw → staging → marts, documented and tested
serve/                           dst: dst.yaml, semantic/, lenses/, profiles/
.github/workflows/load.yml       hourly load + transform
.github/workflows/dst-test.yml   dst tests on every pull request
docs/architecture.svg            the diagram above
```

Data from [OpenDota](https://www.opendota.com/), under their API terms.

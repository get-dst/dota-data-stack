# dota-data-stack

Dota 2 match data, from OpenDota's API to a governed answer in your own AI. Four tools,
each doing one job: **dlt** loads, **dbt** transforms, **MotherDuck** holds it, and
**dst (data serve tool)** serves it to Claude, ChatGPT or any MCP client, with the SQL and
a receipt on every answer.

![OpenDota → dlt → MotherDuck (raw → dbt → marts) → dst → your AI](docs/architecture.svg)

On 26 September 2026 the warehouse held 22,890 professional matches, a full year back to
26 September 2025, each with its complete detail: 9.2 million item purchases, every pick
and ban, every objective, the per-minute gold and experience curves, and what happened
inside the match (166,677 teamfights, with the damage, wards, runes and buybacks around
them). That is 228,900 player rows, next to 41,859 public matchmaking games with their
rank bracket. A GitHub Actions job adds whatever is new every hour.

## Ask it

Real questions against the live warehouse, answered by the lenses in `serve/`, verbatim
except where cut with `…`.

**A typed answer.** Every slot of the query (metric, filters, bracket) was picked from the
declared semantic layer, so the SQL is compiled, not written by a model.

```
pub_meta › What is Anti-Mage's win rate at Divine?

Anti-Mage's hero win rate in the Divine bracket is 0.47085201793721976 (wins divided by
games, ranked All Pick only, per the hero_win_rate definition). This covers only a sample
of public matchmaking games, ranked All Pick — Turbo and unranked games are excluded.

status ok · typed · tag declared · confidence verified · data as of 2026-09-26
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
drafts › Which hero is contested most on the current patch?

Pangolier is the most-contested hero on the current patch, with 4,451 contests, ahead of
Rubick (4,433) … These figures cover only Captains Mode professional matches whose draft
OpenDota recorded, so they exclude pro matches in other game modes or without a recorded
draft.

status ok · typed · tag declared · confidence verified · data as of 2026-09-26
```

**A certified answer.** The question matched one a person approved, so the approved SQL
ran as written.

```
pro_meta › How often does the side that kills Roshan first win on the current patch?

On the current patch, the side that takes the first Roshan wins 0.7788990825688074 of the
time. This covers only Professional matches in the loaded window in which a side actually
took the objective; matches with no Roshan kill or no objective log are excluded.

status ok · typed · tag certified · confidence verified · data as of 2026-09-25
```

**A question that does not type, answered and disclosed.** No declared metric counts a
team's matches, so the lens falls back to model-written SQL and tags the answer inferred,
with the inferred expression on the receipt.

```
pro_meta › How many matches did Team Spirit play?

Team Spirit played 275 matches, counting distinct match IDs in the loaded window — which
covers only every player in every professional match in that window, so this is not a
complete career total.

status ok · untyped · tag inferred · data as of 2026-09-25
SELECT COUNT(DISTINCT player_performances.match_id) AS matches
FROM marts.fact_player_match AS player_performances
WHERE player_performances.team_name = 'Team Spirit'
resolution: inferred (inferred: COUNT(DISTINCT player_performances.match_id))
```

**A concept with no column.** "Wins the lane" is a governed term (400 gold ahead at minute
10, laners matched by map lane), so the answer carries the rule, the position filter and
the games floor.

```
playstyle › Which carry heroes win their lane most often on the current patch?

Kunkka wins his lane most often among carry heroes on the current patch, with a lane win
rate of 0.5789473684210527 (lanes won divided by lane games), ahead of Leshrac
(0.5384615384615384), Marci (0.52) and Void Spirit (0.5). These figures cover only
Player-games in parsed professional matches in the loaded window, filtered to the carry
position and to heroes with at least 10 games …

status ok · typed · tag declared · confidence partial · data as of 2026-09-25
```

**A refusal.** The public sample is ranked All Pick only. A question about Turbo is
refused before any query runs, with the reason, instead of returning an empty ranking.

```
pub_meta › What is the best hero in Turbo?

I can't answer this from this lens's data: Turbo games are not covered by this model — the
public hero tables (pub_hero_stats, pub_matchups, pub_duos) are restricted to ranked All
Pick only (required filter game_type = 'ranked_all_pick'), so hero performance data for
Turbo does not exist here.

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

**dbt** (`transform/`) turns the raw tables into 22 staging views and 47 marts, in five
areas:

- **Matches and heroes**: one row per pro match, one per player per match with a derived
  position, heroes per patch and per position, patch-over-patch trends, team head-to-head,
  league standings, patch notes; and over the public sample, hero stats by rank bracket,
  matchups, duos, daily trends, and win rate by game length.
- **Itemization** (`marts/items/`): a major-item definition (a completed item of at least
  2,000 gold, or one with its own active), the first, second and third major item per hero
  with their timings, win rate by purchase-minute window, starting items and whole starting
  builds, and end-of-game inventories with neutral items by tier.
- **Drafts** (`marts/drafts/`): every pick and ban with its draft phase, per-hero first-pick,
  last-pick and contest rates, pro hero-versus-hero draft matchups, lane partners, team
  lineups and signature heroes.
- **Timings** (`marts/timings/`): the gold and experience lead per minute, the lead at 10,
  15, 20 and 25 minutes, comebacks from 10,000 gold behind, and first blood, first tower
  and first Roshan with how often the side that took them won.
- **Behaviour** (`marts/behaviour/`): how a match was played. Teamfight participation from
  OpenDota's fight windows, farm priority as each player's share of the side's gold at 10
  and 20 minutes, lane outcomes at minute 10 matched by map lane, a declared proxy for
  space created (damage absorbed from enemy heroes, and deaths traded for a tower or
  Roshan, kept as two numbers), wards, runes and buybacks, rolled up per hero and
  position and per player, by patch.

88 tests pin the grains, the draft shape and the behaviour sums. Every model and all 785
mart columns are documented, and `persist_docs` writes those descriptions into the warehouse as comments.
Match dates are the UTC date, pinned in SQL, whoever runs dbt.

**MotherDuck** holds both the raw tables and the marts in one database, `md:dota`. dlt and
dbt write with a read-write token; dst reads through its own connection, opened read-only,
so nothing served can write. Switching dlt and dbt between MotherDuck, a local DuckDB
file and Postgres is one variable, `DSTACK_TARGET`; dst's side is the `warehouse` block in
`serve/dst.yaml`.

**dst** (`serve/`) declares what the marts mean: 46 entities with their metrics, the 97
joins between them, 34 governed terms (bracket, position, major item, first pick, counter,
comeback, lane outcome, farm share, fight participation, space created as a declared
proxy, the current patch, the minimum-games rule), what each lens must refuse (MMR, prize
money, personal match history, items in pubs, what players said or intended), and which
end of a metric is the better one. Six lenses, each the one home for its kind of question:

| lens | answers |
|---|---|
| `pro_meta` | professional matches: heroes per patch and position, teams, leagues, gold leads, comebacks, objectives |
| `pro_players` | the players in them: who plays what, how well, for which team |
| `drafts` | picks and bans, draft phases, contested heroes, draft counters, lineups |
| `items` | item builds, core items, timings, starting items, neutral items |
| `playstyle` | how pros play: fights, farm priority, lane outcomes, space, vision and runes, by hero, position and player |
| `pub_meta` | the public sample: heroes by rank bracket, counters, duos, trends |

Answers are typed first, compiled from the declared layer, and fall back to disclosed
model-written SQL only when a question cannot be typed.
`dst probe` reads the warehouse's own column descriptions, value lists for the declared
dimensions (127 heroes, every team), and each table's freshness.

## Tests on every pull request

`.github/workflows/dst-test.yml` runs on every pull request that touches `serve/` or
`transform/`: it starts a throwaway dst server, applies the semantic layer, and runs
every lens's test suite against the live warehouse (123 checks across the six lenses).
What an enthusiast asks must answer;
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
instead of approximating them. "Space" has no column anywhere, so the playstyle lens
declares a proxy in two parts, never adds them, and says so on every answer. Each of those is a file in `serve/`, and each is a place
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

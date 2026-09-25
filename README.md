# dota-data-stack

Professional Dota 2 matches, from OpenDota's API to a governed answer in your own AI,
in three stages that each do one job:

- **dlt** loads. `load/opendota_pipeline.py` pulls the pro-match list, one detail record
  per match with its purchase log, a sample of public matchmaking games with their rank
  tier, and the dimension tables (heroes, items, patches, patch notes, leagues, teams,
  pro players) into raw tables. Merged on match id, so re-runs are idempotent. Only the
  match-detail calls use an OpenDota key; everything else is keyless and free, and the
  paid calls are counted in the warehouse and capped per month.
- **dbt** transforms. `transform/` turns the raw tables into marts: one row per pro
  match, one per player per match with a derived position and the pro's name, every pick
  and ban, item builds and item timings per hero, team head-to-head, league standings,
  patch notes by hero and item; and over the public sample, hero stats by rank bracket,
  hero-versus-hero matchups, same-side duos, daily trends, and win rate by game length.
  Grain tests pin the shapes.
- **dst (data serve tool)** serves. `serve/` declares what the marts mean: fifteen
  entities with their metrics, the joins between them, the governed terms (bracket,
  position, counter, synergy, the current patch, the minimum-games rule), what each lens
  must refuse (MMR, prize money, personal match history, items in pubs), and the
  questions that are certified. Three lenses: `pro_meta` over professional matches,
  `pro_players` over the players in them, and `pub_meta` over the public sample. Any MCP client, any OpenAI-compatible client, or
  curl can then ask, and every answer carries its SQL and its verification.

The warehouse is whatever you point at. The default is a DuckDB file under `data/`,
which needs no account; the public demo runs the same files against a managed
Postgres.

## Run it locally

```
cp .env.example .env
uv sync
make load          # keyless: 3 000 calls a day, 60 a minute; a key speeds up match details
make transform
```

`make load` walks the pro-match list back `DOTA_SINCE_DAYS` and fetches details for the
newest matches first, up to `DOTA_MAX_DETAIL_CALLS` per run, plus `DOTA_PUBLIC_PAGES`
pages of the public feed. Run it again tomorrow and it continues where it stopped.
`load/backfill.sh` runs it in chunks until nothing is new. With an OpenDota key in `.env`
the detail calls go fast and cost a hundredth of a cent each; `DOTA_PAID_CALLS_MONTH` is
the ceiling, enforced from the `api_usage` table.

To serve, dst needs a Postgres of its own for its state and a model. Fill
`DST_API_KEY_DEEPSEEK` and `DST_API_KEY_JEV` in `serve/.env` (or change the providers
in `serve/dst.yaml`), then:

```
pip install 'dst-core[local-embed]'
cd serve && dst dev             # Postgres up + migrate + serve
dst bootstrap --org dota        # once: an org and an admin token, saved to .env
dst apply                       # entities, joins, terms, the lens
dst query pro_meta "Which hero was banned most on the current patch?"
dst query pub_meta "Who counters Invoker this patch?"
```

`dst apply` probes the warehouse before anything lands, compiles the lenses, and runs the
eval gate. `dst test pro_meta` and `dst test pub_meta` run the certified corpus and the
behavioral cases: what an enthusiast asks must answer, what the data cannot carry must
refuse by name.

## Pointing it at Postgres

Set `DSTACK_TARGET=postgres` and `DATABASE_URL` in `.env` for dlt, the `PG*` variables
for dbt, and swap the `warehouse` block in `serve/dst.yaml` for the postgres shape shown
in its comment. Nothing else changes: the models are plain SQL, and the semantic layer
names tables, not engines.

The hourly GitHub Actions workflow in `.github/workflows/load.yml` runs load and
transform against the repository secrets.

## Where the governed layer earns its keep

The data has the traps a semantic layer exists for. "Win rate" needs a denominator:
a hero's games, a team's matches, or the Radiant side of every match, and the terms in
`serve/semantic/definitions/` say which. "The current patch" is a declared fact from the
patches table, not a guess from match dates. The public numbers come from a sample, and
every answer over them says so. A rate over three games is noise, so rankings apply a
minimum-games floor and every rate is reported with its count. Turbo is a different
game and never blends into the ranked meta. Pro matches carry no MMR and no prize money,
and the public feed carries no items and no player identities, so each lens refuses
those questions instead of approximating them. Each of those is a file in `serve/`, and
each is a place where the answer would otherwise have been plausible and wrong.

## Layout

```
load/opendota_pipeline.py     dlt: OpenDota → raw
transform/                    dbt: raw → staging → marts
serve/                        dst: dst.yaml, semantic/, lenses/pro_meta/
.github/workflows/load.yml    hourly load + transform
```

Data from [OpenDota](https://www.opendota.com/), under their API terms.

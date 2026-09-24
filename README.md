# dota-data-stack

Professional Dota 2 matches, from OpenDota's API to a governed answer in your own AI,
in three stages that each do one job:

- **dlt** loads. `load/opendota_pipeline.py` pulls the pro-match list, one detail record
  per match, and the dimension tables (heroes, items, patches, leagues, teams) into raw
  tables. Merged on match id, so re-runs are idempotent; the detail backfill is bounded
  per run so it fits OpenDota's free tier.
- **dbt** transforms. `transform/` turns the raw tables into marts: one row per match,
  one row per player per match, every pick and ban, a daily hero rollup, and the
  dimensions. Grain tests pin the shapes.
- **dst (data serve tool)** serves. `serve/` declares what the marts mean: eight
  entities with their metrics, the joins between them, the governed terms (hero win rate,
  contest rate, the current patch), what the lens must refuse (MMR, prize money), and
  the questions that are certified. Any MCP client, any OpenAI-compatible client, or
  curl can then ask, and every answer carries its SQL and its verification.

The warehouse is whatever you point at. The default is a DuckDB file under `data/`,
which needs no account; the public demo runs the same files against a managed
Postgres.

## Run it locally

```
cp .env.example .env
uv sync
make load          # a few minutes on the free tier: 3 000 calls a day, 60 a minute
make transform
```

`make load` walks the pro-match list back `DOTA_SINCE_DAYS` and fetches details for the
newest matches first, up to `DOTA_MAX_DETAIL_CALLS` per run. Run it again tomorrow and it
continues where it stopped. A paid OpenDota key in `.env` removes the wait.

To serve, dst needs a Postgres of its own for its state and a model. Fill
`DST_API_KEY_DEEPSEEK` and `DST_API_KEY_JEV` in `serve/.env` (or change the providers
in `serve/dst.yaml`), then:

```
pip install 'dst-core[local-embed]'
cd serve && dst dev             # Postgres up + migrate + serve
dst bootstrap --org dota        # once: an org and an admin token, saved to .env
dst apply                       # entities, joins, terms, the lens
dst query pro_meta "Which hero was banned most on the current patch?"
```

`dst apply` probes the warehouse before anything lands, compiles the lens, and runs the
eval gate. `dst test pro_meta` runs the certified corpus and the behavioral cases.

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
patches table, not a guess from match dates. Pro matches carry no MMR and no prize
money, so the lens refuses those questions instead of approximating them. Each of
those is a file in `serve/`, and each is a place where the answer would otherwise have
been plausible and wrong.

## Layout

```
load/opendota_pipeline.py     dlt: OpenDota → raw
transform/                    dbt: raw → staging → marts
serve/                        dst: dst.yaml, semantic/, lenses/pro_meta/
.github/workflows/load.yml    hourly load + transform
```

Data from [OpenDota](https://www.opendota.com/), under their API terms.

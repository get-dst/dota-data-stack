# dota

A dst project. Quickstart (**already running somewhere? skip `dst dev`** - check `DST_URL` in
.env / `curl $DST_URL/ready` first, so a second server does not race
the live one):

```bash
dst dev                # DB up + migrate + serve on :8000
dst bootstrap --org me # once: mints the admin token, saves it to .env
dst apply              # files -> server: connections + layer + lenses
dst query <lens> "..." # ask a governed question from the terminal
dst keys create --caller alex  # one key per PERSON, never per tool
```

Every command talks to whatever `DST_URL` says - the process env first,
then `.env`, where init wrote `http://localhost:8000`. If something is
already serving (a deployment, another session) that value is already
correct and `dst dev` is not the first step; read it, do not guess a
port.

Then grant the caller in `lenses/<name>/lens.yaml` -
`access.allow: [{caller: alex}]` - or `[{group: everyone}]` for the whole
org (any valid key) - and `dst apply` again. Callers are people;
agents ask on their behalf, so every answer stays attributable to
whoever the question was really for.
Query via `POST /v1/lenses/<lens>/query {"q": "..."}`, or connect an
agent over MCP (endpoint `/mcp`, bearer = the caller key):

```bash
claude mcp add dst http://localhost:8000/mcp --transport http \
  --header "Authorization: Bearer <CALLER-KEY>"
```

The registration name is how people invoke it ("check in dst ...");
it matches `DST_INSTANCE_NAME` in `.env`, which the server presents
itself by - change both to rename.

Shared entities/definitions live under `semantic/` (edited in ONE place);
lenses under `lenses/<name>/` select them + own policy and local extras.
Edit files, `dst plan` (summary + counts; --full for diffs, and it
names which lenses go stale), apply.
Author the layer from `dst introspect --connection <name> --profile`
(schema + profile facts: row counts, enum values, null rates, ranges;
`--json` for the parseable form, no flag for schema only) or import
one-shot from dbt artifacts (`dst import dbt`, never re-synced).
Run `dst probe` after authoring and nightly (cron it): it records the
warehouse's full profile in `profiles/<conn>.probe.json` - value
dictionaries, partitions, freshness - and `dst apply` lands it in the
serving prompt, so generation filters on real literals, not guessed ones.
Bootstrap certified answers from your BI tool's verified queries
(the `.claude/skills/dst-certify/` skill walks it), or bootstrap the
whole layer from 30 days of query history
(the `.claude/skills/dst-history-bootstrap/` skill walks that).
When answers are wrong, run the improvement loop
(the `.claude/skills/dst-flywheel/` skill: measure with repeats,
correct with an explicit target, gate the draft, re-measure, certify).
Secrets live in `.env` (gitignored); dst.yaml refers to them by env name.

Full documentation: https://www.dataservetool.com

# dota - dst project (guide for AI agents)

This repo IS the source of truth for governed data access. Edit files, then
plan/apply; the server (and the dashboard, when bundled) renders this state -
never author in a UI.

## Layout
- `dst.yaml` - providers (LLM endpoints, BYOK), connection declarations.
  Every available field is listed at the bottom, commented, with defaults.
- `semantic/` - the SHARED semantic layer, edited in one place:
  `entities/<name>.yaml` (grain, fields, dimensions, metrics incl. filters),
  `relationships/<left>__<right>.yaml` (one join pair per file, left = the
  FK side, with declared relationship) and `definitions/<term>.md` (governed
  terms; `status: ambiguous` + possible_mappings makes dst ASK instead
  of guessing). Full field references in `semantic/README.md`.
- `lenses/<name>/` - one governed lens per dir: selection + policy + extras:
  - `lens.yaml` (`select:` over shared assets; model, access allow-list,
    rate limits - full commented reference at the bottom), `queries.yaml`
    (use_when + sample_queries), `definitions/*.md` (lens-LOCAL terms only;
    a term defined both shared and locally is an apply error),
    `certified_answers.yaml` (approved question->SQL), `evals/cases.yaml`.
    `compiled.yaml` is a server-rendered artifact - read it, never edit it.
- `.env` (gitignored) - secrets only; files refer to them by env name
- `.dst/` (gitignored) - per-machine state: the env-name -> token map
  `dst env new` records; a credential store, never project truth
  (`DST_API_KEY_<NAME>`). Never write a secret into a tracked file.
- `.claude/skills/dst-semantic/` - the warehouse-to-semantic-layer
  authoring loop as a Claude Code skill (introspect -> author -> select ->
  apply -> verify); other agents: read it as a plain procedure.
- `.claude/skills/dst-certify/` - importing verified BI queries (Looker/
  Metabase/Tableau exports, plain SQL) as certified answers with provenance.
- `.claude/skills/dst-history-bootstrap/` - mining warehouse query history
  into a draft semantic layer + certified candidates (metadata-only SQL,
  generated-vs-authored tells, ambiguity from real disagreement).
- `.claude/skills/dst-context/` - the authoring rules for
  definitions/instructions/context prose (decide, don't describe).
- `.claude/skills/dst-flywheel/` - wrong answer -> diagnose -> correct ->
  gate the patch -> re-measure -> certify; the incident loop.
- `.claude/skills/dst-warehouse-review/` - review a warehouse for
  answerability BEFORE building lenses: 12 shape checks over introspect/
  probe output, each with a rail / definition / remodel remedy.

## Workflow
```bash
dst dev                      # DB up + migrate + serve (API :8765; + dashboard
                             # if this install bundles one - see startup output)
dst bootstrap --org <name>   # once: mints + saves DST_ADMIN_TOKEN to .env
dst plan                     # dry-run diff, files vs server
dst apply                    # files win; all-or-nothing: any error deploys NOTHING
dst query <lens> "..."       # ask a governed question from the terminal
dst env new <name>           # disposable org + admin token (recorded in .dst/,
                             # gitignored) - experiment there, not in the real org
dst test --env <name>        # env-aware verbs take --env; `dst env rm` when done
dst runs <lens> --diff prev latest   # did the change help? exit 1 on regression
```
FIND THE SERVER BEFORE STARTING ONE. Every verb talks to `DST_URL` - the
process env first, then `.env` (this project wrote
`DST_URL=http://localhost:8765` there). A deployment or a session
already running sets it to something else, and that value is the truth: never
assume a port, never curl one to look. `dst dev` is only for when nothing
is serving yet.
Ask questions via MCP (`/mcp`, bearer = a caller key) or
`POST /v1/lenses/<lens>/query` with body `{"q": "..."}`. A caller only sees
lenses whose `access.allow` grants it - entries are objects, e.g.
`allow: [{caller: alex}]` or `[{group: everyone}]` (any valid key in the org).
Callers are PEOPLE (or service identities) - one key each, never shared, never
named after the tool asking on their behalf: that is what keeps every answer
attributable to a person.

## Rules for agents
- The UI never authors - files do. Governance (rulings, certify, revoke)
  runs from the CLI - `dst reviews`, `dst rule`, `dst correct`,
  `dst patches`, `dst revoke-key` - and the dashboard renders the same state
  when this install bundles one (a locally-built wheel is API-only; see
  `dst dev`'s startup line). Anything authored lives in this repo.
- Deletion of server OBJECTS is explicit: `dst lens rm` /
  `dst semantic rm`. File absence never deletes lenses, semantic assets,
  or connections; `dst plan` flags server-only objects to adopt
  (`dst export --lens <name>`) or leave for their owner. The exception
  is file-managed certified ANSWERS: removing an entry from
  certified_answers.yaml deletes it on apply (files win; review-promoted
  answers survive).
- Change governed meaning by editing `semantic/` (shared) or the lens's local
  `definitions/*.md`, then plan -> apply. `dst plan` names every lens a
  shared edit makes stale; apply recompiles them. Never claim a change is
  live until apply succeeded.
- Uncomment fields from the reference blocks instead of guessing names.
- Secrets: add the env name to `.env`, reference it as `secret_env`/`api_key_env`.
- Scaffolding: `dst introspect --connection X --profile` prints the schema
  PLUS profile facts (row counts, null rates, enum values, ranges) - read it,
  then author semantic/ files yourself. Without --profile it is schema only and
  says NOT PROFILED at the top; `--json` prints the same facts parseable.
  `dst import dbt --target-dir target/ --connection X` scaffolds from dbt
  artifacts one-shot.
- Need actual ROWS to settle what a column means? `dst sql "SELECT ..."
  --connection X --limit 5` - SELECT-only, row-capped, logged. Never open the
  warehouse client directly: dst holds that credential so you do not have
  to, and SQL run around it is ungoverned and invisible to the audit log.
- Verifying access: `dst query <lens> "<q>" --key dst_...` asks AS that
  caller. The admin token bypasses every allow-list, so it is the only way to
  prove a grant works - and that an ungranted caller is refused.

## Handing this project to consumers

The consumer-facing handoff is CONSUMER.md at the project root - write it
when the project is handed to the agents that will QUERY it (they read that
file, not this one). Its content is yours; what it must cover is fixed:
- The doors: MCP (`/mcp`, bearer = the caller's key) and
  `POST /v1/lenses/<lens>/query {"q": "..."}` - and that every caller uses
  their OWN key, one per person.
- What `status`, `confidence` (verified | partial | unverified) and
  `certification` mean, and that they are RELAYED with the answer - the
  grade travels with the number, never dropped.
- A refusal or clarification is relayed verbatim: a governed outcome, not
  an error to route around.
- Never bypass: no direct warehouse access to "check" or extend an answer -
  the lens is the interface.

Reference documentation (every verb, every field): https://www.dataservetool.com

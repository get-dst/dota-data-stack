# Launch: the hosted Dota demo

"Add this MCP URL to Claude and ask about Dota." The service is the `dst` Cloud Run
service already live in `kurator-core` (europe-west1, Cloud SQL `dst-pg`, demo mode on,
org `demo`). Launching means swapping its jaffle lens for this project, moving it onto
MotherDuck and a domain, and switching Clerk to production. Every step below is a click
or a command for the maintainer. Only step 5's domain mapping has been run against the
cloud account (2026-09-25); everything else is still to do.

`deploy/cloudrun.sh <step>` holds the gcloud side. Its defaults are the existing names;
override any with env (`PROJECT`, `REGION`, `SERVICE`, `DEMO_DOMAIN`, `IMAGE`, …). The
VM variant (`docker-compose.yml` + `Caddyfile` + `.env.example`) is the same contract on
one machine. It needs `DST_BASE_IMAGE` to be pullable (see step 0).

## The numbers (from the code)

| Bound | Value | Where |
|---|---|---|
| Per person, per lens, per minute | 60 | `rate_limit.per_caller_rpm` in each `serve/lenses/*/lens.yaml` (in-process limiter) |
| Per person, per lens, per rolling 24 h | 50 answers, so 250 across the five lenses | `rate_limit.per_caller_rpd`; counted from `request_log`, refused with 429 + `Retry-After` |
| Whole demo, per rolling 24 h | 2000 answers | `DST_DAILY_REQUEST_CAP`. The code default is **0 = no cap**, so it must be set |
| Key minted on `/demo` | 7 days, one live key per person (a re-mint revokes the last) | `DST_DEMO_KEY_DAYS` |
| MCP OAuth token (what Claude holds) | **7 days** in demo mode (= `DST_DEMO_KEY_DAYS`), no refresh token: people reconnect weekly | dst ≥ 0.5.7 |
| Key mints per source IP | 20/min | `_MINT_IP_RPM` |
| OAuth client registrations per IP | 12/min | `_REGISTER_RPM` |
| Warehouse statement timeout | 30 s | `statement_timeout_ms` in `serve/dst.yaml` |
| Request log retention | 30 days, once `prune-job` runs | `dst prune-log --keep-days 30` |

Measured in the local rehearsal (DeepSeek `deepseek-v4-flash`, priced by dst's own table):
a typed answer cost $0.0003–0.0005 and took 3–4.5 s. A raw-SQL (UNTYPED) answer cost
$0.0016–0.0026 and took 5–8 s. A named refusal cost $0. Over 23 real answers the mix
averaged about $0.0007. At the 2000/day cap that is about $1.40/day typical, and about
$5/day if every answer went raw. Jev's typed decisions are **not** in that figure: dst
records their tokens (`resolution.decisions[].usage`) but does not price them.

## 0. Before anything

- [x] dst 0.5.11 on the laptop (`pip install -U 'dst-core==0.5.11'`, or `~/dst-dev/.venv/bin/dst`).
- [x] `gcloud auth login` as the account that owns `kurator-core`.
- [ ] Decide on the GHCR image. `ghcr.io/get-dst/dst:0.5.11` was pushed by the release,
      but an anonymous pull is refused (403), so the package is private. Cloud Run does
      not need it: `cloudbuild.yaml` builds from the public source tag. The VM variant and
      every stranger following dst's `deploy/` do need it. Either make it public
      (github.com/orgs/get-dst/packages → dst → Package settings → Change visibility), or
      on a VM set `DST_BASE_IMAGE` to a local
      `docker build --build-arg UV_EXTRA=local-embed` of the dst repo.

## 1. MotherDuck: the serving token

- [ ] MotherDuck UI → Settings → Access tokens → create a **Read Scaling** token.
- [ ] Prove it reads and cannot write. This is the demo's one open assumption; so far it
      has only been checked under a regular token:

      ```
      MOTHERDUCK_TOKEN=<read-scaling> uv run python -c "
      import duckdb; c = duckdb.connect('md:dota')
      print(c.sql('select count(*) from marts.fact_match').fetchone())
      c.sql('create table marts.write_probe as select 1')"
      ```
      Expected: a count, then an error on the CREATE.
- [ ] Freshness needs nothing new. The `dota-load` Cloud Run job (`deploy/loader/`, every
      4 hours) writes `md:dota`. Read-scaling
      replicas are eventually consistent ("within minutes", per MotherDuck's docs), and the
      lenses declare `stale_after_days: 2`. If the load stops for two days, answers say
      they are stale; that is the guarantee firing, not a fault.
- [ ] Check what the MotherDuck plan includes for read-scaling compute. The default pool
      is 4 replicas.

## 2. Clerk: production instance

- [ ] Create the application (e.g. "dst demo"). Sign-in methods: **Google**, **GitHub**,
      and **Email verification code**. All three end in a verified email.
- [ ] Switch it to a **production** instance on `dataservetool.com`. Add the CNAME records
      Clerk lists in Cloudflare as **DNS only** (grey cloud), then wait for Clerk to
      verify them. Production Google/GitHub sign-in needs your own OAuth client id and
      secret for each (Clerk links the setup page).
- [ ] Sessions → Customize session token → claims: `{"email": "{{user.primary_email_address}}"}`.
      dst names the caller from the `email` claim, and Clerk's default token has none.
      Without this claim every caller, quota row and log line is named by a Clerk user id
      (`user_…`) instead of the email the page promises.
- [ ] Copy the `pk_live_…` publishable key. The secret key is not used by dst.

## 3. Model spend

- [ ] **DeepSeek**: make a key used only by the demo. DeepSeek runs on a prepaid balance,
      so the balance is the hard ceiling: top up a fixed amount (for example $20, about two
      weeks at the cap if everything went raw) with auto-recharge off. If the dashboard
      offers a monthly limit, set that too. Then put the key into the providers secret
      (keeps jev as is):

      ```
      printf %s '{"deepseek":{"type":"openai-compatible","base_url":"https://api.deepseek.com","api_key":"<demo key>","fast_model":"deepseek-v4-flash"},"jev":{"type":"typesafe","api_key":"<jev key>"}}' \
        | gcloud --project kurator-core secrets versions add dst-providers --data-file=-
      ```
- [ ] **Jev**: a demo-only key in the same JSON, and Jev's own usage limit if the account
      has one. dst does not put a dollar figure on it.

## 4. Build, secret, migrate

```
deploy/cloudrun.sh build              # Cloud Build: dst v0.5.11 source + local-embed + baked weights (~10 min)
deploy/cloudrun.sh warehouse-secret   # paste the read-scaling token; stored as dst-api-key-warehouse
deploy/cloudrun.sh migrate            # dst-migrate job on the new image
```

Done 2026-09-27: the image `dota-demo:0.5.11` is built, `dst-migrate` ran on it (already at
head, 0067), and `dst-api-key-warehouse` holds the REGULAR MotherDuck token as version 1
(dst opens it read-only; writes are refused). Run `warehouse-secret` again with the
read-scaling token when it exists: it adds version 2 and the service reads `latest` on its
next deploy.

## 5. Domain

- [x] `deploy/cloudrun.sh domain` (maps `demo.dataservetool.com` onto the service). Done
      2026-09-25 20:49 UTC.
- [x] Cloudflare: `CNAME demo → ghs.googlehosted.com`, **DNS only** (resolves to a Google
      IP, so not proxied). A proxied (orange)
      record blocks Google's certificate, the same as on the docs site.
- [x] `deploy/cloudrun.sh status` until the mapping reports its certificate ready.
      Ready since 2026-09-26.
      Do not deploy before that. Step 6 sets `DST_PUBLIC_BASE_URL` to the domain, and MCP
      then answers only on that host (the run.app URL gets 421).

## 6. Deploy

```
DST_CLERK_PUBLISHABLE_KEY=pk_live_… deploy/cloudrun.sh deploy
curl -s https://demo.dataservetool.com/ready
```

`/ready` must show `embeddings: ok`, `certified_matching: ok`, `models: configured
providers: deepseek, jev …`, `environment: production`. The live service today shows
`embeddings: unconfigured`, because its stock image has no local-embed.

## 7. Content: retire jaffle, apply Dota

You need the org's admin token (`dstadm_…`). It was printed once to the `dst-bootstrap`
job's Cloud Logging trail. Recovered and verified on 2026-09-27 (GET /mgmt/lenses → 200)
into `~/.config/dst-demo/admin_token` (mode 600): `export DEMO_TOKEN=$(cat
~/.config/dst-demo/admin_token)`. If it was not kept, re-run the job with `--args=bootstrap,--org=demo`
(idempotent; mints a fresh token for the same org), store it, and scrub the log entry.

```
export DEMO=https://demo.dataservetool.com DEMO_TOKEN=dstadm_…
dst lens rm customer_value --yes --url $DEMO --token $DEMO_TOKEN
cd serve && dst apply --url $DEMO --token $DEMO_TOKEN --timeout 1500
```

- Do **not** run `dst demo`. It publishes the bundled jaffle lens, not this project.
- Pass `--url`/`--token` explicitly. `serve/.env` points at the local server on 8765.
- The server resolves `DST_API_KEY_WAREHOUSE` from its own env, probes MotherDuck, and
  stores the token encrypted. The rehearsal apply took 85 s with all five eval gates
  passing.
- One case is flaky: pro_meta's "Which offlaners have the best win rate in pro matches
  this patch?" (the first apply flagged it, and a re-apply blocked on it). A block
  deploys nothing and the previous version keeps serving. Re-run, or publish past it once
  with `--allow-case <id> --reason '…'`.

## 8. Smoke test (as a stranger)

- [ ] Private window → `https://demo.dataservetool.com/demo` → sign in with Google. A
      `dst_` key appears, valid 7 days, with three snippets.
- [ ] The page's heading and the consent pages say **roshan** (`DST_INSTANCE_NAME`),
      with "answers by dst (data serve tool)" above, and "What you can ask" lists the
      five Dota lenses with an example question each.
- [ ] `curl` snippet → HTTP 200 with `status: ok` (the page's example question comes from
      the lens's own declared questions).
- [ ] Claude (desktop or claude.ai) → Settings → Connectors → Add custom connector → name
      it **roshan**, URL `https://demo.dataservetool.com/mcp` → Connect → consent page
      ("Sign in to roshan") → sign in with the same account. Then ask:

  1. *"Ask roshan: what is the current patch in pro Dota?"* → **7.41**. It comes back typed
     (`resolution.method: construction`); this wording does not match the certified
     "What is the current patch?", so it is not a certified answer.
  2. *"How many pro matches were played on the current patch?"* → certified. The count
     grows with every load and counts premium and professional leagues only, so check it
     matches its SQL rather than a number.
  3. *"What is the average MMR of players in pro matches?"* → **refused by name** ("this
     lens cannot compute MMR — professional matches carry no matchmaking rating …").

  Optional, to show both serving paths: *"Which hero was banned most on the current
  patch?"* comes back typed (`resolution.method: construction`); Lone Druid had 880 bans
  at rehearsal time (by ban rate, Treant Protector led at the 2026-09-25 evening
  preflight). *"Which pro match this patch lasted the longest, and who won it?"* comes back with an `UNTYPED: served by raw-SQL generation …` line in `degraded`.
- [ ] `dst observe --url $DEMO --token $DEMO_TOKEN` shows your email as a caller, with cost.

## 9. Retention

- [x] `deploy/cloudrun.sh prune-job`: a Cloud Run job plus a Cloud Scheduler trigger at
      03:17 UTC that deletes `request_log` rows older than 30 days. The `/demo` page tells
      visitors their questions are logged with their email.

## Watching it

- **Usage and cost**: `dst observe --url $DEMO --token $DEMO_TOKEN` (headline plus
  per-caller queries, cost, declines). `dst observe requests --status refused` lists what
  people asked that the lenses refused, which is the authoring backlog.
- **Abuse**: the 429 denials land in `audit_log` (`reason` is "daily quota exceeded",
  "daily request cap exceeded" or "rate limit exceeded"), not in `observe`. A caller near
  250/day or the org near 2000/day is the signal.
- **Spend**: the DeepSeek balance page, and Jev's. Cloud Run and Cloud SQL on the GCP
  billing report.
- **Data**: the `dota-load` Cloud Run job (`deploy/loader/cloudrun-job.sh status`). Two
  days of failed runs means stale answers, disclosed as stale.

## Pulling the plug

From softest to hardest:

1. **One person**: ban them in Clerk (Users → Ban, so they cannot sign in again), then
   revoke their keys and OAuth tokens with `dst revoke-key --caller <email> --org demo`
   (OAuth tokens live in the same table, so they go too). That command talks to the
   database, so on Cloud Run run it as a job shaped like `dst-migrate`.
2. **Everyone, gradually**: lower the cap without a rebuild:
   `gcloud run services update dst --region europe-west1 --update-env-vars DST_DAILY_REQUEST_CAP=200`.
3. **Everyone, now**: `deploy/cloudrun.sh off`. Google's front end answers 403 to all;
   state is kept, and `deploy/cloudrun.sh on` reverses it.
4. **Money**: revoke the demo's DeepSeek key. Answers then fail at generation; nothing
   else is exposed.

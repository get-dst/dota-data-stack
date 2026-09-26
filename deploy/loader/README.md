# The scheduled load

The warehouse is refreshed by a Cloud Run job in `kurator-core` (europe-west1), started
by Cloud Scheduler every four hours. `.github/workflows/load.yml` runs the same two steps
on manual dispatch only.

## What runs where

| Piece | Name | Role |
|---|---|---|
| Cloud Run job | `dota-load` | Runs `run.sh`: `load/opendota_pipeline.py`, then `dbt build` in `transform/`, against the MotherDuck database `dota`. dbt runs even when the loader fails, and the execution fails if either step did. 1 vCPU, 1 GiB, 50-minute task timeout, no retries. |
| Image | `europe-west1-docker.pkg.dev/kurator-core/dst/dota-loader:<commit>` | Built by Cloud Build from `Dockerfile`, with dependencies and DuckDB's MotherDuck extension installed. The tag is the last commit that changed `load/`, `transform/`, `.dlt/`, `pyproject.toml`, `uv.lock`, `Dockerfile` or `run.sh`. |
| Cloud Scheduler job | `dota-load-schedule` | `23 */4 * * *` UTC (00:23, 04:23, … 20:23). Calls the Run Admin API (`jobs/dota-load:run`) with a token for `dota-scheduler@kurator-core.iam.gserviceaccount.com`, which holds `roles/run.invoker` on this job only. |
| Service account | `dota-loader@kurator-core.iam.gserviceaccount.com` | The job's identity: `roles/secretmanager.secretAccessor` on the two secrets, `roles/logging.logWriter` on the project. |
| Secrets | `dota-motherduck-token`, `dota-opendota-key` | Read at version `latest` into `MOTHERDUCK_TOKEN` (a read-write token) and `OPENDOTA_API_KEY`. |

The job's environment is the workflow's: `DSTACK_TARGET=motherduck`,
`MOTHERDUCK_DATABASE=dota`, `DOTA_SINCE_DAYS=365`, `DOTA_MAX_DETAIL_CALLS=300`,
`DOTA_PAID_CALLS_MONTH=90000`. It adds `NORMALIZE__WORKERS=1`, which overrides the eight
workers in `.dlt/config.toml`: on one vCPU, dlt's worker processes add memory, not speed.

## Operating it

`deploy/loader/cloudrun-job.sh <step>`, one step per subcommand, each safe to re-run.
Every default (`PROJECT`, `REGION`, `JOB`, `TRIGGER`, `SCHEDULE`, `MEMORY`, `TAG`,
`ENV_FILE`) can be overridden by env.

- **After a loader or dbt change**: commit, then `build` and `job`. `build` refuses while
  the image's inputs have uncommitted changes, because the tag names a commit.
- **Environment or size only**: `job` (for example `MEMORY=2Gi deploy/loader/cloudrun-job.sh job`).
- **New MotherDuck token or OpenDota key**: put it in `.env`, then `secrets`. A new
  version is added only when the value changed; the next run reads it. Values are never
  printed.
- **Run once now**: `run`. It waits for the result and refuses while another execution is
  running. `status` lists the last five executions with result and duration.
- **Pause and resume**:

  ```
  gcloud scheduler jobs pause dota-load-schedule --location europe-west1 --project kurator-core
  gcloud scheduler jobs resume dota-load-schedule --location europe-west1 --project kurator-core
  ```

- **Another cadence**: `SCHEDULE='23 */6 * * *' deploy/loader/cloudrun-job.sh schedule`.
  Keep the interval longer than the 50-minute task timeout, so two runs never overlap.
- **Logs**: `gcloud logging read 'resource.type="cloud_run_job" AND
  resource.labels.job_name="dota-load"' --project kurator-core --limit 100`. The loader
  prints `this run: N paid calls, N free calls, N match details`; dbt ends with
  `Done. PASS=… ERROR=0`.
- **Old images**: each `build` stores a new image of about 0.45 GiB. After a redeploy,
  delete the previous tag: `gcloud artifacts docker images delete
  europe-west1-docker.pkg.dev/kurator-core/dst/dota-loader:<old tag> --delete-tags`.

Do not dispatch the `load` workflow while an execution is running (`status` shows it):
two loads at once write the same tables and both read the month's paid-call count
before either records its own.

The lenses declare `stale_after_days: 2`, so a failed run or two shows up in the job's
execution list, not in answers.

## Cost

Measured on 2026-09-26, three manual executions took 197 s, 173 s and 195 s from start to
finish. Of that, 21–39 s passed before the loader's first line (container start, imports,
the MotherDuck connection), the loader took 90–97 s, and dbt took 53–57 s. The loader's
share is mostly its 71 keyless OpenDota calls, paced at one every 1.05 s (about 75 s). Each
of those runs had at most one new match to fetch.

List price for Cloud Run jobs in europe-west1 (Tier 1) is $0.000018 per vCPU-second and
$0.000002 per GiB-second, billed for the container's lifetime with a one-minute minimum.
The billing account's free Cloud Run allowance is already used by other services, so none
is counted. At 195 s a run, 1 vCPU and 1 GiB cost $0.0039 a run:

| Cadence | Runs a month | Compute a month |
|---|---|---|
| hourly | 730 | $2.85 |
| every 2 hours | 365 | $1.42 |
| every 3 hours | 243 | $0.95 |
| **every 4 hours** (current) | 183 | **$0.71** |
| every 6 hours | 122 | $0.47 |

195 s is counted from the start of the execution, which includes provisioning before the
container starts, so the billed time is at most that. Cloud Monitoring's once-a-minute samples showed memory at 300 MiB at
most; 512 MiB would lower the price per run by 5% and leave less room for a run that
catches up on up to 300 match details, so the job keeps 1 GiB.

Other charges, at list price, each only beyond a free allowance shared across the billing
account:

- Internet egress: a run sent 6.3–8.7 MB, mostly to MotherDuck, so about 1.1–1.5 GiB a
  month at four-hourly runs. $0.12 per GiB after the first free GiB: $0.18 at most.
- Secret Manager: two active versions at $0.06 each a month beyond six free ones
  (`kurator-core` holds six in total). The 366 reads a month are within the 10,000 free.
- Cloud Scheduler: $0.10 a month for the one job, beyond three free jobs.
- Artifact Registry: about $0.05 a month for the one image kept, beyond 0.5 GiB free.

With no free allowance left anywhere, four-hourly runs come to about $1.16 a month and
six-hourly runs to about $0.86.

Fewer runs also mean a smaller public-match sample, which is taken per run
(`DOTA_PUBLIC_PAGES` pages of 100), and pro matches that land up to four hours after
OpenDota lists them.

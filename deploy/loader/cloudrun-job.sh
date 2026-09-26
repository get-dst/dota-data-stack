#!/usr/bin/env bash
# The scheduled load as a Cloud Run job (deploy/loader/README.md). One step per
# subcommand; each can be re-run. Defaults are the names in kurator-core; override by env.
#
#   deploy/loader/cloudrun-job.sh secrets | build | job | schedule | run | status
set -euo pipefail

PROJECT=${PROJECT:-kurator-core}
REGION=${REGION:-europe-west1}
JOB=${JOB:-dota-load}
TRIGGER=${TRIGGER:-dota-load-schedule}
SCHEDULE=${SCHEDULE:-23 */3 * * *}
MEMORY=${MEMORY:-1Gi}
SA=${SA:-dota-loader@${PROJECT}.iam.gserviceaccount.com}
SCHEDULER_SA=${SCHEDULER_SA:-dota-scheduler@${PROJECT}.iam.gserviceaccount.com}
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
TAG=${TAG:-$(git -C "$root" rev-parse --short HEAD)}
IMAGE=${IMAGE:-${REGION}-docker.pkg.dev/${PROJECT}/dst/dota-loader:${TAG}}
ENV_FILE=${ENV_FILE:-$root/.env}
g() { gcloud --quiet --project "$PROJECT" "$@"; }

service_account() {  # email, display name
  g iam service-accounts describe "$1" >/dev/null 2>&1 ||
    g iam service-accounts create "${1%%@*}" --display-name "$2"
}

case "${1:-}" in
secrets)
  # From .env into Secret Manager. Values stay in shell variables, never printed; a
  # version is added only when the value changed.
  service_account "$SA" "dota loader (Cloud Run job)"
  g projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA" \
    --role roles/logging.logWriter --condition None >/dev/null
  for pair in dota-motherduck-token=MOTHERDUCK_TOKEN dota-opendota-key=OPENDOTA_API_KEY; do
    secret=${pair%%=*} key=${pair#*=}
    value=$(grep "^${key}=" "$ENV_FILE" | cut -d= -f2- | tr -d "\"'\r\n" || true)
    [ -n "$value" ] || { echo "$key is empty or missing in $ENV_FILE" >&2; exit 1; }
    g secrets describe "$secret" >/dev/null 2>&1 ||
      g secrets create "$secret" --replication-policy automatic >/dev/null
    if [ "$(g secrets versions access latest --secret "$secret" 2>/dev/null)" = "$value" ]; then
      echo "$secret: unchanged"
    else
      printf %s "$value" | g secrets versions add "$secret" --data-file=- >/dev/null
      echo "$secret: new version"
    fi
    g secrets add-iam-policy-binding "$secret" --member "serviceAccount:$SA" \
      --role roles/secretmanager.secretAccessor >/dev/null
  done
  ;;
build)
  # The tag is the commit, so the tree the image is built from must be that commit.
  dirty=$(git -C "$root" status --porcelain -- load transform .dlt pyproject.toml uv.lock deploy/loader)
  if [ -n "$dirty" ]; then
    printf 'uncommitted changes would ship under %s:\n%s\n' "$TAG" "$dirty" >&2; exit 1
  fi
  g builds submit "$root" --config "$here/cloudbuild.yaml" --substitutions "_IMAGE=$IMAGE"
  ;;
job)
  # 50 minutes stays under the shortest interval between scheduled runs, so two loads
  # never overlap. No retries: a failed run waits for the next one.
  service_account "$SA" "dota loader (Cloud Run job)"
  g run jobs deploy "$JOB" --region "$REGION" --image "$IMAGE" --service-account "$SA" \
    --cpu 1 --memory "$MEMORY" --task-timeout 50m --max-retries 0 --parallelism 1 --tasks 1 \
    --set-env-vars "DSTACK_TARGET=motherduck,MOTHERDUCK_DATABASE=dota,DOTA_SINCE_DAYS=365,DOTA_MAX_DETAIL_CALLS=300,DOTA_PAID_CALLS_MONTH=90000" \
    --set-secrets "MOTHERDUCK_TOKEN=dota-motherduck-token:latest,OPENDOTA_API_KEY=dota-opendota-key:latest"
  ;;
schedule)
  # Cloud Scheduler calls the Run Admin API with an OAuth token of its own service
  # account, which may only run this job.
  g services enable cloudscheduler.googleapis.com
  service_account "$SCHEDULER_SA" "dota loader trigger (Cloud Scheduler)"
  g run jobs add-iam-policy-binding "$JOB" --region "$REGION" \
    --member "serviceAccount:$SCHEDULER_SA" --role roles/run.invoker >/dev/null
  verb=create
  g scheduler jobs describe "$TRIGGER" --location "$REGION" >/dev/null 2>&1 && verb=update
  g scheduler jobs "$verb" http "$TRIGGER" --location "$REGION" \
    --schedule "$SCHEDULE" --time-zone UTC --http-method POST \
    --uri "https://run.googleapis.com/v2/projects/${PROJECT}/locations/${REGION}/jobs/${JOB}:run" \
    --oauth-service-account-email "$SCHEDULER_SA" >/dev/null
  g scheduler jobs describe "$TRIGGER" --location "$REGION" --format 'value(schedule,timeZone,state)'
  ;;
run)
  # Once, now, waiting for the result. Refuses while another execution is running.
  running=$(g run jobs executions list --job "$JOB" --region "$REGION" \
    --filter 'NOT status.completionTime:*' --format 'value(metadata.name)')
  if [ -n "$running" ]; then echo "already running: $running" >&2; exit 1; fi
  g run jobs execute "$JOB" --region "$REGION" --wait
  ;;
status)
  g run jobs executions list --job "$JOB" --region "$REGION" --limit 5 --format json |
    python3 -c '
import json, sys
from datetime import datetime

def at(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))

for e in json.load(sys.stdin):
    s, meta = e["status"], e["metadata"]
    result = ("succeeded" if s.get("succeededCount") else "failed" if s.get("failedCount")
              else "cancelled" if s.get("cancelledCount") else "running")
    took = "-"
    if s.get("startTime") and s.get("completionTime"):
        took = "%.0f s" % (at(s["completionTime"]) - at(s["startTime"])).total_seconds()
    print(meta["name"], s.get("startTime", "-"), result, took, sep="  ")
'
  g scheduler jobs describe "$TRIGGER" --location "$REGION" \
    --format 'value(schedule,timeZone,state,lastAttemptTime)' 2>/dev/null || echo "no schedule yet"
  ;;
*)
  sed -n '2,6p' "$0"; exit 2
  ;;
esac

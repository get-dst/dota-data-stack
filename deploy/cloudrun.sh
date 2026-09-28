#!/usr/bin/env bash
# The demo on Cloud Run, one step per subcommand, in LAUNCH.md's order. The defaults
# are the dst service already running in kurator-core (Cloud SQL dst-pg, SA dst-run,
# secrets dst-*, demo org from its bootstrap); override any by env.
#
#   deploy/cloudrun.sh build | warehouse-secret | migrate | domain | deploy | prune-job | status | off | on
set -euo pipefail

PROJECT=${PROJECT:-kurator-core}
REGION=${REGION:-europe-west1}
SERVICE=${SERVICE:-dst}
SA=${SA:-dst-run@${PROJECT}.iam.gserviceaccount.com}
SQL=${SQL:-${PROJECT}:${REGION}:dst-pg}
DST_VERSION=${DST_VERSION:-0.6.2}
IMAGE=${IMAGE:-${REGION}-docker.pkg.dev/${PROJECT}/dst/dota-demo:${DST_VERSION}}
DEMO_DOMAIN=${DEMO_DOMAIN:-demo.dataservetool.com}
DST_DEMO_ORG_ID=${DST_DEMO_ORG_ID:-8281cd7f-ba1d-44df-a13d-a6e36bff51bf}
DB_SECRETS="DATABASE_URL=dst-database-url:latest,DATABASE_ADMIN_URL=dst-database-admin-url:latest"
here=$(cd "$(dirname "$0")" && pwd)
g() { gcloud --project "$PROJECT" "$@"; }

case "${1:-}" in
build)
  # dst from the public source at the tag + local-embed + baked weights (cloudbuild.yaml).
  g builds submit "$here" --config "$here/cloudbuild.yaml" \
    --substitutions="_DST_VERSION=${DST_VERSION},_IMAGE=${IMAGE}"
  ;;
warehouse-secret)
  # The MotherDuck READ-SCALING token, read from the terminal, never echoed.
  read -rsp "MotherDuck read-scaling token: " token; echo
  if g secrets describe dst-api-key-warehouse >/dev/null 2>&1; then
    printf %s "$token" | g secrets versions add dst-api-key-warehouse --data-file=-
  else
    printf %s "$token" | g secrets create dst-api-key-warehouse --data-file=-
  fi
  g secrets add-iam-policy-binding dst-api-key-warehouse \
    --member="serviceAccount:${SA}" --role=roles/secretmanager.secretAccessor >/dev/null
  echo "dst-api-key-warehouse stored; the service reads it as DST_API_KEY_WAREHOUSE"
  ;;
migrate)
  # Before shifting the service to a new image, as every release.
  g run jobs update dst-migrate --region "$REGION" --image "$IMAGE"
  g run jobs execute dst-migrate --region "$REGION" --wait
  ;;
domain)
  # Then a DNS-only (grey cloud) CNAME ${DEMO_DOMAIN} -> ghs.googlehosted.com. The
  # certificate is issued once Google sees it; `status` shows when.
  g beta run domain-mappings create --service "$SERVICE" --domain "$DEMO_DOMAIN" --region "$REGION"
  ;;
deploy)
  : "${DST_CLERK_PUBLISHABLE_KEY:?export the pk_live_ key of the Clerk production instance}"
  # --update-* keeps what the service already has (DB URLs, DST_SECRET_KEY, DST_PROVIDERS,
  # DST_ENVIRONMENT, DST_MIGRATE_ON_START=false). Providers stay as they are: deepseek +
  # jev from the dst-providers secret; the image's local embedder is picked up implicitly.
  # DST_APPLY_STEP_TIMEOUT_S=300: an apply's connection probe profiles every table, and
  # from a cloud machine that took 134 s against MotherDuck; the default 60 s aborts it.
  # 2Gi: the local embedder lifts the process to ~780 MiB resident after an apply, with
  # a 945 MiB peak; 1Gi leaves no headroom.
  # --timeout 3600: an MCP client holds an event stream open; at the default 300 s Cloud
  # Run cut it and the client reconnected every five minutes.
  g run deploy "$SERVICE" --region "$REGION" --image "$IMAGE" \
    --service-account "$SA" --set-cloudsql-instances "$SQL" \
    --min-instances 1 --max-instances 1 --no-cpu-throttling --memory 2Gi --cpu 1 \
    --timeout 3600 \
    --update-env-vars "DST_PUBLIC_BASE_URL=https://${DEMO_DOMAIN},DST_CLERK_PUBLISHABLE_KEY=${DST_CLERK_PUBLISHABLE_KEY},DST_DEMO_ORG_ID=${DST_DEMO_ORG_ID},DST_DEMO_KEY_DAYS=7,DST_DAILY_REQUEST_CAP=2000,DST_TYPED_SERVING=auto,DST_INSTANCE_NAME=roshan,DST_LLM_DESCRIPTIONS=false,DST_APPLY_STEP_TIMEOUT_S=300" \
    --update-secrets "DST_API_KEY_WAREHOUSE=dst-api-key-warehouse:latest"
  ;;
prune-job)
  # Questions are logged with the sign-in email for 30 days, as /demo promises. Daily at 03:17 UTC.
  g services enable cloudscheduler.googleapis.com
  g run jobs create dst-prune-log --region "$REGION" --image "$IMAGE" \
    --service-account "$SA" --set-cloudsql-instances "$SQL" --set-secrets "$DB_SECRETS" \
    --command dst --args=prune-log,--keep-days=30 --max-retries 0
  g run jobs add-iam-policy-binding dst-prune-log --region "$REGION" \
    --member="serviceAccount:${SA}" --role=roles/run.invoker >/dev/null
  g scheduler jobs create http dst-prune-log --location "$REGION" --schedule "17 3 * * *" \
    --time-zone UTC --http-method POST \
    --uri "https://run.googleapis.com/v2/projects/${PROJECT}/locations/${REGION}/jobs/dst-prune-log:run" \
    --oauth-service-account-email "$SA"
  ;;
status)
  g run services describe "$SERVICE" --region "$REGION" --format 'value(status.url,spec.template.spec.containers[0].image)'
  g beta run domain-mappings describe --domain "$DEMO_DOMAIN" --region "$REGION" \
    --format 'value(status.conditions)' 2>/dev/null || true
  curl -s "https://${DEMO_DOMAIN}/ready"; echo
  ;;
off)
  # The plug: nobody reaches the service (Google's front end answers 403); state is kept.
  g run services remove-iam-policy-binding "$SERVICE" --region "$REGION" \
    --member=allUsers --role=roles/run.invoker
  ;;
on)
  g run services add-iam-policy-binding "$SERVICE" --region "$REGION" \
    --member=allUsers --role=roles/run.invoker
  ;;
*)
  sed -n '2,6p' "$0"; exit 2
  ;;
esac

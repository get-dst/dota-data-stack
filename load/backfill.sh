#!/bin/bash
# Backfill in chunks: each run fetches at most DOTA_MAX_DETAIL_CALLS match details and
# lands them, so a long backfill is many short loads rather than one long-lived process
# holding hours of paid calls in memory. Stops when a run fetches nothing new.
#
#   load/backfill.sh [chunk=1500] [max_runs=10]
set -euo pipefail
cd "$(dirname "$0")/.."
CHUNK=${1:-1500}
MAX=${2:-10}
for i in $(seq 1 "$MAX"); do
  echo "== backfill run $i (chunk $CHUNK)"
  out=$(DOTA_MAX_DETAIL_CALLS="$CHUNK" DOTA_PUBLIC_PAGES=0 uv run python load/opendota_pipeline.py 2>&1 | tee /dev/stderr | grep -E '^this run:' || true)
  # Stop on a run that bought no match detail; with a key the match list is paid too.
  details=$(echo "$out" | sed -E 's/.* ([0-9]+) match details.*/\1/')
  if [ -z "$details" ] || [ "$details" = "0" ]; then
    echo "== backfill complete: nothing new to fetch"
    exit 0
  fi
done
echo "== backfill: reached max runs ($MAX); run again to continue"

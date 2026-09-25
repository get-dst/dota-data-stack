#!/usr/bin/env bash
# Throwaway dst over the real warehouse: migrate → serve → bootstrap → plan →
# apply → test. Every way this can end without having tested something is an
# exit 1, never a green run.
#
# Needs: dst on PATH, DATABASE_ADMIN_URL, DATABASE_URL, DST_API_KEY_DEEPSEEK,
# DST_API_KEY_JEV, DST_API_KEY_WAREHOUSE. Optional: DST_PORT (8799), DST_ORG (dota),
# SERVE_DIR (serve), OUT_DIR (where the log, test json and summary land).
set -euo pipefail

SERVE_DIR=$(cd "${SERVE_DIR:-serve}" && pwd)
OUT_DIR=${OUT_DIR:-$(mktemp -d)}
PORT=${DST_PORT:-8799}
ORG=${DST_ORG:-dota}
SUMMARY=${GITHUB_STEP_SUMMARY:-$OUT_DIR/summary.md}
mkdir -p "$OUT_DIR"
here=$(cd "$(dirname "$0")" && pwd)

die() { echo "::error::$*" >&2; echo "**dst check failed:** $*" >> "$SUMMARY"; exit 1; }

# A fork PR gets no secrets. An empty key would turn into provider errors, and a
# provider error skips a gate rather than failing it — so refuse up front.
missing=()
for v in DATABASE_ADMIN_URL DATABASE_URL DST_API_KEY_DEEPSEEK DST_API_KEY_JEV DST_API_KEY_WAREHOUSE; do
  [ -n "${!v:-}" ] || missing+=("$v")
done
[ ${#missing[@]} -eq 0 ] || die "missing secrets: ${missing[*]} (a PR from a fork gets none; run it from a branch or via workflow_dispatch)"

# The server encrypts stored warehouse credentials with this (a Fernet key: 32 bytes,
# url-safe base64); it lives one run.
export DST_SECRET_KEY=${DST_SECRET_KEY:-$(python3 -c 'import base64,os;print(base64.urlsafe_b64encode(os.urandom(32)).decode())')}
export DST_URL=http://127.0.0.1:$PORT

dst --version
dst migrate

# serve runs from the project dir, like a real deployment reading its dst.yaml.
(cd "$SERVE_DIR" && exec dst serve --host 127.0.0.1 --port "$PORT") > "$OUT_DIR/serve.log" 2>&1 &
server=$!
trap 'kill $server 2>/dev/null || true' EXIT

# /ready answers 200 even when degraded, so the verdict is its status field.
status=none
for _ in $(seq 1 90); do
  kill -0 $server 2>/dev/null || { tail -50 "$OUT_DIR/serve.log" >&2; die "dst serve exited before it became ready"; }
  status=$(curl -sf "$DST_URL/ready" | python3 -c 'import json,sys;print(json.load(sys.stdin)["status"])' 2>/dev/null || echo down)
  [ "$status" = ready ] && break
  sleep 2
done
if [ "$status" != ready ]; then
  curl -s "$DST_URL/ready" >&2 || true; tail -50 "$OUT_DIR/serve.log" >&2
  die "dst serve never became ready (last status: $status)"
fi
echo "server ready on $DST_URL"

# bootstrap talks to the database; the token it mints is the org's admin credential.
token=$(dst bootstrap --org "$ORG" | grep -oE 'dstadm_[A-Za-z0-9_-]+' | head -1 || true)
[ -n "$token" ] || die "dst bootstrap printed no admin token"
[ -z "${GITHUB_ACTIONS:-}" ] || echo "::add-mask::$token"
export DST_ADMIN_TOKEN=$token

cd "$SERVE_DIR"
dst plan
# --require-gates: a skipped eval gate (empty suite, provider error, dead warehouse)
# aborts instead of publishing with a warning.
dst apply --require-gates

# 1 = something diverged, 4 = nothing was verified; both fail. The report script
# adds what the exit code can't: every lens in the repo must have been tested.
rc=0
dst test --all --org "$ORG" --json > "$OUT_DIR/test.json" || rc=$?
python3 "$here/test_report.py" "$OUT_DIR/test.json" "$SERVE_DIR/lenses" "$rc" >> "$SUMMARY" || { [ "$rc" -ne 0 ] || rc=1; }
cat "$SUMMARY"
exit "$rc"

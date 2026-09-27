#!/bin/sh
# One scheduled load: dlt, then dbt. dbt runs even when the loader failed (an OpenDota
# outage lands what was fetched and exits 1), so the marts reflect whatever landed.
# Then the source freshness check: a load can exit 0 and still bring nothing new (the
# monthly paid-call cap ends the detail fetch without failing the run), so stale raw
# tables fail the run on their own. The run fails if any of the three did.
cd /app
python load/opendota_pipeline.py
load=$?
cd transform && dbt build --profiles-dir .
transform=$?
dbt source freshness --profiles-dir .
fresh=$?
echo "load exit $load, transform exit $transform, freshness exit $fresh"
[ "$load" -eq 0 ] && [ "$transform" -eq 0 ] && [ "$fresh" -eq 0 ]

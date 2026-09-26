#!/bin/sh
# One scheduled load: dlt, then dbt. dbt runs even when the loader failed (an OpenDota
# outage lands what was fetched and exits 1), so the marts reflect whatever landed.
# The run still fails if either step did.
cd /app
python load/opendota_pipeline.py
load=$?
cd transform && dbt build --profiles-dir .
transform=$?
echo "load exit $load, transform exit $transform"
# For sizing the job's memory limit.
[ -r /sys/fs/cgroup/memory.peak ] && echo "peak memory: $(($(cat /sys/fs/cgroup/memory.peak) / 1048576)) MiB"
[ "$load" -eq 0 ] && [ "$transform" -eq 0 ]

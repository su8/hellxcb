#!/bin/sh
# run the smoke test again and again to catch failures that only happen sometimes, and hangs
# usage: sh tests/repeat.sh [runs] [./hellxcb]   a run taking longer than REPEAT_TIMEOUT (60 s) is HUNG;
# it stops at the first run that does not pass
N=${1:-10}; WMBIN=${2:-./hellxcb}; T=${REPEAT_TIMEOUT:-60}
D=$(dirname "$0"); pass=0; i=0
while [ $i -lt "$N" ]; do
    i=$((i + 1)); s=$(date +%s)
    out=$(timeout "$T" sh "$D/smoke.sh" "$WMBIN" 2>/dev/null); rc=$? # timeout ends the whole run, Xvfb included
    case $rc in 0) r=pass; pass=$((pass + 1)) ;; 124) r=HUNG ;; *) r=FAIL ;; esac
    echo "run $i: $r $(( $(date +%s) - s ))s $(echo "$out" | grep '^FAIL' | tr '\n' ' ')last: $(echo "$out" | tail -1 | cut -c6-)"
    [ $r = pass ] || break
done
echo "$pass of $N runs passed"
[ "$pass" = "$N" ]

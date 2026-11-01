#!/bin/sh
# compare hellxcb builds on Xvfb: time to start, to map, tile and close windows, memory, CPU and size
# usage: sh tests/bench.sh [-r runs] [-n windows] ./hellxcb /path/to/other/hellxcb ...
# Needs Xvfb, gcc and the xcb headers. Runs alternate between the builds, so a busy machine
# slows all of them alike; the table shows the median of each column.
set -u
RUNS=7; N=50
while getopts r:n: o; do case $o in r) RUNS=$OPTARG ;; n) N=$OPTARG ;; *) exit 2 ;; esac; done
shift $((OPTIND - 1))
[ $# -gt 0 ] || { echo "usage: sh tests/bench.sh [-r runs] [-n windows] BIN..." >&2; exit 2; }
B=$(mktemp -d); trap 'rm -rf "$B"' EXIT
gcc -O2 -o "$B/wmbench" "$(dirname "$0")/wmbench.c" -lxcb || exit 1
export DISPLAY=${BENCH_DISPLAY:-:98} XDG_RUNTIME_DIR="$B"
TICK=$(getconf CLK_TCK)

i=0
while [ $i -lt "$RUNS" ]; do
    i=$((i + 1)); k=0
    for bin in "$@"; do
        k=$((k + 1))
        Xvfb "$DISPLAY" -screen 0 1920x1080x24 >/dev/null 2>&1 & X=$!
        sleep 1
        "$bin" >/dev/null 2>&1 & W=$!
        r=$("$B/wmbench" "$N") || r="fail fail fail fail"
        sleep 0.5
        rss=$(sed -n 's/^VmRSS:[[:space:]]*\([0-9]*\).*/\1/p' /proc/$W/status)
        cpu=$(awk -v t="$TICK" '{printf "%.0f", ($14+$15)*1000/t}' /proc/$W/stat)
        echo "$r $rss $cpu" >> "$B/$k"
        kill $W; kill $X; wait $X 2>/dev/null; sleep 0.3
    done
done

echo "median of $RUNS runs, $N windows mapped at once, 1920x1080 Xvfb"
printf '%-28s %9s %9s %9s %9s %8s %7s %8s\n' build ready_ms map_ms settle_ms close_ms rss_kB cpu_ms size_kB
k=0
for bin in "$@"; do
    k=$((k + 1))
    printf '%-28s' "$bin"
    for col in 1 2 3 4 5 6; do sort -n -k$col "$B/$k" | awk -v c=$col '{a[NR]=$c} END {printf " %9s", a[int((NR+1)/2)]}'; done
    strip -o "$B/s" "$bin"; printf ' %8d\n' $(( $(stat -c %s "$B/s") / 1024 ))
done

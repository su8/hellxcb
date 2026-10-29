#!/bin/sh
# smoke test: run hellxcb on a virtual X server, do the things that used to crash it
# or misplace windows, and check it is still alive. Needs: Xvfb xdotool xterm xwininfo
set -u
WMBIN=${1:-./hellxcb}
export DISPLAY=:99
Xvfb "$DISPLAY" -screen 0 800x600x24 >/dev/null 2>&1 & XPID=$!
sleep 1
"$WMBIN" & WM=$!
trap 'kill $WM $XPID 2>/dev/null' EXIT
sleep 1
fail=0

check() {
    sleep 0.5
    if kill -0 "$WM" 2>/dev/null; then echo "ok   $1"; return; fi
    echo "FAIL $1 (window manager died)"; fail=1
    "$WMBIN" & WM=$!; sleep 1
}
expect() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1 (got $2, want $3)"; fail=1; fi; }
geom() { xdotool getwindowgeometry --shell "$1" | sed -n "s/^$2=//p"; }

tag() { sed -n 's/^\[tag: \([0-9]*\)\].*/\1/p' /tmp/hellxcb.txt; }

xdotool key alt+shift+j;               check "move_down on an empty desktop"
xdotool key alt+shift+h;               check "rotate_filled backwards with no windows"
xdotool key alt+3; sleep 0.3
expect "desktop switch still works" "$(tag)" 3

# a "Gimp" window goes to desktop 1 without following (config.h rule), then closes there
xterm -class Gimp & P=$!; sleep 1; kill $P
check "closing the only window on a desktop never visited"
xdotool key alt+1

xdotool key alt+shift+g
xterm -class Gimp & P1=$!; xterm -class Gimp & P2=$!; sleep 1.5
check "grid mode with only floating windows"
W=$(xdotool search --class Gimp | head -1)
xdotool windowmove "$W" 100 300; sleep 0.5
expect "floating window keeps the y it asks for" "$(geom "$W" Y)" 318
kill $P1 $P2; sleep 0.5
xdotool key alt+shift+t

xterm & P1=$!; xterm & P2=$!; sleep 1.5
W=$(xdotool search --onlyvisible --class XTerm | head -1)
expect "border width is BORDER_WIDTH" "$(xwininfo -id "$W" | sed -n 's/.*Border width: //p')" 2
W=$(xdotool getactivewindow)
X0=$(geom "$W" X)
xdotool mousemove --window "$W" 20 20 keydown alt mousedown 1 mousemove_relative 150 40 mouseup 1 keyup alt
xdotool key alt+b key alt+b; sleep 0.5 # retile
[ "$(geom "$W" X)" != "$X0" ]; expect "alt+drag moves the window and it stays" $? 0
kill $P1 $P2

exit $fail

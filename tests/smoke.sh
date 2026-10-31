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

# grid tiles share their borders and the pointer starts on one (the screen centre):
# restacking must not bounce the focus between the two windows forever
for i in 1 2 3 4 5; do xterm >/dev/null 2>&1 & done; sleep 2
timeout 5 xdotool key alt+shift+g; sleep 1
timeout 5 xdotool key alt+shift+t; R=$?
expect "responsive with the pointer on a shared border" $R 0
pkill -x xterm; sleep 0.5
[ $R = 0 ] || { kill -9 "$WM"; "$WMBIN" & WM=$!; sleep 1; }

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
xdotool windowsize "$W" 2000 2000; sleep 0.5
expect "a window asking to be bigger than the screen fits on it" "$(geom "$W" WIDTH)" 796
kill $P1 $P2; sleep 0.5
xdotool key alt+shift+t
xdotool key alt+shift+y; sleep 0.3
expect "cycle_mode goes to the next mode" "$(sed -n 's/.*\[mode: \([a-z]*\)\].*/\1/p' /tmp/hellxcb.txt)" bstack
xdotool key alt+shift+t

xdotool key alt+shift+f
xterm & P1=$!; sleep 1.5
W=$(xdotool search --onlyvisible --class XTerm | head -1)
[ "$(geom "$W" WIDTH)" -lt 700 ]; expect "floating mode keeps the size a window asks for" $? 0
xdotool mousemove --window "$W" 20 20 keydown alt mousedown 1 mousemove_relative 150 40 mouseup 1 keyup alt; sleep 0.5
xdotool key alt+shift+t; sleep 0.5
expect "one Alt+Shift+T tiles windows dragged in floating mode" "$(geom "$W" X)" 0
kill $P1; sleep 0.5

xterm & P1=$!; sleep 1.5
W=$(xdotool search --onlyvisible --class XTerm | head -1)
expect "smart gaps: a lone tiled window gets no gap" "$(geom "$W" X)" 0
shaped() { xwininfo -shape -id "$1" | grep -c "Window shape extents"; }
expect "a lone window filling the screen keeps square corners" "$(shaped "$W")" 0
xterm & P2=$!; sleep 1.5
expect "gaps: with two tiled windows the master is inset by GAPS_INNER" "$(geom "$W" X)" 8
W2=$(xdotool search --onlyvisible --class XTerm | grep -vx "$W" | head -1)
B=$(xwininfo -id "$W" | sed -n 's/.*Border width: //p')
expect "gaps: tiled windows are GAPS_INNER apart" $(( $(geom "$W2" X) - $(geom "$W" X) - $(geom "$W" WIDTH) - 2*B )) 8
expect "tiled windows with gaps get rounded corners" "$(shaped "$W")" 1
kill $P1 $P2; sleep 0.5

xterm & P1=$!; xterm & P2=$!; sleep 1.5
count() { grep -o '\[tag 1 win: [0-9]*\]' /tmp/hellxcb.txt; }
expect "status file counts the windows" "$(count)" "[tag 1 win: 2]"
W=$(xdotool search --onlyvisible --class XTerm | head -1)
expect "border width is BORDER_WIDTH" "$(xwininfo -id "$W" | sed -n 's/.*Border width: //p')" 2
W=$(xdotool getactivewindow)
X0=$(geom "$W" X)
xdotool mousemove --window "$W" 20 20 keydown alt mousedown 1 mousemove_relative 150 40 mouseup 1 keyup alt
xdotool key alt+b key alt+b; sleep 0.5 # retile
[ "$(geom "$W" X)" != "$X0" ]; expect "alt+drag moves the window and it stays" $? 0
xdotool key alt+c; sleep 0.5
expect "closing a window updates the count" "$(count)" "[tag 1 win: 1]"
kill $P1 $P2 2>/dev/null; sleep 0.5

xterm & P1=$!; xterm & P2=$!; sleep 1.5
xterm -class Gimp & P3=$!; sleep 1; kill $P3; sleep 0.5
A=$(xdotool getactivewindow)
B=$(xdotool search --onlyvisible --class XTerm | grep -vx "$A" | head -1)
xdotool mousemove --window "$B" 30 30; sleep 0.5
expect "focus follows the mouse after a floating window closed" "$(xdotool getactivewindow)" "$B"


xdotool key super+z; sleep 1.5
D=$(xdotool search --onlyvisible --class hellxcb-dropdown | head -1)
expect "Super+z starts the drop-down terminal" "$([ -n "$D" ] && [ "$(geom "$D" WIDTH)" -gt 700 ] && echo yes)" yes
expect "the drop-down terminal has the focus" "$(xdotool getwindowfocus)" "$D"
expect "the drop-down terminal is not counted" "$(count)" "[tag 1 win: 2]"
xdotool key super+z; sleep 0.5
expect "Super+z hides it" "$(xdotool search --onlyvisible --class hellxcb-dropdown)" ""
xdotool key super+z; sleep 0.5
expect "Super+z shows it again" "$(xdotool search --onlyvisible --class hellxcb-dropdown)" "$D"
pkill -f "class hellxcb-dropdown"; sleep 0.5; check "the drop-down terminal exits"
kill $P1 $P2

exit $fail

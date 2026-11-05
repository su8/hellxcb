#!/bin/sh
# smoke test: run hellxcb on a virtual X server, do the things that used to crash it
# or misplace windows, and check it is still alive. Needs: Xvfb xdotool xterm xwininfo
# The expected numbers assume the default config.h: 800x600 screen, PANEL_HEIGHT 18,
# BORDER_WIDTH 2, GAPS_INNER 8, SMART_GAPS True, the MPlayer and Gimp rules.
set -u
WMBIN=${1:-./hellxcb}
export DISPLAY=${SMOKE_DISPLAY:-:99} # another display: SMOKE_DISPLAY=:98 make check
export XDG_RUNTIME_DIR=$(mktemp -d) # a status file of our own, even next to another hellxcb
STATUS=$XDG_RUNTIME_DIR/hellxcb.txt
Xvfb "$DISPLAY" -screen 0 800x600x24 >/dev/null 2>&1 & XPID=$!
sleep 1
"$WMBIN" & WM=$!
trap 'kill $WM $XPID 2>/dev/null; rm -rf "$XDG_RUNTIME_DIR"' EXIT
sleep 1
fail=0

# check NAME: pass if hellxcb is still running; if it died, report it and start a new one
check() {
    sleep 0.5
    if kill -0 "$WM" 2>/dev/null; then echo "ok   $1"; return; fi
    echo "FAIL $1 (window manager died)"; fail=1
    "$WMBIN" & WM=$!; sleep 1
}
# expect NAME GOT WANT: pass if the two values are equal
expect() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1 (got $2, want $3)"; fail=1; fi; }
# geom WINDOW KEY: one value (X, Y, WIDTH or HEIGHT) of a window's geometry
geom() { xdotool getwindowgeometry --shell "$1" | sed -n "s/^$2=//p"; }

# grid tiles share their borders and the pointer starts on one (the screen centre):
# restacking must not bounce the focus between the two windows forever
for i in 1 2 3 4 5; do xterm >/dev/null 2>&1 & done; sleep 2
timeout 5 xdotool key alt+shift+g; sleep 1
timeout 5 xdotool key alt+shift+t; R=$?
expect "responsive with the pointer on a shared border" $R 0
pkill -x xterm; sleep 0.5
[ $R = 0 ] || { kill -9 "$WM"; "$WMBIN" & WM=$!; sleep 1; }  # a hung WM would fail every test below

# tag: the current desktop number from the status file
tag() { sed -n 's/^\[tag: \([0-9]*\)\].*/\1/p' "$STATUS"; }

# list operations on an empty desktop used to dereference NULL
xdotool key alt+shift+j;               check "move_down on an empty desktop"
xdotool key alt+shift+h;               check "rotate_filled backwards with no windows"
xdotool key alt+3; sleep 0.3
expect "desktop switch still works" "$(tag)" 3

# a "Gimp" window goes to desktop 1 without following (config.h rule), then closes there
xterm -class Gimp & P=$!; sleep 1; kill $P
check "closing the only window on a desktop never visited"
xdotool key alt+1

# grid mode with nothing to tile: the layout used to divide by zero
xdotool key alt+shift+g
xterm -class Gimp & P1=$!; xterm -class Gimp & P2=$!; sleep 1.5
check "grid mode with only floating windows"
# a floating window's requested y is below the panel: 300 + PANEL_HEIGHT
W=$(xdotool search --class Gimp | head -1)
xdotool windowmove "$W" 100 300; sleep 0.5
expect "floating window keeps the y it asks for" "$(geom "$W" Y)" 318
# a size request is cut to the screen: 800 - 2*BORDER_WIDTH
xdotool windowsize "$W" 2000 2000; sleep 0.5
expect "a window asking to be bigger than the screen fits on it" "$(geom "$W" WIDTH)" 796
kill $P1 $P2; sleep 0.5
xdotool key alt+shift+t
# from tile, cycle_mode (Alt+Shift+y) goes to bstack
xdotool key alt+shift+y; sleep 0.3
expect "cycle_mode goes to the next mode" "$(sed -n 's/.*\[mode: \([a-z]*\)\].*/\1/p' "$STATUS")" bstack
xdotool key alt+shift+t

# FLOAT mode: a new window keeps its own size; dragging it there must not mark it
# floating for good, so going back to tile mode tiles it at once
xdotool key alt+shift+f
xterm & P1=$!; sleep 1.5
W=$(xdotool search --onlyvisible --class XTerm | head -1)
[ "$(geom "$W" WIDTH)" -lt 700 ]; expect "floating mode keeps the size a window asks for" $? 0
xdotool mousemove --window "$W" 20 20 keydown alt mousedown 1 mousemove_relative 150 40 mouseup 1 keyup alt; sleep 0.5
xdotool key alt+shift+t; sleep 0.5
expect "one Alt+Shift+T tiles windows dragged in floating mode" "$(geom "$W" X)" 0
kill $P1; sleep 0.5

# gaps and rounded corners: a lone window fills the screen, square, with no gap (SMART_GAPS)
xterm & P1=$!; sleep 1.5
W=$(xdotool search --onlyvisible --class XTerm | head -1)
expect "smart gaps: a lone tiled window gets no gap" "$(geom "$W" X)" 0
# shaped: 1 if the window has a shape (rounded corners), 0 if it is a plain rectangle
shaped() { xwininfo -shape -id "$1" | grep -c "Window shape extents"; }
expect "a lone window filling the screen keeps square corners" "$(shaped "$W")" 0
# a second window brings the gaps and the rounded corners
xterm & P2=$!; sleep 1.5
expect "gaps: with two tiled windows the master is inset by GAPS_INNER" "$(geom "$W" X)" 8
W2=$(xdotool search --onlyvisible --class XTerm | grep -vx "$W" | head -1)
B=$(xwininfo -id "$W" | sed -n 's/.*Border width: //p')
# gap between the windows = stack x - master x - master width - both master borders
expect "gaps: tiled windows are GAPS_INNER apart" $(( $(geom "$W2" X) - $(geom "$W" X) - $(geom "$W" WIDTH) - 2*B )) 8
expect "tiled windows with gaps get rounded corners" "$(shaped "$W")" 1
kill $P1 $P2; sleep 0.5

# status file, borders, Alt+drag and Alt+c with two windows
xterm & P1=$!; xterm & P2=$!; sleep 1.5
# count: the window count of desktop 1 from the status file
count() { grep -o '\[tag 1 win: [0-9]*\]' "$STATUS"; }
expect "status file counts the windows" "$(count)" "[tag 1 win: 2]"
W=$(xdotool search --onlyvisible --class XTerm | head -1)
expect "border width is BORDER_WIDTH" "$(xwininfo -id "$W" | sed -n 's/.*Border width: //p')" 2
# Alt+drag makes a tiled window floating where it was dropped; a retile must keep it there
W=$(xdotool getactivewindow)
X0=$(geom "$W" X)
xdotool mousemove --window "$W" 20 20 keydown alt mousedown 1 mousemove_relative 150 40 mouseup 1 keyup alt
xdotool key alt+b key alt+b; sleep 0.5 # retile
[ "$(geom "$W" X)" != "$X0" ]; expect "alt+drag moves the window and it stays" $? 0
# Alt+c asks the window to close; the count drops once it is gone
xdotool key alt+c; sleep 0.5
expect "closing a window updates the count" "$(count)" "[tag 1 win: 1]"
kill $P1 $P2 2>/dev/null; sleep 0.5

# a floating window that closes must not leave the focus stuck: the mouse still moves it
xterm & P1=$!; xterm & P2=$!; sleep 1.5
xterm -class Gimp & P3=$!; sleep 1; kill $P3; sleep 0.5
A=$(xdotool getactivewindow)
B=$(xdotool search --onlyvisible --class XTerm | grep -vx "$A" | head -1)
xdotool mousemove --window "$B" 30 30; sleep 0.5
expect "focus follows the mouse after a floating window closed" "$(xdotool getactivewindow)" "$B"
kill $P1 $P2 2>/dev/null; sleep 0.5

# an xterm rings its bell in the background: Alt+BackSpace jumps to it
xterm -xrm '*bellIsUrgent: true' -e sh -c 'sleep 2; printf "\a"; sleep 30' & P1=$!; sleep 1
U=$(xdotool getactivewindow)
xterm & P2=$!; sleep 2
xdotool key alt+BackSpace; sleep 0.5
expect "Alt+BackSpace focuses the urgent window" "$(xdotool getactivewindow)" "$U"

# Super+right-click starts the menu: the button grab must not leave the pointer frozen
xdotool mousemove --window "$U" 30 30 keydown super click 3 keyup super; sleep 0.5
pkill -x dmenu 2>/dev/null # it would take the keyboard from the tests below
N=$(xdotool search --onlyvisible --class XTerm | grep -vx "$U" | head -1)
xdotool mousemove --window "$N" 30 30; sleep 0.5
expect "the mouse still moves the focus after Super+right-click" "$(xdotool getactivewindow)" "$N"

# the drop-down terminal (Super+z) is not a client: wide, focused, and not counted
xdotool key super+z; sleep 1.5
D=$(xdotool search --onlyvisible --class hellxcb-dropdown | head -1)
expect "Super+z starts the drop-down terminal" "$([ -n "$D" ] && [ "$(geom "$D" WIDTH)" -gt 700 ] && echo yes)" yes
expect "the drop-down terminal has the focus" "$(xdotool getwindowfocus)" "$D"
expect "the drop-down terminal is not counted" "$(count)" "[tag 1 win: 2]"
xdotool key super+z; sleep 0.5
expect "Super+z hides it" "$(xdotool search --onlyvisible --class hellxcb-dropdown)" ""
xdotool key super+z; sleep 0.5
expect "Super+z shows it again" "$(xdotool search --onlyvisible --class hellxcb-dropdown)" "$D"
# its process exits: hellxcb forgets the window and must not crash on it
pkill -f "class hellxcb-dropdown"; sleep 0.5; check "the drop-down terminal exits"

# config.h sends MPlayer to desktop 4 and follows it; closing it there must leave this desktop's active window
A=$(xdotool getactivewindow)
xterm -class MPlayer & P3=$!; sleep 1.5
xdotool key alt+1; sleep 0.5
kill $P3; sleep 0.8
expect "a window closing on a hidden desktop keeps the active window" "$(xdotool getactivewindow 2>/dev/null)" "$A"
kill $P1 $P2

# growing or shrinking the first stack window keeps every stack window at least MINWSZ (50) high
for i in 1 2 3; do xterm -class stacktest & done; sleep 2
xdotool key alt+shift+t; sleep 0.3
smallest() { for w in $(xdotool search --class stacktest); do geom "$w" HEIGHT; done | sort -n | head -1; }
xdotool key --repeat 100 --delay 5 alt+p; sleep 0.8; expect "a stack window grown far leaves the others at least 50 high" "$([ "$(smallest)" -ge 50 ] && echo yes || echo "no, $(smallest)")" yes
xdotool key --repeat 200 --delay 5 alt+o; sleep 0.8; expect "a stack window shrunk far stays at least 50 high" "$([ "$(smallest)" -ge 50 ] && echo yes || echo "no, $(smallest)")" yes
pkill -f 'class stacktest'; sleep 0.5

exit $fail

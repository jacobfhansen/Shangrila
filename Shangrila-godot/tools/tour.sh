#!/usr/bin/env bash
# Runs the developer tour fast, and saves its screenshots in .tour/.
#   tools/tour.sh            the whole tour
#   tools/tour.sh quests     the Lehan quests and the council
#   tools/tour.sh mines      the mines job, from the entrance to the report
# Vsync is off, so the game draws as fast as it can (a hidden window is no longer throttled to
# about one frame a second), and time runs 5x faster, so the tour's waits, walks and typing
# go by quicker. The tour writes its own save file (tour_save.json), never the player's.
# The log goes to tour.log next to the screenshots.
set -u
cd "$(dirname "$0")/.."
part="${1:-}"
args=(--path . --disable-vsync --time-scale "${TOUR_TIME_SCALE:-5}" -- "--tour=$PWD/.tour")
[ -n "$part" ] && args+=("--part=$part")
log="$PWD/.tour/tour.log"
start=$(date +%s)
# `script` gives Godot a terminal, so its output isn't buffered until the end.
timeout -s KILL "${TOUR_TIMEOUT:-900}" script -qfc "/snap/bin/godot-4 ${args[*]}" "$log" > /dev/null
status=$?
echo "tour ${part:-full}: $(( $(date +%s) - start ))s, exit $status"
errors=$(grep -a -c -E "SCRIPT ERROR|^ERROR|[^_]ERROR:" "$log")
echo "errors: $errors"
grep -a -E "SCRIPT ERROR|ERROR:" -A2 "$log" | head -30
grep -a -E "part done|tour done" "$log"

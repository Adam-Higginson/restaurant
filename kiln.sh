#!/usr/bin/env bash
# Fires every third-party model the game uses that's stale in the Kiln
# (tools/kiln/fire.py, in Blender), then imports the fired files.
#
#   ./kiln.sh            fire what's stale
#   ./kiln.sh --all      fire everything again
#   ./kiln.sh --list     only say where each model stands
#   ./kiln.sh --report   also print the budget report (every model against its look)
#   ./kiln.sh crab pot   only models whose name has one of these words
#
# Needs Blender 4.4 (BLENDER=<path to blender.exe> if it's elsewhere) and the
# art packs in assets/third_party/. The fired files stay there, gitignored.
set -e
GODOT="${GODOT:-C:/Godot/godot_console.exe}"
cd "$(dirname "$0")"
status=0
"$GODOT" --headless --path . res://tools/kiln/fire_all.tscn -- "$@" || status=$?
"$GODOT" --headless --path . --import > /dev/null 2>&1 || true
exit $status

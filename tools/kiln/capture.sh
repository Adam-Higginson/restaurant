#!/usr/bin/env bash
# Photographs the Lookbook: every fired model before and after, close up,
# from a few angles (and animated ones at a few moments of a walk).
#
#   tools/kiln/capture.sh <folder>            every exhibit
#   tools/kiln/capture.sh <folder> crab       only exhibits named with "crab"
#
# It opens a window (the pictures need the real renderer) and closes it when
# done.
set -e
GODOT="${GODOT:-C:/Godot/godot_console.exe}"
folder="${1:?say which folder to save the pictures in}"
only="${2:-}"
cd "$(dirname "$0")/../.."
"$GODOT" --path . --resolution 1600x900 res://scenes/tools/lookbook.tscn -- \
	"--capture=$folder" "--only=$only"

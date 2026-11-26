#!/usr/bin/env bash
# Paints our placeholder textures (assets/placeholder/textures/) from the pixel-art originals in tools/textures/originals/ (#135),
# then imports them.
#
#   tools/textures/paint_placeholders.sh            every texture
#   tools/textures/paint_placeholders.sh rug chart  only these
#
# Needs Blender 4.4 (BLENDER=<path to blender.exe> if it's elsewhere). The
# same originals always paint the same textures.
set -e
BLENDER="${BLENDER:-C:/Program Files/Blender Foundation/Blender 4.4/blender.exe}"
GODOT="${GODOT:-C:/Godot/godot_console.exe}"
cd "$(dirname "$0")/../.."
"$BLENDER" -b --factory-startup --python tools/textures/paint_placeholders.py -- \
	assets/placeholder/textures tools/textures/originals "$@" 2>&1 | grep -E "PAINTED|Error"
"$GODOT" --headless --path . --import > /dev/null 2>&1 || true

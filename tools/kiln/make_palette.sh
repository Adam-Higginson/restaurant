#!/usr/bin/env bash
# Makes the Salt and Ember palette (data/art/palettes/salt_and_ember.tres)
# from our own placeholder textures and every fired texture (as it was before
# any palette: the .raw.png copies), then you can
# fire everything again with it (./kiln.sh --all).
#
#   tools/kiln/make_palette.sh          64 colours
#   tools/kiln/make_palette.sh 32       another number of colours
#
# Needs Blender 4.4 (BLENDER=<path to blender.exe> if it's elsewhere).
set -e
BLENDER="${BLENDER:-C:/Program Files/Blender Foundation/Blender 4.4/blender.exe}"
cd "$(dirname "$0")/../.."
count="${1:-64}"
mkdir -p data/art/palettes
images=()
while IFS= read -r -d '' file; do
	images+=("$file")
done < <(find assets/placeholder/textures -name '*.png' -print0; find assets/third_party/_kiln -name '*.raw.png' -print0 2>/dev/null)
"$BLENDER" -b --factory-startup --python tools/kiln/make_palette.py -- \
	data/art/palettes/salt_and_ember.tres "$count" "${images[@]}" 2>&1 | grep PALETTE

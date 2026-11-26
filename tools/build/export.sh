#!/usr/bin/env bash
# Exports a release build of the game for Windows and macOS into builds/:
#   builds/windows/  SaltAndEmber.exe, SaltAndEmber.pck, CREDITS.txt, licences/
#   builds/macos/    SaltAndEmber.zip (the app, ad-hoc signed)
#   builds/extras/   CREDITS.txt and licences/, for the workflow to add to the
#                    Mac zip
#   builds/build.env every name the build goes by (see BuildInfo.env_for)
# then checks the exported game starts without errors.
#
# The publish workflow (.github/workflows/publish.yml) runs this, zips the
# builds and makes the GitHub Release. It also works by hand in Git Bash, to
# try a build before publishing:
#   tools/build/export.sh
# It needs the art in assets/third_party/ (see CLAUDE.md) and the Godot
# export templates. Set GODOT to use another Godot binary.
set -euo pipefail

GODOT="${GODOT:-/c/Godot/godot_console.exe}"
cd "$(dirname "$0")/../.."

# Without the art the build would quietly be greybox: refuse instead.
for needed in assets/third_party/kaykit_restaurant \
		assets/third_party/quaternius_base_characters assets/third_party/meshy; do
	if [ ! -d "$needed" ]; then
		echo "error: $needed is missing. Clone the art first (see CLAUDE.md)." >&2
		exit 1
	fi
done

commit="$(git rev-parse --short=7 HEAD)"
rm -rf builds
mkdir -p builds/windows builds/macos
# Godot mustn't import what it exports.
touch builds/.gdignore

# The stamp and the file list change these two files: put them back after.
cp project.godot builds/project.godot.bak
cp export_presets.cfg builds/export_presets.cfg.bak
restore() {
	cp builds/project.godot.bak project.godot
	cp builds/export_presets.cfg.bak export_presets.cfg
	rm -f builds/project.godot.bak builds/export_presets.cfg.bak
}
trap restore EXIT

echo "== Importing"
"$GODOT" --headless --path . --import
echo "== Stamping the build and listing its files"
"$GODOT" --headless --path . -s res://tools/build/prepare_export.gd -- "$commit"
# shellcheck source=/dev/null
source builds/build.env

echo "== Exporting $LABEL for Windows"
"$GODOT" --headless --path . --export-release "Windows" builds/windows/SaltAndEmber.exe
echo "== Exporting $LABEL for macOS"
"$GODOT" --headless --path . --export-release "macOS" builds/macos/SaltAndEmber.zip
for made in builds/windows/SaltAndEmber.exe builds/windows/SaltAndEmber.pck \
		builds/macos/SaltAndEmber.zip; do
	if [ ! -s "$made" ]; then
		echo "error: the export didn't make $made." >&2
		exit 1
	fi
done
# What goes beside the game in every zip: the credits, and the fonts'
# licences, which the SIL Open Font Licence asks to travel with them.
mkdir -p builds/extras/licences
cp CREDITS.txt builds/extras/
cp assets/fonts/OFL-*.txt builds/extras/licences/
cp -r builds/extras/. builds/windows/

# Run the exported game data for ten seconds with this Godot, headless: a
# missing file or a broken script shows up as an error. Its user folder is
# a scratch one, so it never sees or writes a real save.
echo "== Starting the exported game"
scratch="$(pwd)/builds/smoke_user"
mkdir -p "$scratch"
# From inside the build, so it can't find the project's own files instead.
(cd builds/windows && APPDATA="$scratch" XDG_DATA_HOME="$scratch" "$GODOT" --headless \
	--main-pack SaltAndEmber.pck --quit-after 600 > ../smoke.log 2>&1) || true
rm -rf "$scratch"
# "Resources still in use at exit" is printed by every run of the game, from
# the editor too, as it quits: not a fault in the build.
if grep -E "ERROR|Parse Error" builds/smoke.log | grep -v "resources still in use at exit"; then
	echo "error: the exported game reported errors (builds/smoke.log)." >&2
	exit 1
fi
if ! grep -q "Godot Engine" builds/smoke.log; then
	echo "error: the exported game didn't start (builds/smoke.log)." >&2
	cat builds/smoke.log >&2
	exit 1
fi

du -sh builds/windows builds/macos
echo "== Built $LABEL"

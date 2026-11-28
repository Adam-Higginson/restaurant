#!/usr/bin/env bash
# Opens a Godot editor on a project folder (default: this checkout) so the
# godot-ai plugin connects Claude Code to it (#237). See "Seeing the game" in
# CLAUDE.md.
#
# The editor is started through Windows Explorer, as an ordinary app. Started
# straight from the Claude desktop app, it would get the app's private copy of
# AppData\Local, and godot-ai's key file would land where Claude Code's
# godot-ai server can't read it.
#
# Usage: tools/godot_ai/open_editor.sh [project folder]
set -euo pipefail

project="$(cygpath -w "${1:-$(git rev-parse --show-toplevel)}")"
godot="${GODOT_EDITOR:-C:\\Godot\\godot.exe}"
launcher="$(mktemp -d)/open_godot_editor.bat"
printf '@echo off\r\nset GODOT_AI_DISABLE_TELEMETRY=1\r\nstart "" "%s" --path "%s" -e\r\n' \
	"$godot" "$project" > "$launcher"
# Explorer exits with 1 even when it has opened the file.
explorer.exe "$(cygpath -w "$launcher")" || true
echo "Opening the Godot editor on $project"

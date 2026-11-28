#!/usr/bin/env bash
# Closes the Godot editor that tools/godot_ai/open_editor.sh opened on a
# project folder (default: this checkout), and no other. It asks the editor to
# close rather than killing it, so the godot-ai plugin stops its own server.
#
# Usage: tools/godot_ai/close_editor.sh [project folder]
set -euo pipefail

project="$(cygpath -w "${1:-$(git rev-parse --show-toplevel)}")"
pids="$(powershell.exe -NoProfile -Command \
	"Get-CimInstance Win32_Process -Filter \"Name='godot.exe'\" | ForEach-Object { \"\$(\$_.ProcessId)|\$(\$_.CommandLine)\" }" \
	| tr -d '\r' | grep -F -- "--path \"$project\" -e" | cut -d'|' -f1 || true)"
if [ -z "$pids" ]; then
	echo "No Godot editor is open on $project"
	exit 0
fi
for pid in $pids; do
	echo "Closing the Godot editor on $project (process $pid)"
	taskkill //PID "$pid" > /dev/null
done

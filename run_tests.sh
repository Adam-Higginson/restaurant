#!/usr/bin/env bash
# Runs the gdUnit4 tests, fast.
#
# The same as addons/gdUnit4/runtest.sh (which we can't edit), plus
# --fixed-fps 60: every frame still advances exactly 1/60 s of game time, but
# Godot starts the next one straight away instead of waiting for the real
# clock. Tests that wait for customers to walk or the clock to tick no longer
# wait in real time, so the full suite takes about a minute instead of four.
# It also makes runs more repeatable: one rendered frame per physics tick.
#
# Usage (Git Bash):
#   ./run_tests.sh                                  every test
#   ./run_tests.sh -a res://tests/scripts/sea       one folder or suite
# Set GODOT_BIN if Godot isn't at C:\Godot\godot_console.exe.

godot="${GODOT_BIN:-/c/Godot/godot_console.exe}"
if [ ! -f "$godot" ]; then
    echo "Godot not found at '$godot'. Set GODOT_BIN to your Godot binary."
    exit 1
fi

args=("$@")
if [ ${#args[@]} -eq 0 ]; then
    args=(-a res://tests)
fi

# -c runs every test rather than stopping a suite at its first failure.
# --remote-debug at port 0 stops Godot dropping into its interactive debugger
# on a script error (the port is never open, so it always fails to connect).
"$godot" --path . --fixed-fps 60 -s -d --remote-debug tcp://127.0.0.1:0 \
    res://addons/gdUnit4/bin/GdUnitCmdTool.gd "${args[@]}" -c --headless --ignoreHeadlessMode
exit_code=$?
echo "Run tests ends with $exit_code"

# Copy the run's log into reports/, as runtest.sh does.
"$godot" --headless --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd "${args[@]}" > /dev/null
exit $exit_code

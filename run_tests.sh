#!/usr/bin/env bash
# Runs the gdUnit4 tests, fast.
#
# With no arguments it runs every test, split across several copies of Godot
# at once (JOBS of them: three for every four processor cores unless you say
# otherwise, so 12 on a 16-core machine), so the whole suite takes about
# twenty-five seconds instead of over two minutes. Each copy runs a share of the
# test suites; the shares are balanced using how long each suite took last
# time (kept in reports/suite_times.txt), so no copy is left with all the
# slow ones. At the end it prints any failures and one summary.
#
# With arguments (-a ...) it runs just those in a single copy, as
# addons/gdUnit4/runtest.sh would (we can't edit that one).
#
# Either way Godot runs with --fixed-fps 60: every frame still advances
# exactly 1/60 s of game time, but Godot starts the next one straight away
# instead of waiting for the real clock. A higher number wouldn't be faster:
# tests wait for a number of physics ticks, and Godot already runs them as
# fast as one processor core can.
#
# Usage (Git Bash):
#   ./run_tests.sh                                  every test, in parallel
#   JOBS=12 ./run_tests.sh                          ...across 12 copies
#   JOBS=1 ./run_tests.sh                           ...one after another
#   ./run_tests.sh -a res://tests/scripts/sea       one folder or suite
# Set GODOT_BIN if Godot isn't at C:\Godot\godot_console.exe.

godot="${GODOT_BIN:-/c/Godot/godot_console.exe}"
if [ ! -f "$godot" ]; then
    echo "Godot not found at '$godot'. Set GODOT_BIN to your Godot binary."
    exit 1
fi

# -c runs every test rather than stopping a suite at its first failure.
# --remote-debug at port 0 stops Godot dropping into its interactive debugger
# on a script error (the port is never open, so it always fails to connect).
run_godot() {
    "$godot" --path . --fixed-fps 60 -s -d --remote-debug tcp://127.0.0.1:0 \
        res://addons/gdUnit4/bin/GdUnitCmdTool.gd "$@" -c --headless --ignoreHeadlessMode
}

# Takes the colour codes out of gdUnit's output, so it can be searched.
plain() {
    sed 's/\x1b\[[0-9;]*m//g' "$@"
}

# ---- Named tests: one copy of Godot, output straight to the screen.
if [ $# -gt 0 ]; then
    run_godot "$@"
    exit_code=$?
    echo "Run tests ends with $exit_code"
    # Copy the run's log into reports/, as runtest.sh does.
    "$godot" --headless --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd "$@" > /dev/null
    exit $exit_code
fi

# ---- Every test: several copies of Godot at once.
cores=$(nproc 2> /dev/null || echo 8)
default_jobs=$(( cores * 3 / 4 ))
[ "$default_jobs" -lt 1 ] && default_jobs=1
jobs="${JOBS:-$default_jobs}"
times="reports/suite_times.txt"
mkdir -p reports
rm -f reports/shard_*.log reports/shard_*.suites
started=$(date +%s)

# Deal the suites out: slowest first, each to whichever share is lightest so
# far. A suite never timed before counts as one second.
[ -f "$times" ] || : > "$times"
find tests -name "*_test.gd" | sort | awk -v jobs="$jobs" -v times="$times" '
    BEGIN {
        while ((getline line < times) > 0) {
            split(line, part, " ")
            took[part[2]] = part[1]
        }
    }
    {
        suite = "res://" $0
        ms = (suite in took) ? took[suite] : 1000
        printf "%d %s\n", ms, suite
    }' | sort -rn | awk -v jobs="$jobs" '
    {
        lightest = 0
        for (i = 1; i < jobs; i++) if (load[i] < load[lightest]) lightest = i
        load[lightest] += $1
        print $2 > ("reports/shard_" lightest ".suites")
    }'

echo "Running the tests across $jobs copies of Godot..."
pids=()
shards=()
for file in reports/shard_*.suites; do
    shard="${file#reports/shard_}"
    shard="${shard%.suites}"
    args=()
    while read -r suite; do
        args+=(-a "$suite")
    done < "$file"
    # Each copy keeps its own save file and its own reports, so two never
    # write the same one.
    TEST_SHARD="$shard" run_godot "${args[@]}" -rd "res://reports/shard_$shard" \
        > "reports/shard_$shard.log" 2>&1 &
    pids+=($!)
    shards+=("$shard")
done

exit_code=0
for i in "${!pids[@]}"; do
    wait "${pids[$i]}"
    code=$?
    if [ $code -ne 0 ]; then
        exit_code=$code
    fi
done

# Remember how long each suite took, for dealing them out next time.
plain reports/shard_*.log | awk '
    /^Run Test Suite: / { suite = $4 }
    /^Statistics: / && suite != "" {
        ms = 0
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^[0-9]+min$/) ms += $i * 60000
            else if ($i ~ /^[0-9]+s$/) ms += $i * 1000
            else if ($i ~ /^[0-9]+ms$/) ms += $i + 0
        }
        printf "%d %s\n", ms, suite
        suite = ""
    }' > "$times"

# What failed, with gdUnit's account of why: from each FAILED line up to the
# next test starting.
failures=$(plain reports/shard_*.log | awk '
    / FAILED / { showing = 1 }
    / STARTED/ || /^Run Test Suite: / || /^Statistics: / { showing = 0 }
    showing { print }')
if [ -n "$failures" ]; then
    echo
    echo "$failures"
fi

# A copy that stopped without finishing (a script error, a crash) has no
# summary: say which, so it isn't mistaken for a pass.
for shard in "${shards[@]}"; do
    if ! plain "reports/shard_$shard.log" | grep -q "^Overall Summary:"; then
        echo
        echo "Copy $shard stopped before finishing. The end of reports/shard_$shard.log:"
        plain "reports/shard_$shard.log" | grep -v "^$" | tail -15
        [ $exit_code -eq 0 ] && exit_code=1
    fi
done

echo
plain reports/shard_*.log | awk '
    /^Overall Summary:/ {
        cases += $3; errors += $7; failed += $10; flaky += $13; skipped += $16; orphans += $19
    }
    END {
        printf "Overall Summary: %d test cases | %d errors | %d failures | %d flaky | %d skipped | %d orphans |\n",
            cases, errors, failed, flaky, skipped, orphans
    }'
echo "Took $(( $(date +%s) - started )) seconds. Each copy's full output is in reports/shard_*.log."
echo "Run tests ends with $exit_code"
exit $exit_code

#!/usr/bin/env bash
# Usage: timed.sh NAME COMMAND [ARGS...]
# Runs COMMAND, then appends one line "NAME<TAB>start<TAB>end<TAB>exit_code" (Unix seconds)
# to "$REPORT_DIR/steps.tsv". Exits with the exit code of COMMAND.
set -uo pipefail
: "${REPORT_DIR:?REPORT_DIR must be set}"
name="$1"
shift
mkdir -p "$REPORT_DIR"
start="$(date +%s)"
"$@"
code=$?
end="$(date +%s)"
printf '%s\t%s\t%s\t%s\n' "$name" "$start" "$end" "$code" >> "$REPORT_DIR/steps.tsv"
exit "$code"

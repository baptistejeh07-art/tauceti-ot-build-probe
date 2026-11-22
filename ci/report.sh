#!/usr/bin/env bash
# Usage: report.sh REPORT_DIR SEARCH_ROOT VARIANT
# Writes REPORT_DIR/build-report.md from the files the earlier steps left in REPORT_DIR, and
# appends it to the job summary. SEARCH_ROOT is the directory under which build outputs
# (.olean files) are counted. Every figure says what it counts; a missing input is reported
# as missing, never as zero.
set -uo pipefail
out="$1"
root="$2"
variant="$3"
rep="$out/build-report.md"
stamp="$out/stamp-before-build"

val() { grep -m1 "^$1=" "$out/build-status.txt" 2>/dev/null | cut -d= -f2-; }

{
  echo "# Build report: Tau Ceti optimal transport layer"
  echo
  echo "- variant: \`$variant\`"
  echo "- Tau Ceti repository and revision: \`${TAUCETI_REPO:-?}\` @ \`${TAUCETI_REV:-?}\`"
  echo "- pinned Lean toolchain: \`${LEAN_TOOLCHAIN:-?}\`; pinned Mathlib revision: \`${MATHLIB_REV:-?}\`"
  echo
  echo "## Machine"
  echo '```'
  cat "$out/runner.txt" 2>/dev/null || echo "runner.txt missing"
  echo '```'
  echo
  echo "## Pin checks"
  echo '```'
  cat "$out/pins.txt" 2>/dev/null || echo "pins.txt missing"
  echo '```'
  echo
  echo "## Step durations (steps run through ci/timed.sh; checkout and upload steps are not timed here)"
  echo
  echo "| step | seconds | exit code |"
  echo "|---|---|---|"
  if [ -f "$out/steps.tsv" ]; then
    awk -F'\t' '{printf "| %s | %d | %s |\n", $1, $3-$2, $4}' "$out/steps.tsv"
  else
    echo "| steps.tsv missing | | |"
  fi
  echo
  echo "## Build"
  if [ -f "$out/build-status.txt" ]; then
    code="$(val exit_code)"; s="$(val start)"; e="$(val end)"
    echo "- lake build exit code: \`$code\` (0 = success, 124 = time limit reached, 2 = no targets)"
    if [ -n "$s" ] && [ -n "$e" ]; then echo "- lake build wall time: $(( e - s )) s (limit: $(val minutes_limit) min)"; fi
    echo "- targets passed to lake build (modules under TauCeti/MeasureTheory/OptimalTransport): $(val targets)"
  else
    echo "- build-status.txt missing: the build step did not run or did not finish"
  fi
  echo
  echo "## Memory and disk"
  echo "Disk after the Mathlib cache was fetched (df -Pk, kB):"
  echo '```'
  cat "$out/disk-after-cache.txt" 2>/dev/null || echo "disk-after-cache.txt missing"
  echo '```'
  if [ -s "$out/resources.tsv" ]; then
    total="$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"
    minavail="$(awk 'NR==1||$2<m{m=$2} END{print m}' "$out/resources.tsv")"
    mindisk="$(awk 'NR==1||$3<m{m=$3} END{print m}' "$out/resources.tsv")"
    n="$(wc -l < "$out/resources.tsv")"
    echo "- samples (every 10 s during lake build): $n"
    echo "- MemTotal: $total kB; lowest MemAvailable seen: $minavail kB; so at most $(( total - minavail )) kB in use at the worst sample"
    echo "- lowest free disk seen on the build filesystem: $mindisk kB"
  else
    echo "- resources.tsv missing or empty"
  fi
  if grep -q "Maximum resident set size" "$out/time-v.txt" 2>/dev/null; then
    echo "- GNU time, largest single process in the build tree: $(grep 'Maximum resident set size' "$out/time-v.txt" | sed 's/^[[:space:]]*//')"
  else
    echo "- GNU time: $(head -n 1 "$out/time-v.txt" 2>/dev/null || echo 'time-v.txt missing')"
  fi
  echo
  echo "## Build outputs (.olean files under the search root)"
  if [ -f "$stamp" ]; then
    echo "| what is counted | total present | written after the build started |"
    echo "|---|---|---|"
    for pat in "TauCeti/MeasureTheory/OptimalTransport" "TauCeti" "Mathlib"; do
      tot="$(find "$root" -name '*.olean' -path "*/lib/lean/$pat/*" 2>/dev/null | wc -l)"
      new="$(find "$root" -name '*.olean' -path "*/lib/lean/$pat/*" -newer "$stamp" 2>/dev/null | wc -l)"
      echo "| .olean under lib/lean/$pat/ | $tot | $new |"
    done
    echo
    echo "A non-zero count of Mathlib .olean files written after the build started means that Mathlib's cache did not cover the pinned revision and Mathlib modules were compiled."
  else
    echo "- no build stamp: the build step did not start"
  fi
  echo
  echo "## Build log"
  if [ -f "$out/build.log" ]; then
    echo "- lines in build.log: $(wc -l < "$out/build.log")"
    echo "- lines containing \"error\": $(grep -c 'error' "$out/build.log")"
    echo "- lines containing \"warning\": $(grep -c 'warning' "$out/build.log")"
    echo
    echo "First 60 lines containing \"error\":"
    echo '```'
    grep -n -m 60 'error' "$out/build.log" | cut -c1-400
    echo '```'
    echo
    echo "Last 40 lines of the log:"
    echo '```'
    tail -n 40 "$out/build.log" | cut -c1-400
    echo '```'
  else
    echo "- build.log missing"
  fi
} > "$rep"

cat "$rep" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
cat "$rep"

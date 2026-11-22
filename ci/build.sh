#!/usr/bin/env bash
# Usage: build.sh WORKDIR TARGETS_FILE MINUTES REPORT_DIR
# Runs `lake build <targets>` in WORKDIR under a time limit of MINUTES, while sampling
# MemAvailable and free disk every 10 s. Never fails by itself: the exit code of the build is
# written to REPORT_DIR/build-status.txt and checked by a later step, so that the report is
# always produced.
#   exit code 124 = the time limit was reached (coreutils `timeout`).
set -uo pipefail
workdir="$1"
targets="$2"
minutes="$3"
out="$4"
mkdir -p "$out"
cd "$workdir"
mapfile -t args < "$targets"
if [ "${#args[@]}" -eq 0 ]; then
  # An empty list would make `lake build` build the package's default targets instead.
  printf 'exit_code=%s\ntargets=0\n' 2 > "$out/build-status.txt"
  echo "no targets: refusing to run a bare lake build"
  exit 0
fi

# Marker for "written by this build" (see report.sh).
touch "$out/stamp-before-build"

# Resource sampler: "unix_seconds mem_available_kB disk_free_kB" every 10 s.
(
  while :; do
    printf '%s %s %s\n' "$(date +%s)" \
      "$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)" \
      "$(df -Pk . | awk 'NR==2{print $4}')"
    sleep 10
  done
) > "$out/resources.tsv" 2>/dev/null &
sampler=$!

# Peak resident memory of the largest single process (GNU time), if the tool is present.
timer=()
if [ -x /usr/bin/time ]; then
  timer=(/usr/bin/time -v -o "$out/time-v.txt")
else
  echo "/usr/bin/time not found: no per-process peak memory" > "$out/time-v.txt"
fi

start="$(date +%s)"
"${timer[@]}" timeout --signal=TERM --kill-after=120 "${minutes}m" \
  lake build "${args[@]}" 2>&1 | tee "$out/build.log"
code="${PIPESTATUS[0]}"
end="$(date +%s)"
kill "$sampler" 2>/dev/null || true

printf 'exit_code=%s\nstart=%s\nend=%s\nminutes_limit=%s\ntargets=%s\n' \
  "$code" "$start" "$end" "$minutes" "${#args[@]}" > "$out/build-status.txt"
echo "lake build exit code: $code (124 means the time limit was reached)"
exit 0

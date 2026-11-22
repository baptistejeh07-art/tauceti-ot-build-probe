#!/usr/bin/env bash
# Usage: runner-info.sh OUTPUT_FILE
# Records what the machine reports about itself. Every line is best effort.
set -uo pipefail
out="$1"
{
  echo "date_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "uname: $(uname -srm)"
  echo "os: $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"
  echo "image: ${ImageOS:-unknown} ${ImageVersion:-unknown}"
  echo "nproc: $(nproc)"
  echo "mem_total_kB: $(awk '/^MemTotal:/{print $2}' /proc/meminfo)"
  echo "swap_total_kB: $(awk '/^SwapTotal:/{print $2}' /proc/meminfo)"
  echo "vm.max_map_count: $(cat /proc/sys/vm/max_map_count)"
  echo "disk (df -Pk of the workspace):"
  df -Pk "${GITHUB_WORKSPACE:-.}"
} > "$out" 2>&1
cat "$out"

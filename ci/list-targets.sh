#!/usr/bin/env bash
# Usage: list-targets.sh SOURCE_ROOT TARGET_PREFIX OUTPUT_FILE
# Writes one Lake target per line, one for every .lean file under
# SOURCE_ROOT/TauCeti/MeasureTheory/OptimalTransport, in the form TARGET_PREFIX+Module.Name
# (Lake target syntax `+A` = module A, `@a/+A` = module A of package a; see README.md, "Sources").
set -euo pipefail
src="$1"
prefix="$2"
out="$3"
layer="TauCeti/MeasureTheory/OptimalTransport"
test -d "$src/$layer"
( cd "$src" && find "$layer" -name '*.lean' -type f | LC_ALL=C sort ) \
  | sed -e 's#\.lean$##' -e 's#/#.#g' -e "s#^#${prefix}+#" > "$out"
echo "targets: $(wc -l < "$out") (first: $(head -n 1 "$out"))"

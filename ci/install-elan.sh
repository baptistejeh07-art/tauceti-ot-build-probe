#!/usr/bin/env bash
# Install a pinned elan release, verified by SHA-256, then the Lean toolchain named by the
# `lean-toolchain` file of the current directory.
#
# Required environment: ELAN_VERSION, ELAN_SHA256.
#
# Sources (see README.md, "Sources"):
#   - release asset URL pattern and checksum: the elan release page for the pinned version,
#     https://github.com/leanprover/elan/releases ; the same version and checksum are used by
#     Tau Ceti's own CI (.github/workflows/ci.yml in TauCetiProject/TauCeti at the pinned revision);
#   - installer flags `-y`, `--no-modify-path`, `--default-toolchain none`: help text in
#     https://raw.githubusercontent.com/leanprover/elan/v4.2.3/elan-init.sh ;
#   - `elan toolchain install "$(cat lean-toolchain)"`: Tau Ceti's ci.yml (same file).
set -euo pipefail
: "${ELAN_VERSION:?ELAN_VERSION must be set}"
: "${ELAN_SHA256:?ELAN_SHA256 must be set}"

tmp="$(mktemp -d)"
url="https://github.com/leanprover/elan/releases/download/${ELAN_VERSION}/elan-x86_64-unknown-linux-gnu.tar.gz"
curl --fail --retry 3 --connect-timeout 15 --max-time 300 -sSL "$url" -o "$tmp/elan.tar.gz"
echo "${ELAN_SHA256}  $tmp/elan.tar.gz" | sha256sum -c -
tar -xzf "$tmp/elan.tar.gz" -C "$tmp" elan-init
"$tmp/elan-init" -y --default-toolchain none --no-modify-path
rm -rf "$tmp"

echo "$HOME/.elan/bin" >> "$GITHUB_PATH"
export PATH="$HOME/.elan/bin:$PATH"
elan toolchain install "$(cat lean-toolchain)"
lean --version
lake --version

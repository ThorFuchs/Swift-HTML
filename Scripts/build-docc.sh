#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Build a DocC archive, or a static website when a hosting base path is supplied.
# Optional fourth argument is the published module version; default is 0.2.0.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
scratch=${1:-"$root/.build/docc-build"}
output=${2:-"$root/.build/SwiftHTML.doccarchive"}
base=${3:-}
version=${4:-0.2.0}
mkdir -p "$scratch" "$(dirname -- "$output")"
scratch=$(CDPATH= cd -- "$scratch" && pwd)
output="$(CDPATH= cd -- "$(dirname -- "$output")" && pwd)/$(basename -- "$output")"
cd "$root"
swift package --disable-sandbox --scratch-path "$scratch" dump-symbol-graph --skip-synthesized-members
symbol=$(find "$scratch" -type f -name SwiftHTML.symbols.json -print -quit)
test -n "$symbol"
temp=$(mktemp -d "${TMPDIR:-/tmp}/swifthtml-docc.XXXXXXXX")
trap 'rm -rf "$temp"' EXIT HUP INT TERM
cp "$symbol" "$temp/SwiftHTML.symbols.json"
set -- convert Sources/SwiftHTML/SwiftHTML.docc --additional-symbol-graph-dir "$temp" \
  --fallback-display-name SwiftHTML --fallback-bundle-identifier io.github.thorfuchs.swift-html \
  --fallback-bundle-version "$version" --output-path "$output" --warnings-as-errors
if [ -n "$base" ]; then
  set -- "$@" --transform-for-static-hosting --hosting-base-path "$base"
fi
if command -v docc >/dev/null 2>&1; then docc "$@"; else xcrun docc "$@"; fi
printf 'Documentation archive: %s\n' "$output"

#!/usr/bin/env bash
# Generate the stats dashboard: build data JSON + assemble the static site

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
OUT="${1:-$HERE/out}"

DATA="$OUT/data"
mkdir -p "$DATA"

# Static site
cp -r "$HERE/site/." "$OUT/"

# Data generators
bash "$HERE/lib/languages.sh" "$REPO" "$DATA/languages.json"
bash "$HERE/lib/nix-modules.sh" "$REPO" "$DATA/modules.json"
bash "$HERE/lib/hosts.sh" "$REPO" "$DATA/hosts.json"
bash "$HERE/lib/scripts.sh" "$REPO" "$DATA/scripts.json"

# Build metadata
jq -n \
    --arg commit "$(git -C "$REPO" rev-parse HEAD)" \
    --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{commit: $commit, generated: $date}' >"$DATA/meta.json"

echo "dashboard generated -> $OUT"

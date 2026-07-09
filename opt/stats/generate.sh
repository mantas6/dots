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

# Cache-busting: stamp the current commit into asset URLs
VERSION="$(git -C "$REPO" rev-parse --short HEAD)"
sed -i "s/__VERSION__/$VERSION/g" "$OUT/index.html"

# Data generators
bash "$HERE/lib/languages.sh" "$REPO" "$DATA/languages.json"
bash "$HERE/lib/nix-modules.sh" "$REPO" "$DATA/modules.json"
bash "$HERE/lib/hosts.sh" "$REPO" "$DATA/hosts.json"
bash "$HERE/lib/scripts.sh" "$REPO" "$DATA/scripts.json"
bash "$HERE/lib/commits.sh" "$REPO" "$DATA/commits.json"
bash "$HERE/lib/commits-monthly.sh" "$REPO" "$DATA/commits-monthly.json"
bash "$HERE/lib/stale.sh" "$REPO" "$DATA/stale.json"

# Build metadata
jq -n \
    --arg commit "$(git -C "$REPO" rev-parse HEAD)" \
    --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{commit: $commit, generated: $date}' >"$DATA/meta.json"

echo "dashboard generated -> $OUT"

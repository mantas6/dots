#!/usr/bin/env bash
# Build the host x feature-module matrix from each host's imports block

set -euo pipefail

REPO="$1"
OUT="$2"

cd "$REPO"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

entries="$tmp/entries.jsonl"
: >"$entries"

for dir in nix/hosts/*/; do
    host="$(basename "$dir")"
    file="$dir/default.nix"
    [[ -f "$file" ]] || continue

    # Extract the module names between `imports = with self.nixosModules; [` and `];`.
    # Strip trailing comments, drop fully commented lines, keep bare identifiers.
    raw="$(awk '
		/imports[[:space:]]*=[[:space:]]*with[[:space:]]+self\.nixosModules;/ {flag=1; next}
		flag && /\];/ {flag=0}
		flag {print}
	' "$file" \
        | sed -E 's/#.*$//' \
        | grep -oE '[A-Za-z0-9_-]+' || true)"
    mods='[]'
    [[ -n "$raw" ]] && mods="$(printf '%s\n' "$raw" | sort -u | jq -R . | jq -s .)"

    jq -nc --arg host "$host" --argjson mods "$mods" '{host: $host, modules: $mods}' >>"$entries"
done

jq -s '
	{
		hosts: (map(.host) | sort),
		modules: (map(.modules[]) | unique | sort),
		matrix: (map({(.host): .modules}) | add // {})
	}
' "$entries" >"$OUT"

echo "hosts: $(jq '.hosts | length' "$OUT") hosts -> $OUT"

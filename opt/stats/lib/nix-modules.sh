#!/usr/bin/env bash
# Map flake-parts nixosModules to their source files + collect the nix/ file tree

set -euo pipefail

REPO="$1"
OUT="$2"

cd "$REPO"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# name<TAB>file for every `flake.nixosModules.<name>` / `flake.nixosModules."<name>"`
pairs="$tmp/pairs.tsv"
grep -rHoE 'flake\.nixosModules\.("[^"]+"|[A-Za-z0-9_-]+)' nix --include='*.nix' 2>/dev/null \
    | sed -E 's#^([^:]+):flake\.nixosModules\.("?)([^"]+)"?$#\3\t\1#' \
    | sort -u >"$pairs" || true

# category from a file path
categorize() {
    case "$1" in
        nix/base/*) echo base ;;
        nix/hosts/*) echo hosts ;;
        nix/features/*) echo "${1#nix/features/}" | cut -d/ -f1 ;;
        *) echo other ;;
    esac
}

# modules: [{name, category, files:[{path, last_commit}]}]
# `path` is relative to the repository root (e.g. nix/features/...).
modules="$tmp/modules.json"
: >"$modules"
while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    mapfile -t fs < <(awk -F'\t' -v n="$name" '$1==n {print $2}' "$pairs" | sort -u)
    files_json="$(
        for f in "${fs[@]}"; do
            date="$(git log -1 --format=%cs -- "$f" 2>/dev/null || true)"
            jq -nc --arg path "$f" --arg date "$date" \
                '{path: $path, last_commit: $date}'
        done | jq -s .
    )"
    cat="$(categorize "${fs[0]}")"
    jq -nc --arg name "$name" --arg cat "$cat" --argjson files "$files_json" \
        '{name: $name, category: $cat, files: $files}' >>"$modules"
done < <(awk -F'\t' '{print $1}' "$pairs" | sort -u)

modules_arr="$(jq -s 'sort_by(.category, .name)' "$modules")"

# all nix files (relative) for the tree view
files_arr="$(find nix -type f -name '*.nix' | sed 's#^\./##' | sort | jq -R . | jq -s .)"

jq -n \
    --argjson modules "$modules_arr" \
    --argjson files "$files_arr" \
    '{modules: $modules, files: $files}' >"$OUT"

echo "nix-modules: $(jq '.modules | length' "$OUT") modules -> $OUT"

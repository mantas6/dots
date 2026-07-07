#!/usr/bin/env bash
# Collect the last 10 commits: date, subject, and file types they touched

set -euo pipefail

REPO="$1"
OUT="$2"

cd "$REPO"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

entries="$tmp/entries.jsonl"
: >"$entries"

while IFS='|' read -r sha date subject; do
    # distinct file "types" (extensions) touched by this commit;
    # extensionless files (e.g. bin/ scripts) are bucketed as "none".
    types="$(git diff-tree --no-commit-id --name-only -r "$sha" \
        | while IFS= read -r f; do
            base="${f##*/}"
            if [[ "$base" == *.* ]]; then echo "${base##*.}"; else echo none; fi
        done | sort -u | jq -R . | jq -s .)"
    count="$(git diff-tree --no-commit-id --name-only -r "$sha" | grep -c . || true)"

    jq -nc \
        --arg sha "${sha:0:8}" \
        --arg date "$date" \
        --arg subject "$subject" \
        --argjson types "$types" \
        --argjson count "${count:-0}" \
        '{sha: $sha, date: $date, subject: $subject, filetypes: $types, files_changed: $count}' >>"$entries"
done < <(git log -10 --format='%H|%cs|%s')

jq -s . "$entries" >"$OUT"

echo "commits: $(jq 'length' "$OUT") commits -> $OUT"

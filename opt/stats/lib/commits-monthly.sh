#!/usr/bin/env bash
# Count commits per calendar month across the full git history

set -euo pipefail

REPO="$1" # repo root
OUT="$2"  # output json path

# git log is newest-first; group committer dates by YYYY-MM and count.
git -C "$REPO" log --format='%cd' --date=format:'%Y-%m' \
    | sort \
    | uniq -c \
    | while read -r count month; do
        jq -nc --arg month "$month" --argjson count "$count" \
            '{month: $month, count: $count}'
    done \
    | jq -s 'sort_by(.month)' >"$OUT"

echo "commits-monthly: $(jq 'length' "$OUT") months -> $OUT"

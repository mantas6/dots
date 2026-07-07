#!/usr/bin/env bash
# Find the 10 oldest-modified files: tracked files whose last commit is oldest

set -euo pipefail

REPO="$1"
OUT="$2"

cd "$REPO"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Set of currently-tracked files (excludes deleted paths still in history).
tracked="$tmp/tracked"
git ls-files | sort >"$tracked"

# Walk history newest-first; the first date we see for a file is its last
# modification. One git pass instead of one invocation per file.
seen="$tmp/seen"
: >"$seen"
dates="$tmp/dates" # <date>\t<path>
: >"$dates"

date=""
while IFS= read -r line; do
    case "$line" in
        C\|*)
            date="${line#C|}"
            ;;
        "")
            ;;
        *)
            # first sighting of this path == most recent commit touching it
            if ! grep -qxF "$line" "$seen"; then
                echo "$line" >>"$seen"
                printf '%s\t%s\n' "$date" "$line" >>"$dates"
            fi
            ;;
    esac
done < <(git log --format='C|%cs' --name-only --no-renames)

# Keep only still-tracked files as JSON lines; jq sorts by date and caps at 10.
entries="$tmp/entries.jsonl"
: >"$entries"

while IFS=$'\t' read -r d path; do
    grep -qxF "$path" "$tracked" || continue
    jq -nc --arg path "$path" --arg date "$d" \
        '{path: $path, last_commit: $date}' >>"$entries"
done <"$dates"

jq -s 'sort_by(.last_commit) | .[:10]' "$entries" >"$OUT"

echo "stale: $(jq 'length' "$OUT") files -> $OUT"

#!/usr/bin/env bash
# Build per-month language/line/file series from git history via tokei

set -euo pipefail

REPO="$1" # repo root
OUT="$2"  # output json path

# tokei over an extracted tree, counting every tracked file
# (--hidden includes dotfiles/dirs, --no-ignore disables .gitignore re-parsing;
#  git archive already contains only tracked files, so the count == git-tracked).
run_tokei() {
    tokei --hidden --no-ignore --output json "$1"
}

# Raw newline count across every file in a tree (matches `git ls-files | xargs wc -l`).
raw_lines() {
    find "$1" -type f -print0 | xargs -0 cat 2>/dev/null | wc -l
}

# jq program: reduce tokei output to totals + per-language code counts.
# Excludes the synthetic "Total" key from the language map.
tokei_reduce='
{
  total_lines: (.Total.code // 0),
  total_files: ([.[] | .reports? // [] | length] | add // 0) - (.Total.reports? // [] | length),
  by_language: (to_entries | map(select(.key != "Total")) | map({key: .key, value: (.value.code // 0)}) | from_entries)
}'

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Map each month (YYYY-MM) to its latest commit. git log is newest-first,
# so the first sha seen per month is that month's last commit.
declare -A month_sha
months=()
while IFS='|' read -r sha month; do
    if [[ -z "${month_sha[$month]:-}" ]]; then
        month_sha[$month]="$sha"
        months+=("$month")
    fi
done < <(git -C "$REPO" log --format='%H|%cd' --date=format:'%Y-%m')

# months[] is newest-first; reverse into chronological order.
sorted_months=()
for ((i = ${#months[@]} - 1; i >= 0; i--)); do
    sorted_months+=("${months[i]}")
done

series="$tmp/series.jsonl"
: >"$series"

for month in "${sorted_months[@]}"; do
    sha="${month_sha[$month]}"
    work="$tmp/work"
    rm -rf "$work"
    mkdir -p "$work"
    git -C "$REPO" archive "$sha" | tar -x -C "$work"
    raw="$(raw_lines "$work")"
    run_tokei "$work" | jq -c --arg month "$month" --argjson raw "$raw" \
        "$tokei_reduce + {month: \$month, total_raw_lines: \$raw}" >>"$series"
done

# current snapshot from HEAD (tracked files only, matching the series)
work="$tmp/work"
rm -rf "$work"
mkdir -p "$work"
git -C "$REPO" archive HEAD | tar -x -C "$work"
raw="$(raw_lines "$work")"
current="$(run_tokei "$work" | jq -c --argjson raw "$raw" "$tokei_reduce + {total_raw_lines: \$raw}")"

jq -n \
    --slurpfile series "$series" \
    --argjson current "$current" \
    '{series: $series, current: $current}' >"$OUT"

echo "languages: ${#sorted_months[@]} months -> $OUT"

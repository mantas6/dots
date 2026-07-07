#!/usr/bin/env bash
# Catalog bin/ scripts: path, folder, language, and self-described purpose

set -euo pipefail

REPO="$1"
OUT="$2"

cd "$REPO"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

entries="$tmp/entries.jsonl"
: >"$entries"

# language from the shebang line
lang_of() {
    case "$1" in
        *php*) echo php ;;
        *bash*) echo bash ;;
        */sh | *env\ sh | *sh) echo sh ;;
        *) echo other ;;
    esac
}

while IFS= read -r file; do
    rel="${file#./}"
    folder="$(dirname "$rel" | sed 's#^bin/##; s#^bin$#.#')"
    line1="$(sed -n '1p' "$file")"
    lang="$(lang_of "$line1")"

    # Description: for shell, line 2 if it's a `# ...` comment.
    # For php, the first docblock/`//`/`#` comment line in the head.
    desc=""
    if [[ "$lang" == "php" ]]; then
        desc="$(sed -n '2,10p' "$file" \
            | grep -oE '(^[[:space:]]*(//|#)[[:space:]]*.+|^[[:space:]]*\*[[:space:]]+[A-Za-z].+)' \
            | head -1 \
            | sed -E 's@^[[:space:]]*(//|#|\*)[[:space:]]*@@' || true)"
    else
        line2="$(sed -n '2p' "$file")"
        [[ "$line2" == "#"* && "$line2" != "#!"* ]] \
            && desc="$(echo "$line2" | sed -E 's/^#\s?//')"
    fi

    # last commit date (author date, YYYY-MM-DD) for the file
    date="$(git log -1 --format=%cs -- "$rel" 2>/dev/null || true)"

    jq -nc \
        --arg path "$rel" \
        --arg folder "$folder" \
        --arg lang "$lang" \
        --arg desc "$desc" \
        --arg date "$date" \
        '{path: $path, folder: $folder, lang: $lang, description: $desc, last_commit: $date}' >>"$entries"
done < <(find bin -type f | sort)

jq -s 'sort_by(.folder, .path)' "$entries" >"$OUT"

echo "scripts: $(jq 'length' "$OUT") scripts -> $OUT"

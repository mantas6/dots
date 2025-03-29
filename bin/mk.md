#!/usr/bin/env sh

# Create and edit a new Markdown file

filename="$1"
ext="${filename##*.}"

[ "$ext" != 'md' ] && filename="$filename.md"

[ -f "$filename" ] && exit 1

printf '# %s' "$(echo "$filename" | sed 's/\.md//')" >> "$filename"

nvim "$filename"

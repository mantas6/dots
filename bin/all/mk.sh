#!/usr/bin/env sh

[ -f "$1" ] && exit 1

cp "$DOTS_DIR/etc/stubs/new.sh" "$1"

[ "$2" = '-e' ] && nvim "$1"

exit 0

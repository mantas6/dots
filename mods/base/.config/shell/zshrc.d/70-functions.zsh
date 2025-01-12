#!/usr/bin/env zsh

lfcd() {
    cd "$(command lf -print-last-dir "$@")" || return
}

zt() {
    out=$(command zt "$@") && eval "$out"
}

li() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"

	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd" || return
	fi

	command rm -f -- "$tmp"
}

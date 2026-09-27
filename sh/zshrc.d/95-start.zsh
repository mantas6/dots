#!/usr/bin/env zsh

if [ -x "$(command -v startx)" ] && [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec startx "$XINITRC"
fi

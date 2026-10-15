#!/usr/bin/env zsh

if [[ -o login ]] && [ -z "$TMUX" ] && [ -z "$DISPLAY" ] \
    && [ "$(tty)" = /dev/tty1 ] && [ -x "$(command -v startx)" ]; then
    exec startx "$XINITRC"
fi

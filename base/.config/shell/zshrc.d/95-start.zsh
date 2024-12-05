#!/usr/bin/env zsh

if [ -x "$(command -v startx)" ] && [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    echo "Start time: $(date)" >> "$XDG_CACHE_HOME/Xoutput"
    exec startx "$XINITRC" &>> "$XDG_CACHE_HOME/Xoutput"
else
    if [ "$(uname -n)" = 'l4' ] && [ "$XDG_VTNR" -eq 1 ]; then
        dashb -f
    fi
fi

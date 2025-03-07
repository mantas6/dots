#!/usr/bin/env zsh

[ "$(uname)" = 'Darwin' ] && return

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 24h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi

if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

#!/usr/bin/env zsh

# Add to .ssh/config for MacOS:
#
# IgnoreUnknown UseKeychain
#
# Host *
#     AddKeysToAgent yes
#     UseKeychain yes

if [[ "$(uname)" = 'Darwin' ]]; then
    [[ ! -S "$SSH_AUTH_SOCK" ]] && export SSH_AUTH_SOCK="$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null)"
    ssh-add --apple-load-keychain >/dev/null 2>&1
    return
fi

if ! pgrep -u "$USER" ssh-agent >/dev/null; then
    ssh-agent -t 24h >"$XDG_RUNTIME_DIR/ssh-agent.env"
fi

[[ ! -S "$SSH_AUTH_SOCK" ]] && source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null

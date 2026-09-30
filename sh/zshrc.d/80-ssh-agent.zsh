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

# Linux: nothing to do here, ssh-agent is started by NixOS
# (programs.ssh.startAgent in nix/features/progs/shell.nix)

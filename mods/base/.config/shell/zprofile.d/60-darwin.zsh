#!/usr/bin/env zsh

[ "$(uname)" != "Darwin" ] && return

# Homebrew rootless
if [ -d "$HOME/.local/brew" ]; then
    export HOMEBREW_PREFIX="$HOME/.local/brew"
    export HOMEBREW_MAKE_JOBS=4
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"

    eval "$(brew shellenv)"
fi

[ -d "$HOME/Library/Application Support/Herd/bin" ] && \
    export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"

[ -d "$HOME/Applications/Docker.app/Contents/Resources/bin" ] && \
    export PATH="$HOME/Applications/Docker.app/Contents/Resources/bin:$PATH"

export DOCKER_CLI_HINTS=false

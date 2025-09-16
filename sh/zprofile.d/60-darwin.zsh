#!/usr/bin/env zsh

[ "$(uname)" != "Darwin" ] && return

# Homebrew rootless
if [ -d "$HOME/.local/brew" ]; then
    export HOMEBREW_PREFIX="$HOME/.local/brew"
    export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
    export HOMEBREW_MAKE_JOBS=4
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"

    eval "$(brew shellenv)"
fi

[ -d "$HOME/.config/herd-lite/bin" ] && \
    export PATH="$HOME/.config/herd-lite/bin:$PATH"

[ -d "$HOME/.docker/bin" ] && \
    export PATH="$HOME/.docker/bin:$PATH"

[ -d "$HOME/Applications/Docker.app/Contents/Resources/bin" ] && \
    export PATH="$HOME/Applications/Docker.app/Contents/Resources/bin:$PATH"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export DOCKER_CLI_HINTS=false

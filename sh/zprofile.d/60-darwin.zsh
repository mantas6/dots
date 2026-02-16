#!/usr/bin/env zsh

[ "$(uname)" != "Darwin" ] && return

# Homebrew rootless
if [ -d "$HOME/.local/brew" ]; then
    export HOMEBREW_PREFIX="$HOME/.local/brew"

    export HOMEBREW_PREFIX=~/.local/brew
    export HOMEBREW_CASK_OPTS=--appdir=~/Applications
    export HOMEBREW_MAKE_JOBS=4

    export HOMEBREW_BUNDLE_FILE_GLOBAL=~/.config/homebrew/Brewfile
    export HOMEBREW_BUNDLE_NO_UPGRADE=true

    # export HOMEBREW_NO_AUTO_UPDATE=true
    export HOMEBREW_DOWNLOAD_CONCURRENCY=5

    export HOMEBREW_DISPLAY_INSTALL_TIMES=true
    export HOMEBREW_NO_ANALYTICS=true
    export HOMEBREW_NO_ENV_HINTS=true

    export PATH="$HOMEBREW_PREFIX/bin:$PATH"
    eval "$(brew shellenv)"
fi

[ -d "$HOME/.config/herd-lite/bin" ] && \
    export PATH="$HOME/.config/herd-lite/bin:$PATH"

[ -d "$HOME/.docker/bin" ] && \
    export PATH="$HOME/.docker/bin:$PATH"

[ -d "$HOME/Applications/Docker.app/Contents/Resources/bin" ] && \
    export PATH="$HOME/Applications/Docker.app/Contents/Resources/bin:$PATH"

export NVM_DIR="$HOME/.local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export DOCKER_CLI_HINTS=false

export LIMA_HOME="$HOME/.local/share/lima"

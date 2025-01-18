#!/usr/bin/env zsh

# Homebrew rootless
if [ -d "$HOME/.local/brew" ]; then
    export HOMEBREW_PREFIX="$HOME/.local/brew"
    export HOMEBREW_MAKE_JOBS=2
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"

    eval "$(brew shellenv)"
fi

[ -d "$HOME/Library/Application Support/Herd/bin" ] && \
    export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"

[ -d "$HOME/Applications/Docker.app/Contents/Resources/bin" ] && \
    export PATH="$HOME/Applications/Docker.app/Contents/Resources/bin:$PATH"

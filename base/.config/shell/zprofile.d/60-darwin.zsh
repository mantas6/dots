#!/usr/bin/env zsh

# Homebrew rootless
if [ -d "$HOME/.local/brew" ]; then
    export HOMEBREW_PREFIX="$HOME/.local/brew"
    export HOMEBREW_MAKE_JOBS=2
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"

    [ -r "${HOMEBREW_PREFIX}/etc/profile.d/zsh_completion.sh" ] \
        && source "${HOMEBREW_PREFIX}/etc/profile.d/zsh_completion.sh"
fi

[ -d "$HOME/Library/Application Support/Herd/bin" ] && \
    export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"

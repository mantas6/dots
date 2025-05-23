#!/usr/bin/env zsh

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

[ "$(uname)" = "Darwin" ] && export XDG_RUNTIME_DIR="$HOME/Library/Caches/TemporaryItems"

#!/usr/bin/env zsh

# Editor
if [ -x "$(command -v nvim)" ]; then
    export MANPAGER="nvim +Man! -c 'set nospell'"
    export EDITOR="nvim"
    export VISUAL="nvim"
    export DIFFPROG="nvim -d"
else
    export EDITOR=vim
    export VISUAL=vim
fi

export INPUTRC="$XDG_CONFIG_HOME/shell/inputrc"

export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
export AWESOME_OUTPUT_DIR="$XDG_CACHE_HOME/awesome"

# Homebrew rootless
if [ -d "$HOME/.local/brew" ]; then
    export HOMEBREW_PREFIX="$HOME/.local/brew"
    export HOMEBREW_MAKE_JOBS=2
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"

    [ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ] \
        && source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
fi

if [ -x "$(command -v gem)" ]; then
    export GEM_HOME=$(gem env user_gemhome)
    export PATH="$PATH:$GEM_HOME/bin"
fi

# Other
if [ "$(uname)" != "Darwin" ]; then
    export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
    export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
fi

export GOPATH="$XDG_DATA_HOME"/go
export GOMODCACHE="$XDG_CACHE_HOME"/go/mod

export ATAC_MAIN_DIR="$XDG_CONFIG_HOME/atac"
export ATAC_KEY_BINDINGS="$XDG_CONFIG_HOME/atac/key.toml"

export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
export PASSWORD_STORE_CHARACTER_SET="[:alnum:]"

export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export VIT_DIR="$XDG_CONFIG_HOME/vit"

export NBRC_PATH="$HOME/.config/nb/nbrc"
export NB_DIR="$XDG_DATA_HOME/nb"
export NB_HIST="$XDG_STATE_HOME/nb/history"

export OLLAMA_HOST='amd:11434'

export MOZ_USE_XINPUT2=1
export QT_QPA_PLATFORMTHEME=qt6ct

[ -f "$XDG_CONFIG_HOME/shell/local/profile" ] && . "$XDG_CONFIG_HOME/shell/local/profile"

export PATH="$PATH:$(find "$HOME"/.local/share/scripts/ -type d | paste -sd ':' -)"

[ -x "$(command -v npm)" ] && PATH="$(npm config get prefix)/bin:$PATH"

[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

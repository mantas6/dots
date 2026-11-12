#!/usr/bin/env zsh

export DOTS_EMAIL='6524518+mantas6@users.noreply.github.com'

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

# Other
if [[ $OSTYPE != darwin* ]]; then
    export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
    export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

    if [ -x "$(command -v gem)" ]; then
        export GEM_HOME=$(gem env user_gemhome)
        export PATH="$PATH:$GEM_HOME/bin"
    fi
fi

export GOPATH="$XDG_DATA_HOME"/go
export GOMODCACHE="$XDG_CACHE_HOME"/go/mod
export CARGO_HOME="$XDG_DATA_HOME"/cargo

export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
export PASSWORD_STORE_CHARACTER_SET="[:alnum:]"

export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

export WGETRC="$XDG_CONFIG_HOME/wgetrc"

export MOZ_USE_XINPUT2=1
export QT_QPA_PLATFORMTHEME=qt6ct

export ANTHROPIC_ENABLE_1M_CONTEXT=true

[ -f "$XDG_CONFIG_HOME/shell/local/profile" ] && . "$XDG_CONFIG_HOME/shell/local/profile"

export PATH="$PATH:$DOTS_DIR/bin"

[ -d "$XDG_DATA_HOME/npm/bin" ] && export PATH="$XDG_DATA_HOME/npm/bin:$PATH"

[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/Repos/private/bin" ] && export PATH="$HOME/Repos/private/bin:$PATH"

export COMPOSER_HOME="$HOME/.config/composer"
[ -d "$HOME/.config/composer/vendor/bin" ] && export PATH="$COMPOSER_HOME/vendor/bin:$PATH"
export CPX_HOME="$XDG_STATE_HOME/cpx"
export T3CODE_HOME="$XDG_DATA_HOME/t3"

[ -d "$HOME/.local/share/cargo/bin" ] && export PATH="$HOME/.local/share/cargo/bin:$PATH"
[ -d "$GOPATH/bin" ] && export PATH="$GOPATH/bin:$PATH"

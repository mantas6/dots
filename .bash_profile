#
# ~/.bash_profile
#

# Editor
export MANPAGER="nvim +Man! -c 'set nospell'"
export EDITOR="nvim"
export VISUAL="nvim"
export DIFFPROG="nvim"

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Other
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker

export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
export PASSWORD_STORE_CHARACTER_SET="[:alnum:]"

export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

export MOZ_USE_XINPUT2=1

[ -f "$HOME/.profile.local" ] && source "$HOME/.profile.local"

[ -d "$HOME/.local/share/scripts" ] && export PATH="$HOME/.local/share/scripts:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec startx
fi


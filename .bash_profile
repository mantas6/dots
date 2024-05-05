#
# ~/.bash_profile
#

# Editor
export MANPAGER="nvim +Man!"
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

export MOZ_USE_XINPUT2=1

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec startx
fi


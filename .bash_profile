#
# ~/.bash_profile
#

export MANPAGER="nvim +Man!"
export EDITOR="nvim"
export VISUAL="nvim"

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec startx
fi


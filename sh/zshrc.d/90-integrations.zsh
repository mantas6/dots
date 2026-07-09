#!/usr/bin/env zsh

[ -x "$(command -v fzf)" ] && eval "$(fzf --zsh)"

[ -x "$(command -v direnv)" ] && eval "$(direnv hook zsh)"
[ -x "$(command -v tg)" ] && eval "$(tg completion zsh)"

[ -f "$XDG_STATE_HOME/.inhibit-suspend" ] && gum log --level info 'Suspend is inhibited'

dchk

#!/usr/bin/env zsh

[ -x "$(command -v starship)" ] && eval "$(starship init zsh)"
[ -x "$(command -v fzf)" ] && eval "$(fzf --zsh)"

unalias zi
[ -x "$(command -v zoxide)" ] && eval "$(zoxide init zsh)"

[ -x "$(command -v direnv)" ] && eval "$(direnv hook zsh)"

[ -f "$XDG_STATE_HOME/.inhibit-suspend" ] && gum log --level info 'Suspend is inhibited'

dchk

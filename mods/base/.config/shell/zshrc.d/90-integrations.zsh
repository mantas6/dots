#!/usr/bin/env zsh

if [ -x "$(command -v starship)" ]; then
    eval "$(starship init zsh)"

    set-long-prompt() { PROMPT=$(starship prompt) }
    precmd_functions=(set-long-prompt)

    set-short-prompt() {
      if [[ $PROMPT != '%# ' ]]; then
        PROMPT="$(starship prompt --profile transient)"
        zle .reset-prompt 2>/dev/null # hide the errors on ctrl+c
      fi
    }

    zle-line-finish() { set-short-prompt }
    zle -N zle-line-finish

    trap 'set-short-prompt; return 130' INT
fi

[ -x "$(command -v fzf)" ] && eval "$(fzf --zsh)"

unalias zi
[ -x "$(command -v zoxide)" ] && eval "$(zoxide init zsh)"

[ -x "$(command -v direnv)" ] && eval "$(direnv hook zsh)"

[ -f "$XDG_STATE_HOME/.inhibit-suspend" ] && gum log --level info 'Suspend is inhibited'

dchk

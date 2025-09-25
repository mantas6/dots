#!/usr/bin/env zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

typeset -U PATH

# History
HISTSIZE=50000
HISTFILE=~/.local/state/zsh/history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
# setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

setopt autocd

# Load completions
autoload -Uz compinit && compinit

[ -n "$ZINIT_HOME" ] && zinit cdreplay -q

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

precmd() {
    # print -n '\033]133;A\033\\'

    if [[ $? -ne 0 ]]; then
        print -n '\a'
    fi
}

#!/usr/bin/env zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

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

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
setopt interactive_comments

# Load completions
autoload -Uz compinit && compinit

[ -n "$ZINIT_HOME" ] && zinit cdreplay -q

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

autoload -Uz add-zsh-hook

# Ring the bell on command error (uses status captured by the prompt precmd)
_bell_on_error() {
    ((_prompt_status)) && print -n '\a'
}
add-zsh-hook precmd _bell_on_error

copy-line-to-clipboard() {
    printf '%s' "$BUFFER" | xc
}

zle -N copy-line-to-clipboard
bindkey '^Xy' copy-line-to-clipboard

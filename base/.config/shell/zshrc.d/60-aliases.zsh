#!/usr/bin/env zsh

[ -x "$(command -v nvim)" ] && alias vim="nvim" vi="nvim"

alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'

alias chx="chmod +x"
alias cp="cp -vi"
alias mkdir="mkdir -v"
alias mv="mv -vi"
alias rm="rm -vi"
alias trash="trash -v"
alias lf="lfcd"
alias t='trash'
alias rsync='rsync -avP'

if [ -x "$(command -v eza)" ]; then
    export EZA_COLORS="uu=0:gu=0"
    alias eza="eza --icons --group-directories-first"
    alias ls="eza"
    alias l="eza"
    alias ll="eza -l"
    alias la="eza -la"
    alias lt="eza -T -L 2"
    alias lt3="eza -T -L 3"
fi

alias zd='cd ~/Downloads'
alias ze='cd ~/Desktop'
alias zr='cd "$(git rev-parse --show-toplevel)"'
alias zk='z "$(tmux display-message -p "#S")"'
alias zf='eval "$(__fzf_cd__)"'

alias cmatrix='cmatrix -ab'
alias ff='fastfetch'
alias q='numbat'

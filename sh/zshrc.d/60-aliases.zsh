#!/usr/bin/env zsh

# Colors
alias ls='ls --color=auto -h'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'

# Use neovim if available
[ -x "$(command -v nvim)" ] && alias vim="nvim" vi="nvim"

alias cp="cp -vi"
alias mkdir="mkdir -v"
alias mv="mv -vi"
alias rm="rm -vi"
alias trash="trash -v"
alias lf="lfcd"
alias t='trash'
alias rsync='rsync -avP'
alias chx="chmod +x"

if [ -x "$(command -v eza)" ]; then
    export EZA_COLORS="uu=0:gu=0"
    alias eza="eza --icons --group-directories-first"
    alias ls="eza"
    alias l="eza"
    alias ll="eza --no-user -l"
    alias la="eza --no-user -la"
    alias lu="eza -la"
    alias lt="eza -T -L 2"
    alias lt3="eza -T -L 3"
fi

alias zd='cd ~/Downloads'
alias zs='cd ~/Desktop'
alias zr='cd "$(git rev-parse --show-toplevel)"'
alias ze='z "$(tmux display-message -p "#S")"'
alias zf='eval "$(__fzf_cd__)"'

alias sail="vendor/bin/sail"
alias artisan="a"
alias composer="c"
alias s="sail"

alias glc="git log -1 --pretty=%B"

alias osw="nh os switch"
alias osb="nh os boot"
alias osc="nix flake check $DOTS_DIR --all-systems"

alias lg='lazygit'
alias cmatrix='cmatrix -ab'
alias ff='fastfetch'
alias q='vi -c Quickmath'

alias ts='tmux split-window -h \; split-window -v'

[ "$(uname)" != 'Darwin' ] && alias cal='cal --monday'
[ "$(uname)" = 'Darwin' ] && alias cal='cal -A 2'

alias keepon="xset s off && xset -dpms"

alias ql="bm -f $XDG_STATE_HOME/bm_ql"
alias qla="bm -lf $XDG_STATE_HOME/bm_ql | xargs open-url"

# Networking
alias pingg="ping google.com"

alias sshvm='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -A'

# Other
alias nj="jq . | nvim -Rc 'set syntax=json | set nospell' -"

alias tra="sat transactions:select"

d="$HOME/Downloads"

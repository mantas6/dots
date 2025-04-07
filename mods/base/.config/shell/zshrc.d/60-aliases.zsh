#!/usr/bin/env zsh

# Colors
alias ls='ls --color=auto -h'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'
alias tree="tree -C"

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
alias artisan="de php artisan"
alias composer="c"
alias s="sail"

alias esl='npx eslint --fix'
alias cl='a ctl'
alias fa='a ctl fa'
alias pc='precommit'
alias dup='docker compose up'
alias dst='docker compose stop'

alias g="git"
alias gp="g pull"
alias gP="g push"
alias lg="lazygit"
alias ld="lazydocker"
alias glc="git log -1 --pretty=%B"

alias osw="nh os switch"
alias osc="nix flake check $DOTS_DIR"

alias cmatrix='cmatrix -ab'
alias ff='fastfetch'
alias q='numbat'

alias tsr='tmux source-file ~/.config/tmux/tmux.conf'
alias ts='tmux split-window -h \; split-window -v'

alias dlg="(cd $DOTS_DIR && lazygit)"

[ "$(uname)" != 'Darwin' ] && alias cal='cal --monday'
[ "$(uname)" = 'Darwin' ] && alias cal='cal -A 2'

alias keepon="xset s off && xset -dpms"

alias vse="vf -d $DOTS_DIR/bin"
alias vaw="vf -d $HOME/.config/awesome"
alias vsh="vf -d $HOME/.config/shell"
alias vrc="vf -d $DOTS_DIR"
alias vne="vf -d $HOME/.config/nvim"
alias vnx="vf -d $DOTS_DIR/nix"
alias vkb="vi $DOTS_DIR/lib/kbd/config/adv360.keymap"

# Networking
alias pingg="ping google.com"
alias ipa="ip a"

alias sshvm='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -A'

# Other
alias nj="jq . | nvim -Rc 'set syntax=json | set nospell' -"

alias tra="sat transactions:select"

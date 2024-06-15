# 
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export HISTCONTROL=ignoreboth
export HISTSIZE=1000
export HISTFILESIZE=10000
export HISTFILE="$XDG_STATE_HOME"/bash/history

shopt -s checkwinsize
shopt -s histappend
shopt -s autocd

PROMPT_COMMAND='history -a'

# Colors
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'

# Use neovim if available
[ -x "$(command -v nvim)" ] && alias vim="nvim" vi="nvim"

# Found myself making this typo, so I suppose it's more natural
alias chmox="chmod +x"

# Higher verbosity for file operations
alias cp="cp -vi"
alias mkdir="mkdir -v"
alias mv="mv -vi"
alias rm="rm -v"
alias trash="trash -v"
alias tree="tree -C"

# Laravel
alias sail="vendor/bin/sail"
alias artisan="sail artisan"
alias c="sail composer"
alias s="sail"
alias a="artisan"
alias deploy="vendor/bin/envoy run deploy"

alias lg="lazygit"

alias ll='ls -alh'
alias pac='sudo pacman'
alias cu='checkupdates'
alias cmatrix='cmatrix -ab'

# Dotfiles
alias dot="git --git-dir=$HOME/Repositories/dotfiles --work-tree=$HOME"
alias dotu="lazygit -g $HOME/Repositories/dotfiles -w $HOME"
source /usr/share/bash-completion/completions/git
__git_complete dot __git_main

alias cal='cal --monday'
alias keepon="xset s off && xset -dpms"
alias vf='selected_file=$(fzf --preview "bat --color=always {}" --preview-window "~3"); [ -n "$selected_file" ] && vi "$selected_file"'

# Networking
alias pingg="ping google.com"
alias ipa="ip a"

# AP
alias ap-hostapd-edit="sudoedit /etc/hostapd/hostapd.conf"
alias ap-hostapd-restart="sudo systemctl restart hostapd"
alias ap-hostapd-logs="sudo journalctl -u hostapd"
alias ap-accept-edit="sudoedit /etc/hostapd/hostapd.accept"

alias ap-dnsmasq-edit="sudoedit /etc/dnsmasq.conf"
alias ap-dnsmasq-check="sudo dnsmasq --test"
alias ap-dnsmasq-restart="sudo systemctl restart dnsmasq"
alias ap-dnsmasq-logs="sudo journalctl -u dnsmasq"

alias ap-etc-hosts-edit="sudoedit /etc/hosts"

alias ap-leases-list="sudo cat /var/lib/dnsmasq/dnsmasq.leases"
alias ap-leases-clear="sudo rm /var/lib/dnsmasq/dnsmasq.leases"

# Other
alias nj="jq . | nvim -Rc 'set syntax=json | set nospell'"
alias wt="$HOME/Repositories/meteo/meteo"

# Functions
# Get time when system was woken from sleep
wok() {
    journalctl -n1 -u sleep.target | awk '{print $3}'
}

dt() {
    if [ $# -eq 0 ]; then
        du -hs .
    else
        du -hs "$@"
    fi
}

n() {
    if [ $# -eq 0 ]; then
        vi .
    else
        vi "$@"
    fi
}

[ -x "$(command -v zoxide)" ] && eval "$(zoxide init bash)"
[ -x "$(command -v fzf)" ] && eval "$(fzf --bash)"
[ -x "$(command -v starship)" ] && eval "$(starship init bash)"

# SSH agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi

if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

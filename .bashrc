#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'

export MANPAGER="less -R --use-color -Dd+r -Du+b"
export MANROFFOPT="-P -c"

alias ll='ls -alh'
alias cmatrix='cmatrix -ab'
alias dotf="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
RESET="$(tput sgr0)"

bat_lvl()
{
   cat /sys/class/power_supply/BAT0/capacity 
}

PS1='[\t $(bat_lvl)% ${GREEN}\W${RESET} $?]\$ '
#/sys/class/power_supply/BAT0/capacity

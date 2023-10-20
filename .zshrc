
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle :compinstall filename '/home/mantas/.zshrc'

autoload -Uz compinit && compinit
#autoload -Uz promptinit && promptinit

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

setopt autocd
bindkey -e

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'

export MANPAGER="less -R --use-color -Dd+r -Du+b"
export MANROFFOPT="-P -c"

alias ll='ls -alh'
alias cmatrix='cmatrix -ab'
alias dotf="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

bat_lvl() {
   cat /sys/class/power_supply/BAT0/capacity
}

setopt prompt_subst
PROMPT='%F{#c0c0c0}%n%f@%F{#008000}%m%f %F{#800080}%B%~%b%f %# '
RPROMPT='[ BAT $(bat_lvl)% ] [%F{#0000ff}%?%f]'
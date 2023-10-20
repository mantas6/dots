
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

bat-lvl() {
    cat /sys/class/power_supply/BAT0/capacity
}

bat-volt() {
    VOLTAGE=$(cat /sys/class/power_supply/BAT0/voltage_now)
    print $(echo "scale=2; $VOLTAGE / 1000000 / 3" | bc)
}

zsh-working-dir() {
    if [ "$(pwd)" == "$HOME" ]; then
        "~"
    else
        basename $(pwd)
    fi
}

setopt prompt_subst
PROMPT='%F{#c0c0c0}%n%f %F{#800080}%B$(zsh-working-dir)%b%f %# '
RPROMPT='[$(bat-volt)V] [$(bat-lvl)%#] [%F{#0000ff}%?%f]'
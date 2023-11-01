
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle :compinstall filename '/home/mantas/.zshrc'

autoload -Uz compinit && compinit
#autoload -Uz promptinit && promptinit

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

setopt autocd
bindkey -e
bindkey  "^[[3~"  delete-char

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'

export MANPAGER="less -R --use-color -Dd+r -Du+b"
export MANROFFOPT="-P -c"

alias ll='ls -alh'
alias pac='sudo pacman'
alias cmatrix='cmatrix -ab'
alias dotf="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
alias dotfui="gitui -d $HOME/.dotfiles -w $HOME"
alias dotfl='dotf pull'
alias cal='cal --monday'

dotfa() {
    dotf diff $2
    dotf add $2
}

dotfp() {
    dotf commit -m "$1"
    dotf push
}

bat-lvl() {
    cat /sys/class/power_supply/BAT0/capacity
}

bat-volt() {
    local VOLTAGE=$(cat /sys/class/power_supply/BAT0/voltage_now)
    print $(echo "scale=2; $VOLTAGE / 1000000 / 3" | bc)
}

bat-status() {
    local STATUS=$(cat /sys/class/power_supply/BAT0/status)
    #if ["$STATUS" = "Charging"]; then
    #    print "|AC"
    #fi
}

zsh-working-dir() {
    if [ "$(pwd)" = "$HOME" ]; then
        print "~"
    else
        print $(basename $(pwd))
    fi
}

setopt prompt_subst
PROMPT='%F{#c0c0c0}%n%f %F{#800080}%B$(zsh-working-dir)%b%f %# '
RPROMPT='[$(bat-lvl)%#%F{100}|%f$(bat-volt)V$(bat-status)] [%F{%(?.green.red)}%?%f]'

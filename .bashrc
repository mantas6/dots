# 
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

shopt -s checkwinsize
shopt -s histappend
shopt -s autocd

primary=$(tput setaf 2)
secondary=$(tput setaf 8)
reset=$(tput sgr0)

battery=/sys/class/power_supply/BAT0

bat-lvl() {
 local energy=$(cat "$battery/energy_now")
 local energy_full=$(cat "$battery/energy_full")
 
 printf $(echo "scale=1; $energy / $energy_full * 100" | bc)
}

PS1="[$(bat-lvl)%] ${secondary}\h ${primary}\W${reset} % "

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
battery_aux=/sys/class/power_supply/BAT1

bat-lvl() {
 local capacity=$(cat "$battery/capacity")

 if [ -d "$battery_aux" ]; then
  local capacity_aux=$(cat "$battery_aux/capacity")
  local total=$(echo "scale=1; ($capacity + $capacity_aux) / 2" | bc)
 else
  local total="$capacity"
 fi

 echo -n "[$total%] "
}

PS1="$(bat-lvl)${secondary}\h ${primary}\W${reset} % "

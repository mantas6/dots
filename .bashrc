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
intermediate=$(tput setaf 3)
secondary=$(tput setaf 8)
reset=$(tput sgr0)
#left=$(tput rc)
#right=$(tput sc)

battery_dir=/sys/class/power_supply
cell_count=3

bat-lvl() {
 local battery=$battery_dir/$1

 if [ ! -d "$battery" ]; then
  return
 fi

 local capacity=$(cat "$battery/capacity")
 local voltage_now=$(cat "$battery/voltage_now")
 local voltage=$(echo "scale=2; $voltage_now / 1000000 / $cell_count" | bc)

 echo -n "[$capacity%${secondary}|${reset}${voltage}V] "
}

status-prompt() {
 if [ "$1" -eq "0" ]; then
  local color="${primary}"
 else
  local color="${intermediate}"
 fi
 
 echo -n "[${color}$1${reset}] " 
}

time-prompt() {
 date +%H:%M
}

PS1='
${reset}\
$(status-prompt $?)$(time-prompt) $(bat-lvl BAT0)$(bat-lvl BAT1)
${secondary}\h ${primary}\W${reset} % '


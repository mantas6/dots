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
left=$(tput rc)
right=$(tput sc)

battery=/sys/class/power_supply/BAT0
battery_aux=/sys/class/power_supply/BAT1
cell_count=3

bat-lvl() {
 local capacity=$(cat "$battery/capacity")
 local voltage_now=$(cat "$battery/voltage_now")
 local voltage=$(echo "scale=2; $voltage_now / 1000000 / $cell_count" | bc)

 #if [ -d "$battery_aux" ]; then
 # local capacity_aux=$(cat "$battery_aux/capacity")
 # local total=$(echo "scale=1; ($capacity + $capacity_aux) / 2" | bc)
 #else
 # local total="$capacity"
 #fi

 echo -n "[$capacity%|${voltage}V]"
}

rightprompt()
{
	printf "%*s" $COLUMNS '$(bat-lvl)'
}

PS1="\[$(tput sc; rightprompt; tput rc)\]${secondary}\h ${primary}\W${reset} % "

unset rightprompt

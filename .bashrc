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

PS1="${secondary}\h ${primary}\W${reset} % "

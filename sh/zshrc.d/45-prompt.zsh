#!/usr/bin/env zsh
# Pure-zsh prompt (replaces starship)

zmodload zsh/datetime
autoload -Uz add-zsh-hook
setopt prompt_subst

# hostname: bold red, only over SSH (computed once)
_prompt_host=""
[[ -n $SSH_CONNECTION || -n $SSH_TTY ]] && _prompt_host="%B%F{red}%m%f%b "

# character: green on success, red on error (updated each precmd)
_prompt_char="%F{green}❯%f"

# directory: repo-relative when in a git repo, else %3~ (recompute on cd)
_prompt_chpwd() {
    local dir=$PWD root=""
    while true; do
        [[ -e $dir/.git ]] && {
            root=$dir
            break
        }
        [[ $dir == / ]] && break
        dir=${dir:h}
    done
    if [[ -n $root ]]; then
        _prompt_dir="${root:t}${PWD#$root}"
        _prompt_dir=${_prompt_dir//\%/%%}
    else
        _prompt_dir=""
    fi
}
add-zsh-hook chpwd _prompt_chpwd
_prompt_chpwd

# cmd_duration: timer via zsh/datetime, shown when >= 2s
_prompt_preexec() { _prompt_timer=$EPOCHREALTIME; }
add-zsh-hook preexec _prompt_preexec

_prompt_precmd() {
    _prompt_status=$?
    if ((_prompt_status)); then
        _prompt_char="%F{red}❯%f"
    else
        _prompt_char="%F{green}❯%f"
    fi
    _prompt_dur=""
    if [[ -n $_prompt_timer ]]; then
        local elapsed=$((EPOCHREALTIME - _prompt_timer))
        unset _prompt_timer
        if ((elapsed >= 2)); then
            local -i secs=$elapsed
            local out="" h=$((secs / 3600)) m=$(((secs % 3600) / 60)) s=$((secs % 60))
            ((h)) && out+="${h}h"
            ((m)) && out+="${m}m"
            out+="${s}s"
            _prompt_dur="%F{yellow}${out}%f "
        fi
    fi
}
add-zsh-hook precmd _prompt_precmd

PROMPT=$'\n''${_prompt_host}%F{blue}${_prompt_dir:-%3~}%f ${_prompt_dur}
${_prompt_char} '

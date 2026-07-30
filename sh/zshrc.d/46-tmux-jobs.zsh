#!/usr/bin/env zsh
# Record command state per tmux pane so tmux-bg can report background jobs

[[ -n $TMUX_PANE ]] || return

zmodload zsh/datetime
autoload -Uz add-zsh-hook

_tmux_jobs_dir="$HOME/.local/state/tmux-jobs"
_tmux_jobs_file="$_tmux_jobs_dir/$TMUX_PANE"

[[ -d $_tmux_jobs_dir ]] || mkdir -p $_tmux_jobs_dir

# kind US timestamp US exit US duration US command
# US instead of tab so that empty fields survive being read back by tmux-bg.
# Written with a builtin redirect only, no forks and no tmux calls.
_tmux_jobs_sep=$'\x1f'

_tmux_jobs_preexec() {
    _tmux_jobs_start=$EPOCHSECONDS
    _tmux_jobs_cmd=${1//$'\x1f'/ }
    print -r -- "R$_tmux_jobs_sep$EPOCHSECONDS$_tmux_jobs_sep$_tmux_jobs_sep$_tmux_jobs_sep$_tmux_jobs_cmd" >$_tmux_jobs_file
}
add-zsh-hook preexec _tmux_jobs_preexec

# Runs after _prompt_precmd (45-prompt.zsh), which owns $_prompt_status.
# $? is unreliable here because the earlier hook has already clobbered it.
_tmux_jobs_precmd() {
    [[ -n $_tmux_jobs_cmd ]] || return
    local dur=$((EPOCHSECONDS - _tmux_jobs_start))
    print -r -- "D$_tmux_jobs_sep$EPOCHSECONDS$_tmux_jobs_sep${_prompt_status:-0}$_tmux_jobs_sep$dur$_tmux_jobs_sep$_tmux_jobs_cmd" >$_tmux_jobs_file
    unset _tmux_jobs_cmd
}
add-zsh-hook precmd _tmux_jobs_precmd

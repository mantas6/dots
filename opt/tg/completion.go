package main

import (
	"errors"
	"fmt"
	"io"
)

// cmdCompletion writes the shell completion script for the requested shell.
// Only zsh is supported; anything else is a usage error.
func cmdCompletion(w io.Writer, shell string) error {
	if shell != "zsh" {
		return errors.New("usage: tg completion zsh")
	}
	fmt.Fprint(w, zshCompletion)
	return nil
}

// zshCompletion is the zsh completion script emitted by `tg completion zsh`.
// It is written to work both ways: dropped on $fpath as a #compdef file, or
// eval'd/sourced after compinit (the trailing guard calls compdef itself).
// `tg start` completion pulls task names from `tg tasks --json`, which reads
// the local SQLite cache and honours TOGGL_PROJECT_ID scoping.
const zshCompletion = `#compdef tg

# Complete task names for ` + "`tg start`" + ` from the local catalog cache.
__tg_tasks() {
  local json name
  local MATCH MBEGIN MEND
  local -a match mbegin mend names
  json="$(tg tasks --json 2>/dev/null)" || return 1
  while [[ $json =~ '"name":"((\\.|[^"\\])*)"' ]]; do
    name=$match[1]
    json=${json[MEND+1,-1]}
    name=${name//'\"'/'"'}
    name=${name//'\\'/'\'}
    names+=("$name")
  done
  (( $#names )) || return 1
  local expl
  _wanted tasks expl 'task' compadd -a names
}

_tg() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '1:command:->cmds' \
    '*::arg:->args'

  case $state in
    cmds)
      local -a commands
      commands=(
        'auth:verify a Toggl API token and store config'
        'start:start tracking the task matching a fragment'
        'stop:stop the running entry (snaps to 5m)'
        'current:show the running entry'
        'status:show the running entry'
        "today:show today's entries"
        "list:show today's entries"
        "ls:show today's entries"
        'tasks:list cached tasks'
        'projects:list cached projects with ids'
        "update:refresh one project's tasks"
        'update-projects:sync all workspace projects'
        'push:send local changes to Toggl'
        "pull:fetch remote changes (all projects, or one)"
        'completion:print a shell completion script'
        'help:show usage'
      )
      _describe -t commands 'tg command' commands
      ;;
    args)
      case $words[1] in
        start)
          __tg_tasks
          ;;
        current|status|push)
          _arguments '--json[emit JSON]'
          ;;
        today|list|ls)
          _arguments '--json[emit JSON]' '--days[number of days to look back]:days:'
          ;;
        tasks)
          _arguments '--all[include inactive tasks]' '--json[emit JSON]'
          ;;
        projects)
          _arguments '--all[include inactive projects]' '--json[emit JSON]'
          ;;
        update)
          _arguments '--all[include inactive tasks]' '--json[emit JSON]' '*:project fragment:'
          ;;
        update-projects)
          _arguments '--all[include inactive projects]' '--json[emit JSON]'
          ;;
        pull)
          _arguments '--since[pull entries modified since DATE]:date (YYYY-MM-DD):' '--json[emit JSON]' '*:project fragment:'
          ;;
        completion)
          local -a shells
          shells=('zsh:zsh completion script')
          _describe -t shells 'shell' shells
          ;;
      esac
      ;;
  esac
}

# Register directly when eval'd/sourced after compinit; as a #compdef fpath
# file zsh calls us with the completion words instead.
if [ "$funcstack[1]" = "_tg" ]; then
  _tg "$@"
else
  compdef _tg tg
fi
`

package session

import (
	"mantas6/sessionizer/config"
	"mantas6/sessionizer/helpers"
	"mantas6/sessionizer/tmuxsession"
	"path/filepath"
)

type Session struct {
	Name         string
	Path         string
	Cmd          string
	LastAttached int
	Active       bool
}

func (s *Session) SetActive(lastAttached int) {
	s.Active = true
	s.LastAttached = lastAttached
}

func (s *Session) MatchesTmuxSession(tmuxSession tmuxsession.TmuxSession) bool {
	return s.Name == tmuxSession.Name
}

func CreateFromTmuxSession(tmuxSession tmuxsession.TmuxSession) *Session {
	return &Session{
		Name:         tmuxSession.Name,
		Path:         tmuxSession.Path,
		LastAttached: tmuxSession.LastAttached,
		Active:       true,
	}
}

func CreateFromConfigItem(configSession config.Session) *Session {
	return &Session{
		Name: configSession.Name,
		Path: helpers.ExpandHome(configSession.Path),
		Cmd:  configSession.Cmd,
	}
}

func CreateFromPatternItem(configPattnern config.Pattern, resolvedPath string) *Session {
	return &Session{
		Name: filepath.Base(resolvedPath),
		Path: resolvedPath,
		Cmd:  configPattnern.Cmd,
	}
}

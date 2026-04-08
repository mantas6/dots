package session

import (
	"mantas6/sessionizer/config"
	"mantas6/sessionizer/tmuxsession"
	"path/filepath"
)

type Source int

const (
	SourceConfig Source = iota
	SourcePattern
	SourceTmux
)

type Session struct {
	Name         string
	Path         string
	Cmd          string
	LastAttached int
	Active       bool
	Source       Source
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
		Source:       SourceTmux,
	}
}

func CreateFromConfig(item config.Session) *Session {
	return &Session{
		Name:   item.Name,
		Path:   item.Path,
		Cmd:    item.Cmd,
		Source: SourceConfig,
	}
}

func CreateFromPattern(item config.Pattern, resolvedPath string) *Session {
	return &Session{
		Name:   filepath.Base(resolvedPath),
		Path:   resolvedPath,
		Cmd:    item.Cmd,
		Source: SourcePattern,
	}
}

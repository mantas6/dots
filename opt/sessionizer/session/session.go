package session

import (
	"mantas6/sessionizer/config"
	"path/filepath"
)

type Session struct {
	Name   string
	Path   string
	Cmd    string
	Active bool
}

func (s *Session) SetActive() {
	s.Active = true
}

func CreateFromConfigItem(configSession config.Session) Session {
	return Session{
		Name: configSession.Name,
		Path: configSession.Path,
		Cmd:  configSession.Cmd,
	}
}

func CreateFromPatternItem(configPattnern config.Pattern, resolvedPath string) Session {
	return Session{
		Name: filepath.Base(resolvedPath),
		Path: resolvedPath,
		Cmd:  configPattnern.Cmd,
	}
}

package session

import "mantas6/sessionizer/config"

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

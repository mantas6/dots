package main

import (
	"log"
	"mantas6/sessionizer/api"
	"mantas6/sessionizer/config"
	"mantas6/sessionizer/session"
	"mantas6/sessionizer/tmuxsession"
	"os"
	"sort"
	"strings"
)

func loadSessions() []*session.Session {
	configText := config.GetUserConfigurationText()
	cfg := config.ParseConfigurationText(configText)

	var sessionItems []*session.Session

	for _, configSession := range cfg.Sessions {
		configSession.Path = expandHome(configSession.Path)
		sessionItems = append(sessionItems, session.CreateFromConfigItem(configSession))
	}

	for _, configPattern := range cfg.Patterns {
		resolvedPaths := expandWildcardPaths(configPattern.Pattern)

		for _, resolvedPath := range resolvedPaths {
			sessionItems = append(sessionItems, session.CreateFromPatternItem(configPattern, resolvedPath))
		}
	}

	sessionsText, err := api.ListSessions()
	if err == nil {
		for _, line := range strings.Split(sessionsText, "\n") {
			tmuxSessionItem := tmuxsession.CreateFromLineItem(line)
			sessionItems = mergeInTmuxSession(sessionItems, tmuxSessionItem)
		}
	}

	sort.Slice(sessionItems, func(i, j int) bool {
		return sessionItems[i].LastAttached > sessionItems[j].LastAttached
	})

	return sessionItems
}

func mergeInTmuxSession(sessionItems []*session.Session, tmuxSessionItem tmuxsession.TmuxSession) []*session.Session {
	for _, s := range sessionItems {
		if s.MatchesTmuxSession(tmuxSessionItem) {
			s.SetActive(tmuxSessionItem.LastAttached)
			return sessionItems
		}
	}

	return append(sessionItems, session.CreateFromTmuxSession(tmuxSessionItem))
}

func switchToSession(name string) {
	if os.Getenv("TMUX") != "" {
		err := api.SwitchClient(name)
		if err != nil {
			log.Fatalf("Failed to switch to session: %v", err)
		}
	} else {
		err := api.Attach(name)
		if err != nil {
			log.Fatalf("Failed to attach to session: %v", err)
		}
	}
}

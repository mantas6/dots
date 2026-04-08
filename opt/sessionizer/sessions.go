package main

import (
	"log"
	"mantas6/sessionizer/api"
	"mantas6/sessionizer/config"
	"mantas6/sessionizer/order"
	"mantas6/sessionizer/session"
	"mantas6/sessionizer/tmuxsession"
	"sort"
	"strings"
)

func loadSessions() []*session.Session {
	configText := config.GetUserConfigurationText()
	cfg := config.ParseConfigurationText(configText)

	var sessionItems []*session.Session

	for _, configSession := range cfg.Sessions {
		configSession.Path = expandHome(configSession.Path)
		sessionItems = append(sessionItems, session.CreateFromConfig(configSession))
	}

	for _, configPattern := range cfg.Patterns {
		resolvedPaths := expandWildcardPaths(configPattern.Pattern)

		for _, resolvedPath := range resolvedPaths {
			sessionItems = append(sessionItems, session.CreateFromPattern(configPattern, resolvedPath))
		}
	}

	sessionsText, err := api.ListSessions()
	if err == nil {
		for _, line := range strings.Split(sessionsText, "\n") {
			tmuxSessionItem := tmuxsession.CreateFromLine(line)
			sessionItems = mergeInTmuxSession(sessionItems, tmuxSessionItem)
		}
	}

	sessionsOrder := order.Read()
	for order, sessionName := range sessionsOrder {
		for _, s := range sessionItems {
			if s.Name == sessionName {
				s.OrderCreated = order
			}
		}
	}

	sort.Slice(sessionItems, func(i, j int) bool {
		if sessionItems[i].Active != sessionItems[j].Active {
			return sessionItems[i].Active
		}

		if sessionItems[i].Active {
			return sessionItems[i].LastAttached > sessionItems[j].LastAttached
		}

		return sessionItems[i].OrderCreated < sessionItems[j].OrderCreated
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
	if api.Attached() {
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

func createNewSession(item *session.Session) {
	err := api.NewSession(item.Name, item.Path)
	if err != nil {
		log.Fatalf("Failed to create a session: %v", err)
	}

	if item.Cmd != "" {
		err := api.SendKeys(item.Name, []string{item.Cmd, "C-m"})
		if err != nil {
			log.Fatalf("Failed to send keys to a session: %v", err)
		}
	}
}

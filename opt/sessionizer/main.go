package main

import (
	"fmt"
	"log"
	"mantas6/sessionizer/api"
	"mantas6/sessionizer/config"
	"mantas6/sessionizer/helpers"
	"mantas6/sessionizer/session"
	"mantas6/sessionizer/tmuxsession"
	"os"
	"strings"
)

func main() {
	configText := config.GetUserConfigurationText()
	config := config.ParseConfigurationText(configText)

	var sessionItems []*session.Session

	for _, configSession := range config.Sessions {
		sessionItems = append(sessionItems, session.CreateFromConfigItem(configSession))
	}

	for _, configPattnern := range config.Patterns {
		resolvedPaths := helpers.ExpandWildcardPaths(configPattnern.Pattern)

		for _, resolvedPath := range resolvedPaths {
			sessionItems = append(sessionItems, session.CreateFromPatternItem(configPattnern, resolvedPath))
		}
	}

	sessionsText, err := api.ListSessions()
	if err != nil {
		log.Fatalf("Failed to list tmux sessions: %v", err)
	}

	for _, line := range strings.Split(sessionsText, "\n") {
		tmuxSessionItem := tmuxsession.CreateFromLineItem(line)
		for _, sessionItem := range sessionItems {
			if sessionItem.MatchesTmuxSession(tmuxSessionItem) {
				sessionItem.SetActive()
			}
		}
	}

	var selectedSessionName string
	if len(os.Args) > 1 {
		selectedSessionName = os.Args[1]
	}

	if selectedSessionName == "" {
		for _, sessionItem := range sessionItems {
			fmt.Printf("%v %v\n", sessionItem.Active, sessionItem.Name)
		}
		return
	}

	for _, sessionItem := range sessionItems {
		if sessionItem.Name == selectedSessionName {
			if sessionItem.Active {
				// check if tmux is running
				err := api.SwitchClient(sessionItem.Name)
				if err != nil {
					log.Fatalf("Failed to attach to session: %v", err)
				}
				return
			}

			err := api.NewSession(sessionItem.Name, sessionItem.Path)
			if err != nil {
				log.Fatalf("Failed to create a session: %v", err)
			}
			if sessionItem.Cmd != "" {
				err := api.SendKeys(sessionItem.Name, []string{sessionItem.Cmd, "C-m"})
				if err != nil {
					log.Fatalf("Failed to send keys to a session: %v", err)
				}
			}
		}
	}
}

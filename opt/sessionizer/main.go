package main

import (
	"mantas6/sessionizer/api"
	"mantas6/sessionizer/config"
	"mantas6/sessionizer/helpers"
	"mantas6/sessionizer/session"
	"mantas6/sessionizer/tmuxsession"
	"fmt"
	"log"
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

	var selectedSession string
	if len(os.Args) > 1 {
		selectedSession = os.Args[1]
	}

	for _, sessionItem := range sessionItems {
		fmt.Printf("%v %v\n", sessionItem.Active, sessionItem.Name)
	}

	// currentSessionName, _ := api.CurrentSession()
	// fmt.Println(currentSessionName)
}

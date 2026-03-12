package main

import (
	"flag"
	"fmt"
	"log"
	"mantas6/sessionizer/api"
	"mantas6/sessionizer/config"
	"mantas6/sessionizer/helpers"
	"mantas6/sessionizer/session"
	"mantas6/sessionizer/tmuxsession"
	"os"
	"sort"
	"strings"
)

func main() {
	lastFlag := flag.Bool("l", false, "return to last attached session")
	flag.Parse()

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

	currentSession, err := api.CurrentSession()
	if err != nil {
		log.Fatalf("Failed to get current tmux: %v", err)
	}

	for _, line := range strings.Split(sessionsText, "\n") {
		tmuxSessionItem := tmuxsession.CreateFromLineItem(line)
		for _, sessionItem := range sessionItems {
			if sessionItem.MatchesTmuxSession(tmuxSessionItem) {
				sessionItem.SetActive(tmuxSessionItem.LastAttached)
			}
		}
	}

	sort.Slice(sessionItems, func(i, j int) bool {
		return sessionItems[i].LastAttached > sessionItems[j].LastAttached
	})

	var selectedSessionName string
	if flag.NArg() > 0 {
		selectedSessionName = flag.Arg(0)
	}

	if selectedSessionName == "" {
		for _, sessionItem := range sessionItems {
			if sessionItem.Name == currentSession {
				continue
			}

			if *lastFlag {
				switchToSession(sessionItem.Name)
				return
			}

			tag := "-"
			if sessionItem.Active {
				tag = "*"
			}

			fmt.Printf("%v %v\n", tag, sessionItem.Name)
		}

		return
	}

	for _, sessionItem := range sessionItems {
		if sessionItem.Name == selectedSessionName {
			if sessionItem.Active {
				switchToSession(sessionItem.Name)
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

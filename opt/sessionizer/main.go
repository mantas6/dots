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
	"sort"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		return
	}

	switch os.Args[1] {
	case "list":
		sessionItems := loadSessions()
		currentSession, _ := api.CurrentSession()

		for _, s := range sessionItems {
			if s.Name == currentSession {
				continue
			}
			tag := "-"
			switch s.Source {
			case session.SourceConfig:
				tag = "#"
			case session.SourcePattern:
				tag = "~"
			}

			color := "\033[90m"
			if s.Active {
				color = "\033[34m"
			}

			fmt.Printf("%s%v \033[0m%v\n", color, tag, s.Name)
		}

	case "last":
		sessionItems := loadSessions()
		currentSession, err := api.CurrentSession()
		if err != nil {
			log.Fatalf("Failed to get current tmux: %v", err)
		}

		for _, s := range sessionItems {
			if s.Name == currentSession {
				continue
			}
			if s.Active {
				switchToSession(s.Name)
				return
			}
		}

	case "connect":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "usage: sessionizer connect <name>")
			os.Exit(1)
		}
		selectedSessionName := os.Args[2]
		sessionItems := loadSessions()

		for _, s := range sessionItems {
			if s.Name != selectedSessionName {
				continue
			}

			if s.Active {
				switchToSession(s.Name)
				return
			}

			err := api.NewSession(s.Name, s.Path)
			if err != nil {
				log.Fatalf("Failed to create a session: %v", err)
			}
			if s.Cmd != "" {
				err := api.SendKeys(s.Name, []string{s.Cmd, "C-m"})
				if err != nil {
					log.Fatalf("Failed to send keys to a session: %v", err)
				}
			}
			switchToSession(s.Name)
			return
		}

		fmt.Fprintf(os.Stderr, "session %q not found\n", selectedSessionName)
		os.Exit(1)

	default:
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Fprintln(os.Stderr, "usage: sessionizer <command>")
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "commands:")
	fmt.Fprintln(os.Stderr, "  list            list sessions")
	fmt.Fprintln(os.Stderr, "  last            switch to last accessed session")
	fmt.Fprintln(os.Stderr, "  connect <name>  connect to a session by name")
}

func loadSessions() []*session.Session {
	configText := config.GetUserConfigurationText()
	cfg := config.ParseConfigurationText(configText)

	var sessionItems []*session.Session

	for _, configSession := range cfg.Sessions {
		sessionItems = append(sessionItems, session.CreateFromConfigItem(configSession))
	}

	for _, configPattnern := range cfg.Patterns {
		resolvedPaths := helpers.ExpandWildcardPaths(configPattnern.Pattern)

		for _, resolvedPath := range resolvedPaths {
			sessionItems = append(sessionItems, session.CreateFromPatternItem(configPattnern, resolvedPath))
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
		if sessionItems[i].Active {
			return sessionItems[i].LastAttached > sessionItems[j].LastAttached
		}

		if sessionItems[i].Source != sessionItems[j].Source {
			return sessionItems[i].Source < sessionItems[j].Source
		}

		return false
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

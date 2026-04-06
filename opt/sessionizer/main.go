package main

import (
	"fmt"
	"log"
	"mantas6/sessionizer/api"
	"mantas6/sessionizer/session"
	"os"
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
				tag = "$"
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
			log.Fatalf("usage: sessionizer connect <name>")
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

		log.Fatalf("session %q not found", selectedSessionName)

	default:
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Fprintf(os.Stderr, "usage: %s <command>\n", os.Args[0])
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "commands:")
	fmt.Fprintln(os.Stderr, "  list            list sessions")
	fmt.Fprintln(os.Stderr, "  last            switch to last accessed session")
	fmt.Fprintln(os.Stderr, "  connect <name>  connect to a session by name")
}

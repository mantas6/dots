package main

import (
	"fmt"
	"log"
	"mantas6/sessionizer/api"
	"mantas6/sessionizer/order"
	"mantas6/sessionizer/session"
	"os"
)

const (
	colorBlue  = "\033[34m"
	colorGray  = "\033[90m"
	colorReset = "\033[0m"

	iconDefault = "-"
	iconConfig  = "#"
	iconPattern = "$"
	iconTmux    = "-"
)

func cmdList() {
	sessionItems := loadSessions()
	currentSession, _ := api.CurrentSession()

	for _, s := range sessionItems {
		if s.Name == currentSession {
			continue
		}
		tag := iconDefault
		switch s.Source {
		case session.SourceConfig:
			tag = iconConfig
		case session.SourcePattern:
			tag = iconPattern
		case session.SourceTmux:
			tag = iconTmux
		}

		color := colorGray
		if s.Active {
			color = colorBlue
		}

		fmt.Printf("%s%v %s%v\n", color, tag, colorReset, s.Name)
	}
}

func cmdLast() {
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
}

func cmdConnect() {
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

		createNewSession(s)
		switchToSession(s.Name)
		order.Update(sessionItems, s)

		return
	}

	log.Fatalf("session %q not found", selectedSessionName)
}

func printUsage() {
	fmt.Fprintf(os.Stderr, "usage: %s <command>\n", os.Args[0])
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "commands:")
	fmt.Fprintln(os.Stderr, "  list            list sessions")
	fmt.Fprintln(os.Stderr, "  last            switch to last accessed session")
	fmt.Fprintln(os.Stderr, "  connect <name>  connect to a session by name")
}

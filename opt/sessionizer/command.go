package main

import (
	"fmt"
	"log"
	"mantas6/sessionizer/api"
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
	iconTmux    = "O"
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
}

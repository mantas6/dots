package main

import (
	"log"
	"mantas6/sessionizer/api"
	"os"
	"path/filepath"
	"strings"
)

func expandWildcardPaths(pattern string) []string {
	if strings.HasPrefix(pattern, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return []string{}
		}

		pattern = filepath.Join(home, pattern[2:])
	}

	matches, err := filepath.Glob(pattern)
	if err != nil {
		return []string{}
	}

	return matches
}

func expandHome(path string) string {
	if strings.HasPrefix(path, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return path
		}
		return filepath.Join(home, path[2:])
	}
	return path
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

package order

import (
	"log"
	"mantas6/sessionizer/session"
	"os"
	"path/filepath"
	"strings"
)

const statePath = ".local/state/sessionizer-order"

func Update(sessionItems []*session.Session, creatingSession *session.Session) {
	lines := []string{creatingSession.Name}

	for _, s := range sessionItems {
		if s.Name == creatingSession.Name {
			continue
		}

		lines = append(lines, s.Name)
	}

	writeState(lines)
}

func Read() (lines []string) {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatalf("Failed to get home directory: %v", err)
	}

	stateFile := filepath.Join(home, statePath)

	data, err := os.ReadFile(stateFile)
	if err != nil {
		return []string{}
	}

	return strings.Split(strings.TrimSpace(string(data)), "\n")
}

func writeState(lines []string) {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatalf("Failed to get home directory: %v", err)
	}

	stateFile := filepath.Join(home, statePath)

	err = os.MkdirAll(filepath.Dir(stateFile), 0o755)
	if err != nil {
		log.Fatalf("Failed to create directories for %s: %v", stateFile, err)
	}

	data := []byte(strings.Join(lines, "\n") + "\n")

	err = os.WriteFile(stateFile, data, 0o644)
	if err != nil {
		log.Fatalf("Failed to write order file: %v", err)
	}
}

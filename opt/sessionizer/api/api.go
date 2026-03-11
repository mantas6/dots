package api

import (
	"os/exec"
	"strings"
)

func ListSessions() (string, error) {
	format := "#{session_last_attached} #{session_name} #{session_path}"

	out, err := exec.Command("tmux", "list-sessions", "-F", format).Output()
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(out)), nil
}

func SwitchClient(target string) error {
	return exec.Command("tmux", "switch-client", "-t", target).Run()
}

func Attach(target string) error {
	return exec.Command("tmux", "attach", "-t", target).Run()
}

func SendKeys(target string, keys []string) error {
	args := append([]string{"send-keys", "-t", target}, keys...)
	return exec.Command("tmux", args...).Run()
}

func CurrentSession() (string, error) {
	out, err := exec.Command("tmux", "display-message", "-p", "#S").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

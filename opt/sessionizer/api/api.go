package api

import (
	"bytes"
	"errors"
	"os"
	"os/exec"
	"strings"
)

func callTmux(args ...string) (string, error) {
	cmd := exec.Command("tmux", args...)

	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	out, err := cmd.Output()
	if err != nil {
		if msg := strings.TrimSpace(stderr.String()); msg != "" {
			return "", errors.New(msg)
		}

		return "", err
	}

	return strings.TrimSpace(string(out)), nil
}

func ListSessions() (string, error) {
	format := "#{session_last_attached} #{session_name} #{session_path}"
	return callTmux("list-sessions", "-F", format)
}

func SwitchClient(target string) error {
	_, err := callTmux("switch-client", "-t", target)
	return err
}

func Attach(target string) error {
	cmd := exec.Command("tmux", "attach", "-t", target)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func NewSession(name string, path string) error {
	_, err := callTmux("new-session", "-d", "-s", name, "-c", path)
	return err
}

func SendKeys(target string, keys []string) error {
	args := append([]string{"send-keys", "-t", target}, keys...)
	_, err := callTmux(args...)
	return err
}

func CurrentSession() (string, error) {
	return callTmux("display-message", "-p", "#S")
}

package api

import (
	"bytes"
	"errors"
	"mantas6/sessionizer/tmuxsession"
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

// sessionTarget builds an exact-match session target so names containing "." or ":" aren't parsed as window/pane
func sessionTarget(name string) string {
	return "=" + name + ":"
}

func Attached() bool {
	return os.Getenv("TMUX") != ""
}

func ListSessions() (output string, err error) {
	return callTmux("list-sessions", "-F", tmuxsession.LineFormat)
}

func SwitchClient(target string) error {
	_, err := callTmux("switch-client", "-t", sessionTarget(target))
	return err
}

func Attach(target string) error {
	cmd := exec.Command("tmux", "attach", "-t", sessionTarget(target))
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
	args := append([]string{"send-keys", "-t", sessionTarget(target)}, keys...)
	_, err := callTmux(args...)
	return err
}

func CurrentSession() (string, error) {
	return callTmux("display-message", "-p", "#S")
}

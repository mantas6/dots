package api

import (
	"bytes"
	"errors"
	"fmt"
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

func Attached() bool {
	return os.Getenv("TMUX") != ""
}

func ListSessions() (output string, err error) {
	return callTmux("list-sessions", "-F", tmuxsession.LineFormat)
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

func NewRemoteSession(name string, path string, host string, remoteSession string) error {
	command := remoteShellCommand(host, remoteSession)
	if _, err := callTmux("new-session", "-d", "-s", name, "-c", path, command); err != nil {
		return err
	}

	_, err := callTmux(
		"set-option", "-t", name, "prefix", "None", ";",
		"set-option", "-t", name, "prefix2", "C-b", ";",
		"set-option", "-t", name, "status", "off", ";",
		"set-option", "-t", name, "mouse", "off",
	)
	if err != nil {
		_, _ = callTmux("kill-session", "-t", name)
	}

	return err
}

func remoteShellCommand(host string, remoteSession string) string {
	remoteCommand := fmt.Sprintf("exec tmux new-session -A -s %s", shellQuote(remoteSession))
	return fmt.Sprintf("exec ssh -t -- %s %s", shellQuote(host), shellQuote(remoteCommand))
}

func shellQuote(value string) string {
	return "'" + strings.ReplaceAll(value, "'", "'\"'\"'") + "'"
}

func SendKeys(target string, keys []string) error {
	args := append([]string{"send-keys", "-t", target}, keys...)
	_, err := callTmux(args...)
	return err
}

func CurrentSession() (string, error) {
	return callTmux("display-message", "-p", "#S")
}

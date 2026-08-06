package api

import "testing"

func TestShellQuote(t *testing.T) {
	tests := map[string]string{
		"":          "''",
		"a5":        "'a5'",
		"it's here": "'it'\"'\"'s here'",
	}

	for value, expected := range tests {
		if actual := shellQuote(value); actual != expected {
			t.Errorf("shellQuote(%q) = %q, want %q", value, actual, expected)
		}
	}
}

func TestRemoteShellCommand(t *testing.T) {
	expected := "exec ssh -t -- 'a5' 'exec tmux new-session -A -s '\"'\"'main'\"'\"''"
	if actual := remoteShellCommand("a5", "main"); actual != expected {
		t.Fatalf("remoteShellCommand() = %q, want %q", actual, expected)
	}
}

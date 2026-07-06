package config

import (
	"errors"
	"os"
	"testing"
)

func TestLoadNotConfigured(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	if _, err := Load(); !errors.Is(err, ErrNotConfigured) {
		t.Fatalf("Load on empty dir = %v, want ErrNotConfigured", err)
	}
}

func TestSaveLoadRoundTrip(t *testing.T) {
	base := t.TempDir()
	t.Setenv("XDG_STATE_HOME", base)

	c := &Config{APIToken: "secret-token", WorkspaceID: 12345}
	if err := c.Save(); err != nil {
		t.Fatalf("save: %v", err)
	}

	path, _ := Path()
	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("stat: %v", err)
	}
	if perm := info.Mode().Perm(); perm != 0o600 {
		t.Errorf("config.json perm = %o, want 600", perm)
	}

	got, err := Load()
	if err != nil {
		t.Fatalf("load: %v", err)
	}
	if got.APIToken != c.APIToken || got.WorkspaceID != c.WorkspaceID {
		t.Errorf("round-trip = %+v, want %+v", got, c)
	}
}

func TestDirHonorsXDG(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", "/custom/state")
	dir, err := Dir()
	if err != nil {
		t.Fatalf("dir: %v", err)
	}
	if dir != "/custom/state/tg" {
		t.Errorf("Dir() = %q, want /custom/state/tg", dir)
	}
}

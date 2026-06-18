// Package config manages tgl's on-disk state directory: the API token and
// cached workspace id (config.json) plus the location of the SQLite database.
// The state directory honors XDG_STATE_HOME, falling back to ~/.local/state.
package config

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
)

// ErrNotConfigured is returned by Load when no config.json exists yet, i.e. the
// user has not run `tgl auth`.
var ErrNotConfigured = errors.New("not authenticated: run `tgl auth`")

// Config is the persisted credential/workspace state.
type Config struct {
	APIToken    string `json:"api_token"`
	WorkspaceID int64  `json:"workspace_id"`
}

// Dir returns the tgl state directory ($XDG_STATE_HOME/tgl or ~/.local/state/tgl).
func Dir() (string, error) {
	base := os.Getenv("XDG_STATE_HOME")
	if base == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		base = filepath.Join(home, ".local", "state")
	}
	return filepath.Join(base, "tgl"), nil
}

// EnsureDir creates the state directory (mode 0700) if it does not exist.
func EnsureDir() (string, error) {
	dir, err := Dir()
	if err != nil {
		return "", err
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return "", err
	}
	return dir, nil
}

// Path returns the absolute path to config.json.
func Path() (string, error) {
	dir, err := Dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "config.json"), nil
}

// DBPath returns the absolute path to the SQLite database file.
func DBPath() (string, error) {
	dir, err := Dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "tgl.db"), nil
}

// Load reads config.json. It returns ErrNotConfigured when the file is absent.
func Load() (*Config, error) {
	path, err := Path()
	if err != nil {
		return nil, err
	}
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrNotConfigured
	}
	if err != nil {
		return nil, err
	}
	var c Config
	if err := json.Unmarshal(data, &c); err != nil {
		return nil, err
	}
	return &c, nil
}

// Save writes config.json with mode 0600, creating the state directory first.
func (c *Config) Save() error {
	if _, err := EnsureDir(); err != nil {
		return err
	}
	path, err := Path()
	if err != nil {
		return err
	}
	data, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0o600)
}

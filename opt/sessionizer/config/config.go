package config

import (
	"log"
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

const configPath = ".config/tmux/sessions.toml"

type Pattern struct {
	Cmd     string `toml:"cmd"`
	Pattern string `toml:"pattern"`
}

type Session struct {
	Name string `toml:"name"`
	Path string `toml:"path"`
	Cmd  string `toml:"cmd"`
}

type Config struct {
	Patterns []Pattern `toml:"patterns"`
	Sessions []Session `toml:"session"`
}

func Load() Config {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatalf("Failed to get home directory: %v", err)
	}

	configFile := filepath.Join(home, configPath)

	var cfg Config
	if _, err := toml.DecodeFile(configFile, &cfg); err != nil {
		log.Fatalf("Failed to read configuration file: %v", err)
	}

	return cfg
}

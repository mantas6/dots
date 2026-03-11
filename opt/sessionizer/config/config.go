package config

import (
	"encoding/json"
	"log"
	"os"
	"os/exec"
)

type Pattern struct {
	Cmd     string `json:"cmd"`
	Pattern string `json:"pattern"`
}

type Session struct {
	Name string `json:"name"`
	Path string `json:"path,omitempty"`
	Cmd  string `json:"cmd,omitempty"`
}

type Config struct {
	Patterns []Pattern `json:"patterns"`
	Sessions []Session `json:"session"`
}

func ParseConfigurationText(configText string) Config {
	var cfg Config

	err := json.Unmarshal([]byte(configText), &cfg)
	if err != nil {
		log.Fatalf("Failed to parse configuration: %v", err)
	}

	return cfg
}

func GetUserConfigurationText() string {
	configDir, err := os.UserConfigDir()

	if err != nil {
		log.Fatalf("Failed to get user configuration directory: %v", err)
	}

	cmd := exec.Command("yq", "-p", "toml", "-o", "json", ".", configDir+"/tmux/sessions.toml")
	output, err := cmd.Output()

	if err != nil {
		log.Fatalf("Failed to read configuration file: %v", err)
	}

	return string(output)
}

package main

import (
	// "fmt"
	"log"
	"os"
	"os/exec"
)

func main() {
	configText := getUserConfigurationText()

	buildConfigurationObjects(configText)
}

func buildConfigurationObjects(configText string) {
	//
}

func getUserConfigurationText() string {
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

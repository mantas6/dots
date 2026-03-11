package main

import (
	"fmt"
	"mantas6/sessionizer/api"
	"mantas6/sessionizer/config"
	"mantas6/sessionizer/session"
)

func main() {
	configText := config.GetUserConfigurationText()
	config := config.ParseConfigurationText(configText)

	var sessionItems []session.Session
	for _, configSession := range config.Sessions {
		 sessionItems = append(sessionItems, session.CreateFromConfigItem(configSession))
	}

	// currentSessionName, _ := api.CurrentSession()
	// fmt.Println(currentSessionName)

	sessions, _ := api.ListSessions()
	fmt.Println(sessions)
}

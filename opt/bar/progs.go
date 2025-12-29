package main

import (
	"encoding/json"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

func getFastfetchData() (metrics []Metric) {
	cmd := exec.Command(
		"fastfetch",
		"--format", "json",
		"-c",
		"bar.jsonc",
	)

	out, err := cmd.Output()

	if err != nil {
		return
	}

	err = json.Unmarshal(out, &metrics)

	if err != nil {
		return
	}

	return
}

func getNetworkTime() string {
	start := time.Now()
	cmd := exec.Command("ping", "-c", "1", "-W", "1", "google.com")

	out, err := cmd.Output()

	if err != nil {
		if time.Since(start).Milliseconds() > 1000 {
			return "!"
		}

		return "-"
	}

	re := regexp.MustCompile(`time=([\d.]+) ms`)
	match := re.FindStringSubmatch(string(out))

	if len(match) < 2 {
		return "-"
	}

	return strings.Split(match[1], ".")[0] + "ms"
}

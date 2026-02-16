package main

import (
	"context"
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
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "ping", "-c", "1", "google.com")

	out, err := cmd.Output()

	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
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

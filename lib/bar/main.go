package main

import (
	"fmt"
	"encoding/json"
	"log"
	"os/exec"
)

type Metric struct {
	Type   string          `json:"type"`
	Result json.RawMessage `json:"result"`
}

type MemoryResult struct {
	Total int64 `json:"total"`
	Used  int64 `json:"used"`
}

func main() {
	cmd := exec.Command(
		"fastfetch",
		"--format", "json",
		"-s",
		"memory",
	)

	out, err := cmd.Output()

	if err != nil {
		log.Fatalf("Failed to run fastfetch: %v", err)
	}

	var metrics []Metric
	err = json.Unmarshal(out, &metrics)

	if err != nil {
		log.Fatalf("Failed to parse JSON: %v", err)
	}

	for _, m := range metrics {
		switch m.Type {
		case "Memory":
			var mem MemoryResult
			err = json.Unmarshal(m.Result, &mem)
			if err != nil {
				log.Fatalf("Err: %v", err)
			}
			usageGb := float64(mem.Used) / 1024 / 1024 / 1024
			fmt.Printf("󰘚 %.1fGB\n", usageGb)

		}
	}
}

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os/exec"
	"strings"
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
		"memory:cpuusage",
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

	var parts []string

	for _, m := range metrics {
		switch m.Type {
		case "Memory":
			var mem MemoryResult
			if json.Unmarshal(m.Result, &mem); err != nil {
				log.Fatalf("Err: %v", err)
			}
			usageGb := float64(mem.Used) / 1024 / 1024 / 1024
			parts = append(parts, fmt.Sprintf("󰘚 %.1fGB", usageGb))
		case "CPUUsage":
			var cpu []float64
			if json.Unmarshal(m.Result, &cpu); err != nil {
				log.Fatalf("Err: %v", err)
			}

			sum := 0.0
			max := 0.0

			for _, v := range cpu {
				sum += v
				if v >= max {
					max = v
				}
			}

			avg := sum / float64(len(cpu))
			parts = append(parts, fmt.Sprintf(" %.1f%%/%.1f%%", avg, max))

		}
	}

	fmt.Println(strings.Join(parts, " "))
}

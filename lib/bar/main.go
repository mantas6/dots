package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math"
	"os/exec"
	"strings"
)

type Metric struct {
	Type   string          `json:"type"`
	Result json.RawMessage `json:"result"`
}

type KernelResult struct {
	Release string `json:"release"`
}

type MemoryResult struct {
	Total int64 `json:"total"`
	Used  int64 `json:"used"`
}

type CpuResult struct {
	Temperature float64 `json:"temperature"`
}

type UptimeResult struct {
	Uptime int64 `json:"uptime"`
}

func cpuUsage(parts *[]string, res json.RawMessage) {
	var usages []float64
	if err := json.Unmarshal(res, &usages); err != nil {
		return
	}

	sum := 0.0
	max := 0.0

	for _, v := range usages {
		sum += v
		if v >= max {
			max = v
		}
	}

	avg := sum / float64(len(usages))
	*parts = append(*parts, fmt.Sprintf(" %2.0f%%/%2.0f%%", avg, max))
}

func cpuTemp(parts *[]string, res json.RawMessage) {
	var cpu CpuResult
	if err := json.Unmarshal(res, &cpu); err != nil {
		return
	}

	temp := math.Round(cpu.Temperature)
	*parts = append(*parts, fmt.Sprintf("󰏈 %.0fC", temp))
}

func memoryUsage(parts *[]string, res json.RawMessage) {
	var mem MemoryResult
	if err := json.Unmarshal(res, &mem); err != nil {
		return
	}

	usageGb := float64(mem.Used) / 1024 / 1024 / 1024
	*parts = append(*parts, fmt.Sprintf("󰘚 %.1fG", usageGb))
}

func kernelVersion(parts *[]string, res json.RawMessage) {
	var p KernelResult
	if err := json.Unmarshal(res, &p); err != nil {
		return
	}

	*parts = append(*parts, fmt.Sprintf(" %s", p.Release))
}

func uptime(parts *[]string, res json.RawMessage) {
	var p UptimeResult
	if err := json.Unmarshal(res, &p); err != nil {
		return
	}

	time := p.Uptime / 1000 / 60
	unit := "m"

	if (time > 60) {
		time /= 60
		unit = "h"

		if (time > 24) {
			time /= 24
			unit = "d"
		}
	}


	*parts = append(*parts, fmt.Sprintf("󰐦 %v%s", time, unit))
}

func main() {
	cmd := exec.Command(
		"fastfetch",
		"--format", "json",
		"-c",
		"bar.jsonc",
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
		res := m.Result

		switch m.Type {
		case "Memory":
			memoryUsage(&parts, res)
		case "CPUUsage":
			cpuUsage(&parts, res)
		case "CPU":
			cpuTemp(&parts, res)
		case "Kernel":
			kernelVersion(&parts, res)
		case "Uptime":
			uptime(&parts, res)
		}
	}

	fmt.Println(strings.Join(parts, " "))
}

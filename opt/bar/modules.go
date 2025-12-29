package main

import (
	"encoding/json"
	"fmt"
	"math"
	"strings"
	"time"
)

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

func swapUsage(parts *[]string, res json.RawMessage) {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return
	}

	if len(raw) == 0 {
		return
	}

	var totalUsed int64 = 0

	for _, dev := range raw {
		var p SwapResult
		if err := json.Unmarshal(dev, &p); err != nil {
			continue
		}

		totalUsed += p.Used
	}

	*parts = append(*parts, fmt.Sprintf(" %v%%", totalUsed))
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

	if time > 60 {
		time /= 60
		unit = "h"

		if time > 24 {
			time /= 24
			unit = "d"
		}
	}

	*parts = append(*parts, fmt.Sprintf("󰐦 %v%s", time, unit))
}

func clock(parts *[]string) {
	s := time.Now().Format(time.TimeOnly)
	*parts = append(*parts, fmt.Sprintf(" %v", s))
}

func battery(parts *[]string, res json.RawMessage) {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return
	}

	if len(raw) == 0 {
		return
	}

	var p BatteryResult
	if err := json.Unmarshal(raw[0], &p); err != nil {
		return
	}

	icon := ""

	switch {
	case strings.Contains(p.Status, "Charging"):
		icon = "󱐋"
	case strings.Contains(p.Status, "AC Connected"):
		icon = ""
	case p.Capacity > 80:
		icon = ""
	case p.Capacity > 60:
		icon = ""
	case p.Capacity > 40:
		icon = ""
	case p.Capacity > 20:
		icon = ""
	default:
		icon = ""
	}

	*parts = append(*parts, fmt.Sprintf("%v %.0f%%", icon, p.Capacity))
}

func diskUsage(parts *[]string, res json.RawMessage) {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return
	}

	for _, disk := range raw {
		var p DiskResult
		if err := json.Unmarshal(disk, &p); err != nil {
			continue
		}

		if p.Mountpoint != "/" {
			continue
		}

		usagePercent := float64(p.Bytes.Used) / float64(p.Bytes.Total) * 100
		*parts = append(*parts, fmt.Sprintf(" %.0f%%", usagePercent))
		return
	}
}

func networkPing(parts *[]string, networkTime string) {
	*parts = append(*parts, fmt.Sprintf(" %v", networkTime))
}

func networkIO(parts *[]string, res json.RawMessage) {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return
	}

	for _, dev := range raw {
		var p NetworkIOResult
		if err := json.Unmarshal(dev, &p); err != nil {
			continue
		}

		if !p.DefaultRoute {
			continue
		}

		icon := "󰛴"
		bytes := p.RxBytes

		if p.TxBytes > p.RxBytes {
			icon = "󰛶"
			bytes = p.TxBytes
		}

		*parts = append(*parts, fmt.Sprintf("%s %v", icon, formatBytes(bytes)))
		return
	}
}

func volume(parts *[]string, res json.RawMessage) {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return
	}

	for _, dev := range raw {
		var p SoundResult
		if err := json.Unmarshal(dev, &p); err != nil {
			continue
		}

		if !p.Active || !p.Main {
			continue
		}

		*parts = append(*parts, fmt.Sprintf("󰕾 %v%%", p.Volume))
		return
	}
}

func bluetoothBattery(parts *[]string, res json.RawMessage) {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return
	}

	for _, dev := range raw {
		var p BluetoothResult
		if err := json.Unmarshal(dev, &p); err != nil {
			continue
		}

		if !p.Connected || p.Battery == 0 {
			continue
		}

		*parts = append(*parts, fmt.Sprintf("󰂳 %v%%", p.Battery))
		return
	}
}

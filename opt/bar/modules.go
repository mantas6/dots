package main

import (
	"encoding/json"
	"fmt"
	"math"
	"slices"
	"strings"
	"time"
)

func cpuUsage(res json.RawMessage) *Part {
	var usages []float64
	if err := json.Unmarshal(res, &usages); err != nil {
		return nil
	}

	sum := 0.0

	for _, v := range usages {
		sum += v
	}

	avg := sum / float64(len(usages))
	return &Part{Icon: "", Value: fmt.Sprintf("%02.0f%%", avg)}
}

func cpuTemp(res json.RawMessage) *Part {
	var cpu CpuResult
	if err := json.Unmarshal(res, &cpu); err != nil {
		return nil
	}

	if cpu.Temperature == nil {
		return nil
	}

	temp := math.Round(*cpu.Temperature)
	return &Part{Icon: "󰏈", Value: fmt.Sprintf("%.0fC", temp)}
}

func memoryUsage(res json.RawMessage) *Part {
	var mem MemoryResult
	if err := json.Unmarshal(res, &mem); err != nil {
		return nil
	}

	usageGb := float64(mem.Used) / 1024 / 1024 / 1024
	return &Part{Icon: "󰘚", Value: fmt.Sprintf("%.1fG", usageGb)}
}

func swapUsage(res json.RawMessage) *Part {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return nil
	}

	if len(raw) == 0 {
		return nil
	}

	var totalUsed int64 = 0

	for _, dev := range raw {
		var p SwapResult
		if err := json.Unmarshal(dev, &p); err != nil {
			continue
		}

		totalUsed += p.Used
	}

	usageGb := float64(totalUsed) / 1024 / 1024 / 1024
	return &Part{Icon: "󰾶", Value: fmt.Sprintf("%.1fG", usageGb)}
}

func kernelVersion(res json.RawMessage) *Part {
	var p KernelResult
	if err := json.Unmarshal(res, &p); err != nil {
		return nil
	}

	return &Part{Icon: "", Value: p.Release}
}

func uptime(res json.RawMessage) *Part {
	var p UptimeResult
	if err := json.Unmarshal(res, &p); err != nil {
		return nil
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

	return &Part{Icon: "󰐦", Value: fmt.Sprintf("%v%s", time, unit)}
}

func clock() *Part {
	return &Part{Icon: "", Value: time.Now().Format(time.TimeOnly)}
}

func battery(res json.RawMessage) *Part {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return nil
	}

	if len(raw) == 0 {
		return nil
	}

	var p BatteryResult
	if err := json.Unmarshal(raw[0], &p); err != nil {
		return nil
	}

	icon := ""

	hasStatus := func(s string) bool {
		for _, v := range p.Status {
			if strings.Contains(v, s) {
				return true
			}
		}
		return false
	}

	switch {
	case hasStatus("Charging"):
		icon = "󱐋"
	case hasStatus("AC Connected"):
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

	return &Part{Icon: icon, Value: fmt.Sprintf("%.0f%%", p.Capacity)}
}

func diskUsage(res json.RawMessage) *Part {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return nil
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
		return &Part{Icon: "", Value: fmt.Sprintf("%.0f%%", usagePercent)}
	}
	return nil
}

func networkPing(networkTime string) *Part {
	return &Part{Icon: "", Value: networkTime}
}

func networkIO(res json.RawMessage) *Part {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return nil
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

		return &Part{Icon: icon, Value: formatBytes(bytes)}
	}
	return nil
}

func diskIO(res json.RawMessage) *Part {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return nil
	}

	for _, dev := range raw {
		var p DiskIOResult
		if err := json.Unmarshal(dev, &p); err != nil {
			continue
		}

		icon := "󰪩"
		bytes := p.BytesRead

		if p.BytesWritten > p.BytesRead {
			icon = "󰮆"
			bytes = p.BytesWritten
		}

		return &Part{Icon: icon, Value: fmt.Sprintf("%vM", bytes/1024/1024)}
	}
	return nil
}

func volume(res json.RawMessage) *Part {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return nil
	}

	for _, dev := range raw {
		var p SoundResult
		if err := json.Unmarshal(dev, &p); err != nil {
			continue
		}

		if !slices.Contains(p.Type, "active") {
			continue
		}

		return &Part{Icon: "󰕾", Value: fmt.Sprintf("%v%%", p.Volume)}
	}
	return nil
}

func bluetoothBattery(res json.RawMessage) *Part {
	var raw []json.RawMessage
	if err := json.Unmarshal(res, &raw); err != nil {
		return nil
	}

	for _, dev := range raw {
		var p BluetoothResult
		if err := json.Unmarshal(dev, &p); err != nil {
			continue
		}

		if !p.Connected || p.Battery == 0 {
			continue
		}

		return &Part{Icon: "󰂳", Value: fmt.Sprintf("%v%%", p.Battery)}
	}
	return nil
}

func dns(res json.RawMessage) *Part {
	var addresses []string
	if err := json.Unmarshal(res, &addresses); err != nil {
		return nil
	}

	for _, address := range addresses {
		return &Part{Icon: "󰒍", Value: address}
	}
	return nil
}

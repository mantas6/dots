package main

import (
	"fmt"
	"strings"
)

func main() {
	parts := new([]string)

	metrics := getFastfetchData()

	for _, m := range metrics {
		res := m.Result

		switch m.Type {
		case "Memory":
			memoryUsage(parts, res)
		case "CPUUsage":
			cpuUsage(parts, res)
		case "CPU":
			cpuTemp(parts, res)
		case "Kernel":
			kernelVersion(parts, res)
		case "Uptime":
			uptime(parts, res)
		case "Battery":
			battery(parts, res)
		case "Disk":
			diskUsage(parts, res)
		case "Sound":
			volume(parts, res)
		}
	}

	networkPing(parts)
	clock(parts)

	fmt.Println(strings.Join(*parts, " "))
}

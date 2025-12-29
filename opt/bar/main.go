package main

import (
	"fmt"
	"strings"
)

func main() {
	parts := new([]string)

	metrics := make(chan []Metric)
	networkTime := make(chan string)

	go func() {
		r := getFastfetchData()
		metrics <- r
	}()

	go func() {
		r := getNetworkTime()
		networkTime <- r
	}()

	for _, m := range <-metrics {
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
		case "Bluetooth":
			bluetoothBattery(parts, res)
		case "Swap":
			swapUsage(parts, res)
		case "NetIO":
			networkIO(parts, res)
		case "DiskIO":
			diskIO(parts, res)
		}
	}

	networkPing(parts, <-networkTime)
	clock(parts)

	fmt.Println(strings.Join(*parts, " "))
}

package main

import (
	"flag"
	"fmt"
	"strings"
)

func main() {
	padding := flag.Int("p", 1, "number of spaces between elements")
	flag.Parse()

	gap := strings.Repeat(" ", *padding)
	parts := []Part{}

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

		var p *Part
		switch m.Type {
		case "Memory":
			p = memoryUsage(res)
		case "CPUUsage":
			p = cpuUsage(res)
		case "CPU":
			p = cpuTemp(res)
		case "Kernel":
			p = kernelVersion(res)
		case "Uptime":
			p = uptime(res)
		case "Battery":
			p = battery(res)
		case "Disk":
			p = diskUsage(res)
		case "Sound":
			p = volume(res)
		case "Bluetooth":
			p = bluetoothBattery(res)
		case "Swap":
			p = swapUsage(res)
		case "NetIO":
			p = networkIO(res)
		case "DiskIO":
			p = diskIO(res)
		case "DNS":
			p = dns(res)
		}
		if p != nil {
			parts = append(parts, *p)
		}
	}

	if p := networkPing(<-networkTime); p != nil {
		parts = append(parts, *p)
	}
	if p := clock(); p != nil {
		parts = append(parts, *p)
	}

	strs := make([]string, len(parts))
	for i, part := range parts {
		strs[i] = part.Format(gap)
	}
	fmt.Println(strings.Join(strs, gap))
}

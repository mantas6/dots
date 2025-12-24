package main

import (
	"encoding/json"
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

type BatteryResult struct {
	Capacity float64 `json:"capacity"`
	Status   string  `json:"status"`
}

type DiskBytesResult struct {
	Used  int64 `json:"used"`
	Total int64 `json:"total"`
}

type DiskResult struct {
	Mountpoint string          `json:"mountpoint"`
	Bytes      DiskBytesResult `json:"bytes"`
}

type SoundResult struct {
	Active bool `json:"active"`
	Main   bool `json:"main"`
	Volume int  `json:"volume"`
}

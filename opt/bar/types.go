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

type SwapResult struct {
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

type BluetoothResult struct {
	Connected bool `json:"connected"`
	Battery   int  `json:"battery"`
}

type NetworkIOResult struct {
	DefaultRoute bool  `json:"defaultRoute"`
	TxBytes      int64 `json:"txBytes"`
	RxBytes      int64 `json:"rxBytes"`
}

type DiskIOResult struct {
	BytesRead    int64 `json:"bytesRead"`
	BytesWritten int64 `json:"bytesWritten"`
}

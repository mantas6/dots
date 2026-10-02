package main

import (
	"encoding/json"
	"fmt"
	"testing"
	"time"
)

func TestUptimeUnitBoundaries(t *testing.T) {
	cases := []struct {
		duration time.Duration
		want     string
	}{
		{0, "0m"},
		{time.Minute - time.Millisecond, "0m"},
		{time.Minute, "1m"},
		{time.Hour - time.Millisecond, "59m"},
		{time.Hour, "1h"},
		{time.Hour + time.Millisecond, "1h"},
		{time.Hour + time.Minute - time.Millisecond, "1h"},
		{time.Hour + time.Minute, "1h"},
		{24*time.Hour - time.Millisecond, "23h"},
		{24 * time.Hour, "1d"},
		{24*time.Hour + time.Millisecond, "1d"},
		{25*time.Hour - time.Millisecond, "1d"},
		{25 * time.Hour, "1d"},
		{48 * time.Hour, "2d"},
	}

	for _, tc := range cases {
		t.Run(tc.duration.String(), func(t *testing.T) {
			res := json.RawMessage(fmt.Sprintf(`{"uptime":%d}`, tc.duration.Milliseconds()))
			got := uptime(res)
			if got == nil {
				t.Fatal("uptime returned nil for valid input")
			}
			if got.Value != tc.want {
				t.Errorf("uptime = %q, want %q", got.Value, tc.want)
			}
			if got.Icon != "󰐦" {
				t.Errorf("uptime icon changed: %q", got.Icon)
			}
		})
	}
}

func TestUptimeInvalidJSON(t *testing.T) {
	if got := uptime(json.RawMessage(`{"uptime":`)); got != nil {
		t.Errorf("uptime returned %+v for invalid JSON, want nil", got)
	}
}

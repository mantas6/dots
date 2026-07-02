package main

import (
	"bytes"
	"flag"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"mantas6/tgl/store"
)

var update = flag.Bool("update", false, "update golden files")

// assertGolden compares got against testdata/<name>, rewriting it under -update.
func assertGolden(t *testing.T, name, got string) {
	t.Helper()
	path := filepath.Join("testdata", name)
	if *update {
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(got), 0o644); err != nil {
			t.Fatal(err)
		}
		return
	}
	want, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read golden %s: %v (run with -update)", name, err)
	}
	if got != string(want) {
		t.Errorf("golden %s mismatch:\n--- got ---\n%s\n--- want ---\n%s", name, got, want)
	}
}

func TestCeil5(t *testing.T) {
	cases := []struct {
		in   time.Duration
		want time.Duration
	}{
		{0, 5 * time.Minute},
		{1 * time.Second, 5 * time.Minute},
		{5 * time.Minute, 5 * time.Minute},
		{5*time.Minute + 1*time.Second, 10 * time.Minute},
		{46 * time.Minute, 50 * time.Minute},
		{45 * time.Minute, 45 * time.Minute},
		{-3 * time.Minute, 5 * time.Minute},
	}
	for _, c := range cases {
		if got := ceil5(c.in); got != c.want {
			t.Errorf("ceil5(%v) = %v, want %v", c.in, got, c.want)
		}
	}
}

func TestFormatHM(t *testing.T) {
	cases := []struct {
		in   time.Duration
		want string
	}{
		{0, "0h00m"},
		{45 * time.Minute, "0h45m"},
		{75 * time.Minute, "1h15m"},
		{120 * time.Minute, "2h00m"},
		{-time.Minute, "0h00m"},
	}
	for _, c := range cases {
		if got := formatHM(c.in); got != c.want {
			t.Errorf("formatHM(%v) = %q, want %q", c.in, got, c.want)
		}
	}
}

func TestFormatClock(t *testing.T) {
	tm := time.Date(2026, 1, 2, 9, 15, 0, 0, time.UTC)
	if got := formatClock(tm, time.UTC); got != "09:15" {
		t.Errorf("formatClock = %q, want 09:15", got)
	}
}

// sampleDay builds the two-entry fixture used across golden tests.
func sampleDay() (entries []store.Entry, now time.Time) {
	start1 := time.Date(2026, 1, 2, 9, 15, 0, 0, time.UTC)
	stop1 := time.Date(2026, 1, 2, 10, 30, 0, 0, time.UTC)
	start2 := time.Date(2026, 1, 2, 10, 30, 0, 0, time.UTC)
	now = time.Date(2026, 1, 2, 11, 15, 0, 0, time.UTC)
	entries = []store.Entry{
		{ID: 11, TaskName: "Fix login bug", ProjectName: "Backend", Start: start1, Stop: &stop1, Duration: 4500},
		{ID: 12, TaskName: "Code review", ProjectName: "Backend", Start: start2, Duration: -1},
	}
	return entries, now
}

func TestRenderTodayGolden(t *testing.T) {
	entries, now := sampleDay()
	var buf bytes.Buffer
	renderToday(&buf, entries, now, time.UTC)
	assertGolden(t, "today.txt", buf.String())
}

func TestRenderTodayJSONGolden(t *testing.T) {
	entries, now := sampleDay()
	var buf bytes.Buffer
	if err := renderTodayJSON(&buf, entries, now); err != nil {
		t.Fatal(err)
	}
	assertGolden(t, "today.json", buf.String())
}

func TestRenderTodayEmpty(t *testing.T) {
	var buf bytes.Buffer
	renderToday(&buf, nil, time.Now(), time.UTC)
	if buf.String() != "No entries.\n" {
		t.Errorf("empty today = %q", buf.String())
	}
}

func TestRenderCurrentGolden(t *testing.T) {
	entries, now := sampleDay()
	running := entries[1] // the running entry

	var human bytes.Buffer
	if err := renderCurrent(&human, &running, now, time.UTC, false); err != nil {
		t.Fatal(err)
	}
	assertGolden(t, "current.txt", human.String())

	var js bytes.Buffer
	if err := renderCurrent(&js, &running, now, time.UTC, true); err != nil {
		t.Fatal(err)
	}
	assertGolden(t, "current.json", js.String())
}

// sampleTasks builds the catalog-listing fixture (project name joined),
// pre-sorted by project then task name as ListTasks returns them.
func sampleTasks() []store.Task {
	return []store.Task{
		{ID: 12, Name: "Code review", ProjectName: "Backend", Active: true},
		{ID: 10, Name: "Fix login bug", ProjectName: "Backend", Active: true},
		{ID: 20, Name: "Payment fix", ProjectName: "Payments", Active: true},
	}
}

func TestRenderTasksGolden(t *testing.T) {
	var buf bytes.Buffer
	renderTasks(&buf, sampleTasks())
	assertGolden(t, "tasks.txt", buf.String())
}

func TestRenderTasksJSONGolden(t *testing.T) {
	var buf bytes.Buffer
	if err := renderTasksJSON(&buf, sampleTasks()); err != nil {
		t.Fatal(err)
	}
	assertGolden(t, "tasks.json", buf.String())
}

func TestRenderTasksEmpty(t *testing.T) {
	var buf bytes.Buffer
	renderTasks(&buf, nil)
	if !strings.Contains(buf.String(), "tgl update") {
		t.Errorf("empty tasks = %q, want hint to run `tgl update`", buf.String())
	}
}

// sampleProjects builds the project-listing fixture, pre-sorted by name as
// ListProjects returns them.
func sampleProjects() []store.Project {
	return []store.Project{
		{ID: 1, Name: "Backend", Active: true},
		{ID: 2, Name: "Payments", ClientName: "Acme", Active: true},
	}
}

func TestRenderProjectsGolden(t *testing.T) {
	var buf bytes.Buffer
	renderProjects(&buf, sampleProjects())
	assertGolden(t, "projects.txt", buf.String())
}

func TestRenderProjectsJSONGolden(t *testing.T) {
	var buf bytes.Buffer
	if err := renderProjectsJSON(&buf, sampleProjects()); err != nil {
		t.Fatal(err)
	}
	assertGolden(t, "projects.json", buf.String())
}

func TestRenderProjectsEmpty(t *testing.T) {
	var buf bytes.Buffer
	renderProjects(&buf, nil)
	if !strings.Contains(buf.String(), "tgl update") {
		t.Errorf("empty projects = %q, want hint to run `tgl update`", buf.String())
	}
}

func TestRenderCurrentNoneGolden(t *testing.T) {
	var human bytes.Buffer
	if err := renderCurrent(&human, nil, time.Now(), time.UTC, false); err != nil {
		t.Fatal(err)
	}
	assertGolden(t, "current_none.txt", human.String())

	var js bytes.Buffer
	if err := renderCurrent(&js, nil, time.Now(), time.UTC, true); err != nil {
		t.Fatal(err)
	}
	assertGolden(t, "current_none.json", js.String())
}

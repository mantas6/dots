package main

import (
	"bytes"
	"flag"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"mantas6/tg/store"
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
	renderToday(&buf, entries, now, time.UTC, false)
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

func TestRenderTodayGaps(t *testing.T) {
	day := time.Date(2026, 1, 2, 0, 0, 0, 0, time.UTC)
	at := func(d time.Duration) time.Time { return day.Add(d) }
	pt := func(t time.Time) *time.Time { return &t }
	now := at(23 * time.Hour)

	cases := []struct {
		name    string
		entries []store.Entry
		want    string // substring that must appear...
		absent  bool   // ...or must not appear when true
	}{
		{
			name: "gap shown",
			entries: []store.Entry{
				{TaskName: "A", Start: at(9 * time.Hour), Stop: pt(at(10 * time.Hour)), Duration: 3600},
				{TaskName: "B", Start: at(10*time.Hour + 25*time.Minute), Stop: pt(at(11 * time.Hour)), Duration: 2100},
			},
			want: "            (gap 0h25m)\n",
		},
		{
			name: "gap below threshold hidden",
			entries: []store.Entry{
				{TaskName: "A", Start: at(9 * time.Hour), Stop: pt(at(10 * time.Hour)), Duration: 3600},
				{TaskName: "B", Start: at(10*time.Hour + 30*time.Second), Stop: pt(at(11 * time.Hour)), Duration: 3570},
			},
			want:   "(gap",
			absent: true,
		},
		{
			name: "no cross-day gap",
			entries: []store.Entry{
				{TaskName: "A", Start: at(-2 * time.Hour), Stop: pt(at(-1 * time.Hour)), Duration: 3600},
				{TaskName: "B", Start: at(9 * time.Hour), Stop: pt(at(10 * time.Hour)), Duration: 3600},
			},
			want:   "(gap",
			absent: true,
		},
		{
			name: "no gap after running entry",
			entries: []store.Entry{
				{TaskName: "A", Start: at(9 * time.Hour), Duration: -1},
				{TaskName: "B", Start: at(10 * time.Hour), Stop: pt(at(11 * time.Hour)), Duration: 3600},
			},
			want:   "(gap",
			absent: true,
		},
		{
			name: "no gap on overlap",
			entries: []store.Entry{
				{TaskName: "A", Start: at(9 * time.Hour), Stop: pt(at(11 * time.Hour)), Duration: 7200},
				{TaskName: "B", Start: at(10 * time.Hour), Stop: pt(at(10*time.Hour + 30*time.Minute)), Duration: 1800},
			},
			want:   "(gap",
			absent: true,
		},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			var buf bytes.Buffer
			renderToday(&buf, c.entries, now, time.UTC, false)
			got := buf.String()
			if c.absent {
				if strings.Contains(got, c.want) {
					t.Errorf("output contains %q, want it absent:\n%s", c.want, got)
				}
			} else if !strings.Contains(got, c.want) {
				t.Errorf("output missing %q:\n%s", c.want, got)
			}
		})
	}
}

func TestParseHexColor(t *testing.T) {
	cases := []struct {
		in      string
		r, g, b uint8
		ok      bool
	}{
		{"#000000", 0, 0, 0, true},
		{"#ffffff", 255, 255, 255, true},
		{"#0B83D9", 11, 131, 217, true},
		{"", 0, 0, 0, false},
		{"#fff", 0, 0, 0, false},     // short form unsupported
		{"0b83d9", 0, 0, 0, false},   // missing '#'
		{"#gggggg", 0, 0, 0, false},  // bad digits
		{"#0b83d9a", 0, 0, 0, false}, // too long
	}
	for _, c := range cases {
		r, g, b, ok := parseHexColor(c.in)
		if r != c.r || g != c.g || b != c.b || ok != c.ok {
			t.Errorf("parseHexColor(%q) = (%d,%d,%d,%v), want (%d,%d,%d,%v)",
				c.in, r, g, b, ok, c.r, c.g, c.b, c.ok)
		}
	}
}

func TestColorBlock(t *testing.T) {
	if got, want := colorBlock("#0B83D9"), "\x1b[38;2;11;131;217m\u25a0\x1b[0m"; got != want {
		t.Errorf("colorBlock = %q, want %q", got, want)
	}
	for _, bad := range []string{"", "#fff", "nope"} {
		if got := colorBlock(bad); got != "" {
			t.Errorf("colorBlock(%q) = %q, want empty", bad, got)
		}
	}
}

func TestRenderTodayColor(t *testing.T) {
	entries, now := sampleDay()
	for i := range entries {
		entries[i].ProjectColor = "#0B83D9"
	}

	// color enabled: a tinted block leads the line, followed by a space.
	var buf bytes.Buffer
	renderToday(&buf, entries, now, time.UTC, true)
	if want := "\x1b[38;2;11;131;217m\u25a0\x1b[0m 09:15-10:30"; !strings.Contains(buf.String(), want) {
		t.Errorf("colored output missing %q:\n%q", want, buf.String())
	}

	// color disabled: plain output, no escape codes.
	buf.Reset()
	renderToday(&buf, entries, now, time.UTC, false)
	if strings.Contains(buf.String(), "\x1b") {
		t.Errorf("plain output contains ANSI escapes:\n%q", buf.String())
	}

	// invalid color: no block, no broken escapes.
	for i := range entries {
		entries[i].ProjectColor = "oops"
	}
	buf.Reset()
	renderToday(&buf, entries, now, time.UTC, true)
	if strings.Contains(buf.String(), "\x1b") {
		t.Errorf("invalid-color output contains ANSI escapes:\n%q", buf.String())
	}
}

func TestRenderTodayEmpty(t *testing.T) {
	var buf bytes.Buffer
	renderToday(&buf, nil, time.Now(), time.UTC, false)
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
	if !strings.Contains(buf.String(), "tg update") {
		t.Errorf("empty tasks = %q, want hint to run `tg update`", buf.String())
	}
}

// sampleProjects builds the project-listing fixture, pre-sorted by name as
// ListProjects returns them.
func sampleProjects() []store.Project {
	return []store.Project{
		{ID: 1, Name: "Backend", Active: true},
		{ID: 2, Name: "Payments", ClientName: "Acme", Active: true, Billable: true},
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
	if !strings.Contains(buf.String(), "tg update") {
		t.Errorf("empty projects = %q, want hint to run `tg update`", buf.String())
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

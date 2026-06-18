package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"mantas6/tgl/api"
	"mantas6/tgl/config"
	"mantas6/tgl/store"
)

func newStore(t *testing.T) *store.Store {
	t.Helper()
	s, err := store.Open(filepath.Join(t.TempDir(), "tgl.db"))
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	t.Cleanup(func() { s.Close() })
	return s
}

func seedCatalog(t *testing.T, s *store.Store) {
	t.Helper()
	if err := s.ReplaceProjects([]store.Project{
		{ID: 1, WorkspaceID: 1, Name: "Backend", Active: true},
		{ID: 2, WorkspaceID: 1, Name: "Payments", Active: true},
	}); err != nil {
		t.Fatal(err)
	}
	if err := s.ReplaceTasks([]store.Task{
		{ID: 10, WorkspaceID: 1, ProjectID: 1, Name: "Fix login bug", Active: true},
		{ID: 11, WorkspaceID: 1, ProjectID: 1, Name: "Fix", Active: true},
		{ID: 12, WorkspaceID: 1, ProjectID: 1, Name: "Code review", Active: true},
		{ID: 13, WorkspaceID: 1, ProjectID: 1, Name: "Write tests", Active: true},
		{ID: 14, WorkspaceID: 1, ProjectID: 1, Name: "Write docs", Active: true},
		{ID: 20, WorkspaceID: 1, ProjectID: 2, Name: "Payment fix", Active: true},
	}); err != nil {
		t.Fatal(err)
	}
}

var testStart = time.Date(2026, 1, 2, 9, 0, 0, 0, time.UTC)

func TestStartSingleMatch(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	if err := cmdStart(&buf, s, 1, nil, "login", testStart); err != nil {
		t.Fatalf("start: %v", err)
	}
	if !strings.Contains(buf.String(), "Started: Fix login bug") {
		t.Errorf("output = %q", buf.String())
	}

	r, _ := s.Running()
	if r == nil {
		t.Fatal("expected a running entry")
	}
	if r.TaskID == nil || *r.TaskID != 10 {
		t.Errorf("task_id = %v, want 10", r.TaskID)
	}
	if r.ProjectID == nil || *r.ProjectID != 1 {
		t.Errorf("project_id = %v, want 1", r.ProjectID)
	}
	if r.Description != "" {
		t.Errorf("description = %q, want empty", r.Description)
	}
	if !r.Start.Equal(testStart) {
		t.Errorf("start = %v, want %v", r.Start, testStart)
	}
	if !r.Dirty {
		t.Error("new entry should be dirty")
	}
}

func TestStartAutoStops(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	if err := cmdStart(&buf, s, 1, nil, "login", testStart); err != nil {
		t.Fatalf("first start: %v", err)
	}
	second := testStart.Add(30 * time.Minute)
	if err := cmdStart(&buf, s, 1, nil, "review", second); err != nil {
		t.Fatalf("second start: %v", err)
	}

	r, _ := s.Running()
	if r == nil || r.TaskID == nil || *r.TaskID != 12 {
		t.Fatalf("running entry = %+v, want Code review", r)
	}

	entries, _ := s.EntriesBetween(testStart.Add(-time.Hour), testStart.Add(24*time.Hour))
	if len(entries) != 2 {
		t.Fatalf("entries = %d, want 2", len(entries))
	}
	running := 0
	for _, e := range entries {
		if e.Stop == nil {
			running++
		}
	}
	if running != 1 {
		t.Errorf("running entries = %d, want exactly 1", running)
	}
}

func TestStartExactWins(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	// "Fix" exactly matches task 11 even though it is a substring of others.
	if err := cmdStart(&buf, s, 1, nil, "Fix", testStart); err != nil {
		t.Fatalf("start: %v", err)
	}
	r, _ := s.Running()
	if r == nil || r.TaskID == nil || *r.TaskID != 11 {
		t.Fatalf("running entry = %+v, want task 11 (Fix)", r)
	}
}

func TestStartManyAmbiguous(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	err := cmdStart(&buf, s, 1, nil, "write", testStart)
	if err == nil {
		t.Fatal("expected ambiguity error")
	}
	if !strings.Contains(err.Error(), "Write tests") || !strings.Contains(err.Error(), "Write docs") {
		t.Errorf("error should list candidates: %v", err)
	}
	if r, _ := s.Running(); r != nil {
		t.Errorf("nothing should be running, got %+v", r)
	}
}

func TestStartNoneSuggestsUpdate(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	err := cmdStart(&buf, s, 1, nil, "nonexistent", testStart)
	if err == nil || !strings.Contains(err.Error(), "tgl update") {
		t.Errorf("error = %v, want suggestion to run `tgl update`", err)
	}
}

func TestStartProjectScope(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	pid := int64(2)
	var buf bytes.Buffer
	// "fix" matches several tasks, but scoping to project 2 leaves only one.
	if err := cmdStart(&buf, s, 1, &pid, "fix", testStart); err != nil {
		t.Fatalf("start: %v", err)
	}
	r, _ := s.Running()
	if r == nil || r.TaskID == nil || *r.TaskID != 20 {
		t.Fatalf("running entry = %+v, want task 20 (Payment fix)", r)
	}
	if r.ProjectID == nil || *r.ProjectID != 2 {
		t.Errorf("project_id = %v, want 2", r.ProjectID)
	}
}

func TestProjectIDFromEnv(t *testing.T) {
	t.Setenv("TOGGL_PROJECT_ID", "42")
	if got := projectIDFromEnv(); got == nil || *got != 42 {
		t.Errorf("projectIDFromEnv = %v, want 42", got)
	}
	t.Setenv("TOGGL_PROJECT_ID", "")
	if got := projectIDFromEnv(); got != nil {
		t.Errorf("projectIDFromEnv (unset) = %v, want nil", got)
	}
	t.Setenv("TOGGL_PROJECT_ID", "abc")
	if got := projectIDFromEnv(); got != nil {
		t.Errorf("projectIDFromEnv (invalid) = %v, want nil", got)
	}
}

func TestStopQuantizes(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	if err := cmdStart(&buf, s, 1, nil, "login", testStart); err != nil {
		t.Fatalf("start: %v", err)
	}

	var stopBuf bytes.Buffer
	now := testStart.Add(46 * time.Minute) // -> rounds up to 50m
	if err := cmdStop(&stopBuf, s, now); err != nil {
		t.Fatalf("stop: %v", err)
	}
	if !strings.Contains(stopBuf.String(), "0h50m") {
		t.Errorf("stop output = %q, want 0h50m", stopBuf.String())
	}

	entries, _ := s.EntriesBetween(testStart.Add(-time.Hour), testStart.Add(24*time.Hour))
	if len(entries) != 1 {
		t.Fatalf("entries = %d, want 1", len(entries))
	}
	e := entries[0]
	if e.Duration != 3000 {
		t.Errorf("duration = %d, want 3000", e.Duration)
	}
	wantStop := testStart.Add(50 * time.Minute)
	if e.Stop == nil || !e.Stop.Equal(wantStop) {
		t.Errorf("stop = %v, want %v", e.Stop, wantStop)
	}
}

func TestStopNothingRunning(t *testing.T) {
	s := newStore(t)
	var buf bytes.Buffer
	if err := cmdStop(&buf, s, time.Now()); err != nil {
		t.Fatalf("stop: %v", err)
	}
	if !strings.Contains(buf.String(), "Nothing is running") {
		t.Errorf("output = %q", buf.String())
	}
}

// seedSampleDay mirrors the fixture behind today.txt / current.txt goldens.
func seedSampleDay(t *testing.T, s *store.Store) (now time.Time, loc *time.Location) {
	t.Helper()
	if err := s.ReplaceProjects([]store.Project{{ID: 1, WorkspaceID: 1, Name: "Backend", Active: true}}); err != nil {
		t.Fatal(err)
	}
	if err := s.ReplaceTasks([]store.Task{
		{ID: 10, WorkspaceID: 1, ProjectID: 1, Name: "Fix login bug", Active: true},
		{ID: 12, WorkspaceID: 1, ProjectID: 1, Name: "Code review", Active: true},
	}); err != nil {
		t.Fatal(err)
	}
	start1 := time.Date(2026, 1, 2, 9, 15, 0, 0, time.UTC)
	stop1 := time.Date(2026, 1, 2, 10, 30, 0, 0, time.UTC)
	start2 := time.Date(2026, 1, 2, 10, 30, 0, 0, time.UTC)
	if _, err := s.CreateEntry(store.Entry{
		WorkspaceID: 1, ProjectID: p(1), TaskID: p(10),
		Start: start1, Stop: &stop1, Duration: 4500, UpdatedAt: stop1,
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := s.CreateEntry(store.Entry{
		WorkspaceID: 1, ProjectID: p(1), TaskID: p(12),
		Start: start2, Duration: -1, UpdatedAt: start2,
	}); err != nil {
		t.Fatal(err)
	}
	return time.Date(2026, 1, 2, 11, 15, 0, 0, time.UTC), time.UTC
}

func p(v int64) *int64 { return &v }

func TestTodayCommandGolden(t *testing.T) {
	s := newStore(t)
	now, loc := seedSampleDay(t, s)
	var buf bytes.Buffer
	if err := cmdToday(&buf, s, now, loc, 1, false); err != nil {
		t.Fatalf("today: %v", err)
	}
	assertGolden(t, "today.txt", buf.String())
}

func TestCurrentCommandGolden(t *testing.T) {
	s := newStore(t)
	now, loc := seedSampleDay(t, s)
	var buf bytes.Buffer
	if err := cmdCurrent(&buf, s, now, loc, false); err != nil {
		t.Fatalf("current: %v", err)
	}
	assertGolden(t, "current.txt", buf.String())
}

func meHandler(t *testing.T) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/me" {
			t.Errorf("path = %q, want /me", r.URL.Path)
		}
		w.Write([]byte(`{"id":1,"default_workspace_id":12345,"fullname":"Test User"}`))
	}
}

func TestAuthSuccessWritesConfig(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	srv := httptest.NewServer(meHandler(t))
	defer srv.Close()

	var buf bytes.Buffer
	err := cmdAuth(&buf,
		func() (string, error) { return "tok123", nil },
		func(token string) *api.Client {
			return api.New(token, api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))
		})
	if err != nil {
		t.Fatalf("auth: %v", err)
	}
	if !strings.Contains(buf.String(), "Authenticated as Test User") {
		t.Errorf("output = %q", buf.String())
	}

	path, _ := config.Path()
	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("config.json missing: %v", err)
	}
	if perm := info.Mode().Perm(); perm != 0o600 {
		t.Errorf("perm = %o, want 600", perm)
	}
	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("load: %v", err)
	}
	if cfg.APIToken != "tok123" || cfg.WorkspaceID != 12345 {
		t.Errorf("config = %+v", cfg)
	}
}

func TestAuthForbiddenWritesNothing(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusForbidden)
	}))
	defer srv.Close()

	var buf bytes.Buffer
	err := cmdAuth(&buf,
		func() (string, error) { return "bad", nil },
		func(token string) *api.Client {
			return api.New(token, api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))
		})
	if err == nil {
		t.Fatal("expected an error for 403")
	}

	path, _ := config.Path()
	if _, statErr := os.Stat(path); !os.IsNotExist(statErr) {
		t.Errorf("config.json should not exist, stat err = %v", statErr)
	}
}

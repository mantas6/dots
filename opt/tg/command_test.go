package main

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"mantas6/tg/api"
	"mantas6/tg/config"
	"mantas6/tg/store"
)

func newStore(t *testing.T) *store.Store {
	t.Helper()
	s, err := store.Open(filepath.Join(t.TempDir(), "tg.db"))
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
		{ID: 2, WorkspaceID: 1, Name: "Payments", Active: true, Billable: true},
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
	if err := cmdStart(&buf, s, nil, 1, nil, "login", testStart); err != nil {
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

// TestStartPushesRunningEntryWithTaskID verifies that when a client is
// supplied, `start` immediately POSTs the running entry to Toggl carrying its
// task_id (so the web app shows it running against the right task), and that
// the pushed entry is marked synced locally.
func TestStartPushesRunningEntryWithTaskID(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var body map[string]any
	var gotMethod string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotMethod = r.Method
		raw, _ := io.ReadAll(r.Body)
		json.Unmarshal(raw, &body)
		w.Write([]byte(`{"id":9001,"at":"2026-01-02T09:00:00Z"}`))
	}))
	defer srv.Close()
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))

	var buf bytes.Buffer
	if err := cmdStart(&buf, s, c, 1, nil, "login", testStart); err != nil {
		t.Fatalf("start: %v", err)
	}
	if gotMethod != http.MethodPost {
		t.Errorf("method = %s, want POST", gotMethod)
	}
	// The running entry must be pushed with its task_id set (JSON numbers
	// decode to float64).
	if v, ok := body["task_id"].(float64); !ok || int64(v) != 10 {
		t.Errorf("task_id = %v, want 10", body["task_id"])
	}
	if v, ok := body["project_id"].(float64); !ok || int64(v) != 1 {
		t.Errorf("project_id = %v, want 1", body["project_id"])
	}
	if v, ok := body["duration"].(float64); !ok || int64(v) != -1 {
		t.Errorf("duration = %v, want -1 (running)", body["duration"])
	}

	// The pushed entry is marked synced locally (remote id set, clean).
	r, _ := s.EntryByRemoteID(9001)
	if r == nil {
		t.Fatal("expected the running entry to be synced with its remote id")
	}
	if r.Dirty {
		t.Error("running entry should be clean after a successful push")
	}
	if r.TaskID == nil || *r.TaskID != 10 {
		t.Errorf("task_id = %v, want 10", r.TaskID)
	}
}

// TestStartSyncFailureIsNonFatal verifies a push failure on start does not fail
// the command: the running entry is still created locally (dirty) for a later
// `tg push`, and a warning is surfaced.
func TestStartSyncFailureIsNonFatal(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer srv.Close()
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))

	var buf bytes.Buffer
	if err := cmdStart(&buf, s, c, 1, nil, "login", testStart); err != nil {
		t.Fatalf("start should not fail on a sync error: %v", err)
	}
	if !strings.Contains(buf.String(), "warning") {
		t.Errorf("output = %q, want a sync warning", buf.String())
	}
	r, _ := s.Running()
	if r == nil {
		t.Fatal("expected a running entry despite the sync failure")
	}
	if !r.Dirty {
		t.Error("running entry should stay dirty for a later push")
	}
	if r.RemoteID != nil {
		t.Errorf("remote_id = %v, want nil (never synced)", r.RemoteID)
	}
}

func TestStartAutoStops(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	if err := cmdStart(&buf, s, nil, 1, nil, "login", testStart); err != nil {
		t.Fatalf("first start: %v", err)
	}
	second := testStart.Add(30 * time.Minute)
	if err := cmdStart(&buf, s, nil, 1, nil, "review", second); err != nil {
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
	if err := cmdStart(&buf, s, nil, 1, nil, "Fix", testStart); err != nil {
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
	err := cmdStart(&buf, s, nil, 1, nil, "write", testStart)
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
	err := cmdStart(&buf, s, nil, 1, nil, "nonexistent", testStart)
	if err == nil || !strings.Contains(err.Error(), "tg update") {
		t.Errorf("error = %v, want suggestion to run `tg update`", err)
	}
}

func TestStartProjectScope(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	pid := int64(2)
	var buf bytes.Buffer
	// "fix" matches several tasks, but scoping to project 2 leaves only one.
	if err := cmdStart(&buf, s, nil, 1, &pid, "fix", testStart); err != nil {
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

func TestStartCarriesProjectBillable(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	// A task in the billable project (Payments, id 2) must produce a billable
	// entry so the workspace accepts it.
	pid := int64(2)
	var buf bytes.Buffer
	if err := cmdStart(&buf, s, nil, 1, &pid, "fix", testStart); err != nil {
		t.Fatalf("start billable: %v", err)
	}
	r, _ := s.Running()
	if r == nil || !r.Billable {
		t.Fatalf("running entry = %+v, want Billable=true", r)
	}
}

func TestStartNonBillableProject(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	// A task in a non-billable project (Backend, id 1) stays non-billable.
	var buf bytes.Buffer
	if err := cmdStart(&buf, s, nil, 1, nil, "login", testStart); err != nil {
		t.Fatalf("start: %v", err)
	}
	r, _ := s.Running()
	if r == nil || r.Billable {
		t.Fatalf("running entry = %+v, want Billable=false", r)
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

func TestStopSnaps(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	if err := cmdStart(&buf, s, nil, 1, nil, "login", testStart); err != nil {
		t.Fatalf("start: %v", err)
	}

	var stopBuf bytes.Buffer
	now := testStart.Add(46 * time.Minute) // 09:46 -> snaps back to 09:45
	if err := cmdStop(&stopBuf, s, now); err != nil {
		t.Fatalf("stop: %v", err)
	}
	if !strings.Contains(stopBuf.String(), "0h45m") {
		t.Errorf("stop output = %q, want 0h45m", stopBuf.String())
	}

	entries, _ := s.EntriesBetween(testStart.Add(-time.Hour), testStart.Add(24*time.Hour))
	if len(entries) != 1 {
		t.Fatalf("entries = %d, want 1", len(entries))
	}
	e := entries[0]
	if e.Duration != 2700 {
		t.Errorf("duration = %d, want 2700", e.Duration)
	}
	wantStop := testStart.Add(45 * time.Minute)
	if e.Stop == nil || !e.Stop.Equal(wantStop) {
		t.Errorf("stop = %v, want %v", e.Stop, wantStop)
	}
}

// TestStartSnapsStart verifies the entry's start time is snapped to the nearest
// 5-minute wall-clock mark at creation.
func TestStartSnapsStart(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	// 09:03 should snap up to 09:05.
	start := time.Date(2026, 1, 2, 9, 3, 0, 0, time.UTC)
	if err := cmdStart(&buf, s, nil, 1, nil, "login", start); err != nil {
		t.Fatalf("start: %v", err)
	}
	r, _ := s.Running()
	want := time.Date(2026, 1, 2, 9, 5, 0, 0, time.UTC)
	if r == nil || !r.Start.Equal(want) {
		t.Fatalf("start = %v, want %v", r.Start, want)
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

func TestTasksCommand(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	if err := cmdTasks(&buf, s, false, nil, false); err != nil {
		t.Fatalf("tasks: %v", err)
	}
	out := buf.String()
	for _, want := range []string{"Fix login bug", "Code review", "Payment fix", "[Backend]", "[Payments]"} {
		if !strings.Contains(out, want) {
			t.Errorf("tasks output missing %q:\n%s", want, out)
		}
	}
}

func TestTasksCommandAllIncludesInactive(t *testing.T) {
	s := newStore(t)
	if err := s.ReplaceProjects([]store.Project{{ID: 1, WorkspaceID: 1, Name: "Backend", Active: true}}); err != nil {
		t.Fatal(err)
	}
	if err := s.ReplaceTasks([]store.Task{
		{ID: 10, WorkspaceID: 1, ProjectID: 1, Name: "Active task", Active: true},
		{ID: 11, WorkspaceID: 1, ProjectID: 1, Name: "Retired task", Active: false},
	}); err != nil {
		t.Fatal(err)
	}

	var active bytes.Buffer
	if err := cmdTasks(&active, s, false, nil, false); err != nil {
		t.Fatalf("tasks: %v", err)
	}
	if strings.Contains(active.String(), "Retired task") {
		t.Errorf("active-only listing should hide inactive tasks:\n%s", active.String())
	}

	var all bytes.Buffer
	if err := cmdTasks(&all, s, true, nil, false); err != nil {
		t.Fatalf("tasks --all: %v", err)
	}
	if !strings.Contains(all.String(), "Retired task") {
		t.Errorf("--all listing should include inactive tasks:\n%s", all.String())
	}
}

func TestTasksCommandProjectScope(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	pid := int64(2) // Payments
	var buf bytes.Buffer
	if err := cmdTasks(&buf, s, false, &pid, false); err != nil {
		t.Fatalf("tasks: %v", err)
	}
	out := buf.String()
	if !strings.Contains(out, "Payment fix") {
		t.Errorf("scoped tasks should list Payment fix:\n%s", out)
	}
	for _, hidden := range []string{"Fix login bug", "Code review", "Write tests"} {
		if strings.Contains(out, hidden) {
			t.Errorf("scoped tasks should hide %q:\n%s", hidden, out)
		}
	}
}

func TestResolvePullProjectRequiresFragment(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	// pull ignores TOGGL_PROJECT_ID, so a blank argument is a hard error that
	// must NOT suggest the env var as a fallback.
	_, err := resolvePullProject(s, "  ")
	if err == nil || !strings.Contains(err.Error(), "project-name argument") {
		t.Errorf("err = %v, want a required-argument error", err)
	}
	if strings.Contains(err.Error(), "TOGGL_PROJECT_ID") {
		t.Errorf("err = %v, should not mention TOGGL_PROJECT_ID (pull ignores it)", err)
	}
}

func TestResolvePullProjectUnique(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	got, err := resolvePullProject(s, "back")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if got == nil || *got != 1 {
		t.Errorf("resolved = %v, want project 1 (Backend)", got)
	}
}

func TestResolvePullProjectAmbiguous(t *testing.T) {
	s := newStore(t)
	if err := s.ReplaceProjects([]store.Project{
		{ID: 1, WorkspaceID: 1, Name: "Backend", Active: true},
		{ID: 2, WorkspaceID: 1, Name: "Back office", Active: true},
	}); err != nil {
		t.Fatal(err)
	}

	_, err := resolvePullProject(s, "back")
	if err == nil {
		t.Fatal("expected ambiguity error")
	}
	if !strings.Contains(err.Error(), "Backend") || !strings.Contains(err.Error(), "Back office") {
		t.Errorf("error should list candidates: %v", err)
	}
}

func TestResolvePullProjectNone(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	_, err := resolvePullProject(s, "nonexistent")
	if err == nil || !strings.Contains(err.Error(), "tg update") {
		t.Errorf("err = %v, want suggestion to run `tg update`", err)
	}
}

func TestResolvePullScopeUnscopedMeansAll(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	// A blank argument means "pull every project": nil scope.
	got, err := resolvePullScope(s, "   ")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if got != nil {
		t.Errorf("resolved = %v, want nil (pull all projects)", got)
	}
}

// TestResolvePullScopeIgnoresEnv verifies pull's scope resolution never falls
// back to TOGGL_PROJECT_ID: with the env set but no argument, the scope is nil
// (all projects), unlike the env-honoring resolvers for start/update.
func TestResolvePullScopeIgnoresEnv(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	t.Setenv("TOGGL_PROJECT_ID", "2")
	got, err := resolvePullScope(s, "")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if got != nil {
		t.Errorf("resolved = %v, want nil (pull ignores TOGGL_PROJECT_ID)", got)
	}
}

func TestResolvePullScopeFragment(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	got, err := resolvePullScope(s, "pay")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if got == nil || *got != 2 {
		t.Errorf("resolved = %v, want 2 (Payments)", got)
	}
}

// TestPullAllProjectsUnscoped verifies `tg pull` with no project scope
// reconciles entries from every project in one pass and advances last_pull.
func TestPullAllProjectsUnscoped(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[
		  {"id":1,"workspace_id":1,"project_id":1,"description":"a",
		   "start":"2026-01-02T09:00:00Z","stop":"2026-01-02T09:30:00Z",
		   "duration":1800,"at":"2026-01-02T09:30:00Z"},
		  {"id":2,"workspace_id":1,"project_id":2,"description":"b",
		   "start":"2026-01-02T10:00:00Z","stop":"2026-01-02T10:30:00Z",
		   "duration":1800,"at":"2026-01-02T10:30:00Z"}]`))
	}))
	defer srv.Close()
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))

	since := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	now := time.Date(2026, 1, 2, 12, 0, 0, 0, time.UTC)
	var buf bytes.Buffer
	// empty argument => pull every project.
	if err := cmdPull(&buf, s, c, "", since, now, false); err != nil {
		t.Fatalf("pull: %v", err)
	}
	if !strings.Contains(buf.String(), "2 inserted") {
		t.Errorf("output = %q, want 2 inserted", buf.String())
	}
	if got, _ := s.EntryByRemoteID(1); got == nil {
		t.Error("project 1 entry should be inserted")
	}
	if got, _ := s.EntryByRemoteID(2); got == nil {
		t.Error("project 2 entry should be inserted")
	}
	// A full (unscoped) pull advances the watermark.
	if _, ok, _ := s.GetMeta(store.MetaLastPull); !ok {
		t.Error("unscoped pull should advance last_pull")
	}
}

// TestPullScopedByFragment verifies a fragment still scopes the pull to one
// project (backwards compatible) and leaves the watermark untouched.
func TestPullScopedByFragment(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[
		  {"id":1,"workspace_id":1,"project_id":1,"description":"backend",
		   "start":"2026-01-02T09:00:00Z","stop":"2026-01-02T09:30:00Z",
		   "duration":1800,"at":"2026-01-02T09:30:00Z"},
		  {"id":2,"workspace_id":1,"project_id":2,"description":"payments",
		   "start":"2026-01-02T10:00:00Z","stop":"2026-01-02T10:30:00Z",
		   "duration":1800,"at":"2026-01-02T10:30:00Z"}]`))
	}))
	defer srv.Close()
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))

	since := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	now := time.Date(2026, 1, 2, 12, 0, 0, 0, time.UTC)
	var buf bytes.Buffer
	// "back" resolves to Backend (project 1); only its entry is reconciled.
	if err := cmdPull(&buf, s, c, "back", since, now, false); err != nil {
		t.Fatalf("pull: %v", err)
	}
	if got, _ := s.EntryByRemoteID(1); got == nil {
		t.Error("backend entry should be inserted")
	}
	if got, _ := s.EntryByRemoteID(2); got != nil {
		t.Error("payments entry should be ignored under a backend-scoped pull")
	}
	// A scoped pull is partial and must not advance the watermark.
	if _, ok, _ := s.GetMeta(store.MetaLastPull); ok {
		t.Error("scoped pull should not advance last_pull")
	}
}

// TestPullIgnoresProjectEnv verifies `tg pull` reconciles entries from EVERY
// project even when TOGGL_PROJECT_ID is set. Unlike start/tasks/update, pull
// deliberately ignores the env project and spans the whole workspace, so an
// entry belonging to a project other than the env one is still pulled and the
// last_pull watermark advances (a full pull).
func TestPullIgnoresProjectEnv(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	// Scope the env to a single project; pull must NOT honor it.
	t.Setenv("TOGGL_PROJECT_ID", "1")

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[
		  {"id":1,"workspace_id":1,"project_id":1,"description":"a",
		   "start":"2026-01-02T09:00:00Z","stop":"2026-01-02T09:30:00Z",
		   "duration":1800,"at":"2026-01-02T09:30:00Z"},
		  {"id":2,"workspace_id":1,"project_id":2,"description":"b",
		   "start":"2026-01-02T10:00:00Z","stop":"2026-01-02T10:30:00Z",
		   "duration":1800,"at":"2026-01-02T10:30:00Z"}]`))
	}))
	defer srv.Close()
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))

	since := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	now := time.Date(2026, 1, 2, 12, 0, 0, 0, time.UTC)
	var buf bytes.Buffer
	if err := cmdPull(&buf, s, c, "", since, now, false); err != nil {
		t.Fatalf("pull: %v", err)
	}
	if !strings.Contains(buf.String(), "2 inserted") {
		t.Errorf("output = %q, want 2 inserted (all projects)", buf.String())
	}
	// The env project's entry is pulled...
	if got, _ := s.EntryByRemoteID(1); got == nil {
		t.Error("project 1 entry should be inserted")
	}
	// ...and so is the entry for a project other than TOGGL_PROJECT_ID.
	if got, _ := s.EntryByRemoteID(2); got == nil {
		t.Error("project 2 entry should be inserted despite TOGGL_PROJECT_ID=1")
	}
	// Ignoring the env means this is a full pull: the watermark advances.
	if _, ok, _ := s.GetMeta(store.MetaLastPull); !ok {
		t.Error("pull ignoring env should be a full pull and advance last_pull")
	}
}

func TestResolveStartProjectUnique(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	got, err := resolveStartProject(s, "pay")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if got == nil || *got != 2 {
		t.Errorf("resolved = %v, want project 2 (Payments)", got)
	}
}

func TestResolveStartProjectNone(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	_, err := resolveStartProject(s, "nonexistent")
	if err == nil || !strings.Contains(err.Error(), "tg update") {
		t.Errorf("err = %v, want suggestion to run `tg update`", err)
	}
}

func TestResolveUpdateProjectEnvWins(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	pid := int64(2)
	got, err := resolveUpdateProject(s, &pid, "backend")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if got == nil || *got != 2 {
		t.Errorf("resolved = %v, want 2 (env wins)", got)
	}
}

func TestResolveUpdateProjectRequiresScope(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	_, err := resolveUpdateProject(s, nil, "  ")
	if err == nil || !strings.Contains(err.Error(), "TOGGL_PROJECT_ID") {
		t.Errorf("err = %v, want required-argument error mentioning TOGGL_PROJECT_ID", err)
	}
}

// TestUpdateScopedToOneProject verifies update fetches only the selected
// project's metadata and tasks (never the whole workspace) and upserts them
// without wiping other projects' cached tasks.
func TestUpdateScopedToOneProject(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var paths []string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		paths = append(paths, r.URL.Path)
		switch r.URL.Path {
		case "/workspaces/1/projects/2":
			w.Write([]byte(`{"id":2,"workspace_id":1,"name":"Payments","billable":true,"active":true}`))
		case "/workspaces/1/projects/2/tasks":
			w.Write([]byte(`[{"id":21,"workspace_id":1,"project_id":2,"name":"New payment task","active":true}]`))
		default:
			t.Errorf("unexpected path %q (update must not sync all projects)", r.URL.Path)
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer srv.Close()
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))

	pid := int64(2)
	var buf bytes.Buffer
	if err := cmdUpdate(&buf, s, c, 1, &pid, "", false, false); err != nil {
		t.Fatalf("update: %v", err)
	}
	if !strings.Contains(buf.String(), "Payments") {
		t.Errorf("output = %q, want project name", buf.String())
	}

	// Only the single-project endpoints were hit.
	for _, p := range paths {
		if p != "/workspaces/1/projects/2" && p != "/workspaces/1/projects/2/tasks" {
			t.Errorf("unexpected request path %q", p)
		}
	}

	// Project 2's tasks were replaced with the fetched one...
	p2 := int64(2)
	scoped, _ := s.ListTasks(false, &p2)
	if len(scoped) != 1 || scoped[0].ID != 21 {
		t.Errorf("project 2 tasks = %+v, want only id 21", scoped)
	}
	// ...while project 1's cached tasks are untouched.
	p1 := int64(1)
	backend, _ := s.ListTasks(false, &p1)
	if len(backend) == 0 {
		t.Error("project 1 tasks should be untouched by a project-2 update")
	}
}

// TestUpdateProjectsSyncsWholeWorkspace verifies update-projects walks the
// entire workspace project list and upserts it (without wiping other cached
// projects) while never fetching tasks.
func TestUpdateProjectsSyncsWholeWorkspace(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var paths []string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		paths = append(paths, r.URL.Path)
		if r.URL.Path != "/workspaces/1/projects" {
			t.Errorf("unexpected path %q (update-projects must not fetch tasks)", r.URL.Path)
			w.WriteHeader(http.StatusNotFound)
			return
		}
		w.Write([]byte(`[{"id":2,"workspace_id":1,"name":"Payments","billable":true,"active":true},{"id":3,"workspace_id":1,"name":"Frontend","active":true}]`))
	}))
	defer srv.Close()
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))

	var buf bytes.Buffer
	if err := cmdUpdateProjects(&buf, s, c, 1, false, false); err != nil {
		t.Fatalf("update-projects: %v", err)
	}
	if !strings.Contains(buf.String(), "2 projects") {
		t.Errorf("output = %q, want project count", buf.String())
	}

	// Only the workspace projects endpoint was hit; tasks were never fetched.
	for _, p := range paths {
		if p != "/workspaces/1/projects" {
			t.Errorf("unexpected request path %q", p)
		}
	}

	// The fetched project was added and the pre-existing project 1 (Backend,
	// not in the response) is left untouched by the upsert.
	projects, _ := s.ListProjects(false)
	names := map[string]bool{}
	for _, p := range projects {
		names[p.Name] = true
	}
	for _, want := range []string{"Backend", "Payments", "Frontend"} {
		if !names[want] {
			t.Errorf("project %q missing after sync: %+v", want, projects)
		}
	}

	// Cached tasks are untouched: update-projects never syncs tasks.
	p1 := int64(1)
	backend, _ := s.ListTasks(false, &p1)
	if len(backend) == 0 {
		t.Error("project 1 tasks should be untouched by update-projects")
	}
}

func TestUpdateProjectsJSON(t *testing.T) {
	s := newStore(t)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[{"id":2,"workspace_id":1,"name":"Payments","active":true}]`))
	}))
	defer srv.Close()
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))

	var buf bytes.Buffer
	if err := cmdUpdateProjects(&buf, s, c, 1, false, true); err != nil {
		t.Fatalf("update-projects --json: %v", err)
	}
	if !strings.Contains(buf.String(), `"projects":1`) {
		t.Errorf("json output = %q, want projects count", buf.String())
	}
}

func TestProjectsCommand(t *testing.T) {
	s := newStore(t)
	seedCatalog(t, s)

	var buf bytes.Buffer
	if err := cmdProjects(&buf, s, false, false); err != nil {
		t.Fatalf("projects: %v", err)
	}
	out := buf.String()
	for _, want := range []string{"Backend", "Payments", "1", "2"} {
		if !strings.Contains(out, want) {
			t.Errorf("projects output missing %q:\n%s", want, out)
		}
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
	if err := cmdToday(&buf, s, now, loc, 1, false, false); err != nil {
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

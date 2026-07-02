package store

import (
	"path/filepath"
	"testing"
	"time"
)

func ptrInt(v int64) *int64 { return &v }

// ceil5 mirrors the production rounding so stop assertions are realistic.
func ceil5(d time.Duration) time.Duration {
	const s = 5 * time.Minute
	if d <= 0 {
		return s
	}
	return ((d + s - 1) / s) * s
}

func openTest(t *testing.T) *Store {
	t.Helper()
	s, err := Open(filepath.Join(t.TempDir(), "tgl.db"))
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	t.Cleanup(func() { s.Close() })
	return s
}

func mustCreate(t *testing.T, s *Store, e Entry) int64 {
	t.Helper()
	id, err := s.CreateEntry(e)
	if err != nil {
		t.Fatalf("create entry: %v", err)
	}
	return id
}

func TestMigrateIdempotent(t *testing.T) {
	s := openTest(t)
	// Re-running migrate must not error or wipe data.
	if err := s.migrate(); err != nil {
		t.Fatalf("second migrate: %v", err)
	}
	if v, ok, _ := s.GetMeta(MetaSchemaVersion); !ok || v != schemaVersion {
		t.Fatalf("schema_version = %q ok=%v, want %q", v, ok, schemaVersion)
	}
}

func TestStopRunningSetsFields(t *testing.T) {
	s := openTest(t)
	start := time.Date(2026, 1, 2, 9, 0, 0, 0, time.UTC)
	id := mustCreate(t, s, Entry{
		WorkspaceID: 1, TaskID: ptrInt(7), Start: start,
		Duration: -1, UpdatedAt: start, Dirty: true,
	})

	now := start.Add(46 * time.Minute)
	stopped, err := s.StopRunning(now, ceil5)
	if err != nil {
		t.Fatalf("stop: %v", err)
	}
	if stopped == nil || stopped.ID != id {
		t.Fatalf("stopped entry mismatch: %+v", stopped)
	}
	if stopped.Duration != int64((50 * time.Minute).Seconds()) {
		t.Errorf("duration = %d, want %d", stopped.Duration, int64((50 * time.Minute).Seconds()))
	}
	wantStop := start.Add(50 * time.Minute)
	if stopped.Stop == nil || !stopped.Stop.Equal(wantStop) {
		t.Errorf("stop = %v, want %v", stopped.Stop, wantStop)
	}
	if !stopped.Dirty {
		t.Error("entry should be dirty after stop")
	}
	if !stopped.UpdatedAt.Equal(now) {
		t.Errorf("updated_at = %v, want %v", stopped.UpdatedAt, now)
	}

	// No longer running.
	if r, _ := s.Running(); r != nil {
		t.Errorf("expected nothing running, got %+v", r)
	}
	// Stopping again is a no-op returning nil.
	if again, err := s.StopRunning(now, ceil5); err != nil || again != nil {
		t.Errorf("second stop: entry=%v err=%v", again, err)
	}
}

func TestStopRunningNothing(t *testing.T) {
	s := openTest(t)
	got, err := s.StopRunning(time.Now(), ceil5)
	if err != nil || got != nil {
		t.Fatalf("stop with nothing running: entry=%v err=%v", got, err)
	}
}

func TestSingleRunningInvariant(t *testing.T) {
	s := openTest(t)
	base := time.Date(2026, 1, 2, 8, 0, 0, 0, time.UTC)
	mustCreate(t, s, Entry{WorkspaceID: 1, Start: base, Duration: -1, UpdatedAt: base, Dirty: true})

	// Auto-stop before starting another, mirroring the start command.
	if _, err := s.StopRunning(base.Add(10*time.Minute), ceil5); err != nil {
		t.Fatalf("auto-stop: %v", err)
	}
	mustCreate(t, s, Entry{WorkspaceID: 1, Start: base.Add(10 * time.Minute), Duration: -1, UpdatedAt: base, Dirty: true})

	if r, _ := s.Running(); r == nil {
		t.Fatal("expected a running entry")
	}
	var n int
	if err := s.db.QueryRow("SELECT COUNT(*) FROM entries WHERE stop IS NULL AND deleted = 0").Scan(&n); err != nil {
		t.Fatalf("count: %v", err)
	}
	if n != 1 {
		t.Fatalf("running entries = %d, want 1", n)
	}
}

func TestEntriesBetweenOrdering(t *testing.T) {
	s := openTest(t)
	day := time.Date(2026, 1, 2, 0, 0, 0, 0, time.UTC)
	mk := func(h int) {
		st := day.Add(time.Duration(h) * time.Hour)
		mustCreate(t, s, Entry{WorkspaceID: 1, Start: st, Stop: ptrTime(st.Add(time.Hour)), Duration: 3600, UpdatedAt: st})
	}
	mk(11)
	mk(9)
	mk(14)
	// An entry outside the window must be excluded.
	mustCreate(t, s, Entry{WorkspaceID: 1, Start: day.Add(-2 * time.Hour), Duration: 3600, UpdatedAt: day})

	got, err := s.EntriesBetween(day, day.Add(24*time.Hour))
	if err != nil {
		t.Fatalf("between: %v", err)
	}
	if len(got) != 3 {
		t.Fatalf("entries = %d, want 3", len(got))
	}
	for i := 1; i < len(got); i++ {
		if got[i].Start.Before(got[i-1].Start) {
			t.Fatalf("entries not ordered by start: %v", got)
		}
	}
}

func TestDirtyEntriesAndMarkSynced(t *testing.T) {
	s := openTest(t)
	at := time.Date(2026, 1, 2, 9, 0, 0, 0, time.UTC)
	id := mustCreate(t, s, Entry{WorkspaceID: 1, Start: at, Duration: 3600, UpdatedAt: at, Dirty: true})

	dirty, err := s.DirtyEntries()
	if err != nil || len(dirty) != 1 {
		t.Fatalf("dirty = %v err=%v, want 1", dirty, err)
	}

	syncedAt := at.Add(time.Minute)
	if err := s.MarkSynced(id, 999, syncedAt); err != nil {
		t.Fatalf("mark synced: %v", err)
	}
	dirty, _ = s.DirtyEntries()
	if len(dirty) != 0 {
		t.Fatalf("dirty after sync = %d, want 0", len(dirty))
	}
	got, err := s.EntryByRemoteID(999)
	if err != nil || got == nil {
		t.Fatalf("by remote: %v err=%v", got, err)
	}
	if got.RemoteID == nil || *got.RemoteID != 999 {
		t.Errorf("remote_id = %v, want 999", got.RemoteID)
	}
	if got.SyncedAt == nil || !got.SyncedAt.Equal(syncedAt) {
		t.Errorf("synced_at = %v, want %v", got.SyncedAt, syncedAt)
	}
	if got.Dirty {
		t.Error("entry should be clean after MarkSynced")
	}
}

func TestCatalogFullReplace(t *testing.T) {
	s := openTest(t)
	if err := s.ReplaceProjects([]Project{{ID: 1, WorkspaceID: 1, Name: "Backend", Active: true}}); err != nil {
		t.Fatalf("replace projects: %v", err)
	}
	if err := s.ReplaceTasks([]Task{
		{ID: 10, WorkspaceID: 1, ProjectID: 1, Name: "Fix login bug", Active: true},
		{ID: 11, WorkspaceID: 1, ProjectID: 1, Name: "Old task", Active: true},
	}); err != nil {
		t.Fatalf("replace tasks: %v", err)
	}

	// Second replace must wipe the previous contents entirely.
	if err := s.ReplaceTasks([]Task{{ID: 12, WorkspaceID: 1, ProjectID: 1, Name: "Code review", Active: true}}); err != nil {
		t.Fatalf("replace tasks 2: %v", err)
	}
	all, err := s.activeTasks()
	if err != nil {
		t.Fatalf("active tasks: %v", err)
	}
	if len(all) != 1 || all[0].ID != 12 {
		t.Fatalf("tasks after replace = %+v, want only id 12", all)
	}
}

func TestFindTasksByFragment(t *testing.T) {
	s := openTest(t)
	tasks := []Task{
		{ID: 1, WorkspaceID: 1, ProjectID: 100, Name: "Fix login bug", Active: true},
		{ID: 2, WorkspaceID: 1, ProjectID: 100, Name: "Fix", Active: true},
		{ID: 3, WorkspaceID: 1, ProjectID: 200, Name: "Fix payment", Active: true},
		{ID: 4, WorkspaceID: 1, ProjectID: 100, Name: "Inactive fix", Active: false},
	}
	if err := s.ReplaceTasks(tasks); err != nil {
		t.Fatalf("replace: %v", err)
	}

	// Substring: matches across projects, excludes inactive, sorted by name.
	// "Fi" is a substring of every active "Fix…" task but exactly equals none.
	got, _ := s.FindTasksByFragment("Fi", nil)
	if names := taskNames(got); !equal(names, []string{"Fix", "Fix login bug", "Fix payment"}) {
		t.Fatalf("substring match = %v", names)
	}

	// Exact title precedence: "Fix" wins over the broader substrings.
	got, _ = s.FindTasksByFragment("Fix", nil)
	if names := taskNames(got); !equal(names, []string{"Fix"}) {
		t.Fatalf("exact match = %v", names)
	}

	// Project scoping restricts candidates.
	pid := int64(200)
	got, _ = s.FindTasksByFragment("fix", &pid)
	if names := taskNames(got); !equal(names, []string{"Fix payment"}) {
		t.Fatalf("scoped match = %v", names)
	}

	// No match.
	if got, _ := s.FindTasksByFragment("nonexistent", nil); len(got) != 0 {
		t.Fatalf("expected no matches, got %v", taskNames(got))
	}
}

func TestListProjects(t *testing.T) {
	s := openTest(t)
	if err := s.ReplaceProjects([]Project{
		{ID: 2, WorkspaceID: 1, Name: "Payments", Active: true},
		{ID: 1, WorkspaceID: 1, Name: "Backend", Active: true},
		{ID: 3, WorkspaceID: 1, Name: "Archived", Active: false},
	}); err != nil {
		t.Fatalf("replace projects: %v", err)
	}

	// Active-only, ordered by name.
	got, err := s.ListProjects(false)
	if err != nil {
		t.Fatalf("list projects: %v", err)
	}
	if len(got) != 2 || got[0].Name != "Backend" || got[1].Name != "Payments" {
		t.Fatalf("active projects = %+v, want [Backend Payments]", got)
	}

	// --all includes inactive.
	all, err := s.ListProjects(true)
	if err != nil {
		t.Fatalf("list projects --all: %v", err)
	}
	if len(all) != 3 || all[0].Name != "Archived" {
		t.Fatalf("all projects = %+v, want 3 incl. Archived", all)
	}
}

func TestListTasksProjectScope(t *testing.T) {
	s := openTest(t)
	if err := s.ReplaceProjects([]Project{
		{ID: 100, WorkspaceID: 1, Name: "Backend", Active: true},
		{ID: 200, WorkspaceID: 1, Name: "Payments", Active: true},
	}); err != nil {
		t.Fatalf("replace projects: %v", err)
	}
	if err := s.ReplaceTasks([]Task{
		{ID: 1, WorkspaceID: 1, ProjectID: 100, Name: "Fix login bug", Active: true},
		{ID: 2, WorkspaceID: 1, ProjectID: 100, Name: "Code review", Active: true},
		{ID: 3, WorkspaceID: 1, ProjectID: 200, Name: "Payment fix", Active: true},
	}); err != nil {
		t.Fatalf("replace tasks: %v", err)
	}

	// Unscoped: every active task.
	all, err := s.ListTasks(false, nil)
	if err != nil {
		t.Fatalf("list tasks: %v", err)
	}
	if len(all) != 3 {
		t.Fatalf("tasks = %d, want 3", len(all))
	}

	// Scoped to project 200: only its tasks.
	pid := int64(200)
	scoped, err := s.ListTasks(false, &pid)
	if err != nil {
		t.Fatalf("list tasks scoped: %v", err)
	}
	if len(scoped) != 1 || scoped[0].ID != 3 {
		t.Fatalf("scoped tasks = %+v, want only task 3 (Payment fix)", scoped)
	}
}

func TestFindProjectsByFragment(t *testing.T) {
	s := openTest(t)
	if err := s.ReplaceProjects([]Project{
		{ID: 1, WorkspaceID: 1, Name: "Backend", Active: true},
		{ID: 2, WorkspaceID: 1, Name: "Back office", Active: true},
		{ID: 3, WorkspaceID: 1, Name: "Payments", Active: true},
		{ID: 4, WorkspaceID: 1, Name: "Backup", Active: false},
	}); err != nil {
		t.Fatalf("replace projects: %v", err)
	}

	// Substring: matches active projects across the catalog, sorted by name,
	// excluding the inactive "Backup".
	got, _ := s.FindProjectsByFragment("back")
	if names := projectNames(got); !equal(names, []string{"Back office", "Backend"}) {
		t.Fatalf("substring match = %v", names)
	}

	// Exact full-name precedence over broader substrings.
	got, _ = s.FindProjectsByFragment("Backend")
	if names := projectNames(got); !equal(names, []string{"Backend"}) {
		t.Fatalf("exact match = %v", names)
	}

	// Unique fragment.
	got, _ = s.FindProjectsByFragment("pay")
	if len(got) != 1 || got[0].ID != 3 {
		t.Fatalf("unique match = %+v, want project 3", got)
	}

	// No match.
	if got, _ := s.FindProjectsByFragment("nonexistent"); len(got) != 0 {
		t.Fatalf("expected no matches, got %v", projectNames(got))
	}
}

func TestMetaRoundTrip(t *testing.T) {
	s := openTest(t)
	if _, ok, _ := s.GetMeta(MetaLastPull); ok {
		t.Fatal("last_pull should be absent initially")
	}
	if err := s.SetMeta(MetaLastPull, "2026-01-01T00:00:00Z"); err != nil {
		t.Fatalf("set: %v", err)
	}
	if err := s.SetMeta(MetaLastPull, "2026-02-01T00:00:00Z"); err != nil {
		t.Fatalf("update: %v", err)
	}
	v, ok, err := s.GetMeta(MetaLastPull)
	if err != nil || !ok || v != "2026-02-01T00:00:00Z" {
		t.Fatalf("get = %q ok=%v err=%v", v, ok, err)
	}
}

// --- helpers ---

func ptrTime(t time.Time) *time.Time { return &t }

func taskNames(tasks []Task) []string {
	out := make([]string, len(tasks))
	for i, t := range tasks {
		out[i] = t.Name
	}
	return out
}

func projectNames(projects []Project) []string {
	out := make([]string, len(projects))
	for i, p := range projects {
		out[i] = p.Name
	}
	return out
}

func equal(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

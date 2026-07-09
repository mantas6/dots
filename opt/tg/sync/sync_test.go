package sync

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"
	"time"

	"mantas6/tg/api"
	"mantas6/tg/store"
)

func ptrInt(v int64) *int64 { return &v }

func ts(s string) time.Time {
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		panic(err)
	}
	return t
}

func setup(t *testing.T, handler http.HandlerFunc) (*store.Store, *api.Client) {
	t.Helper()
	st, err := store.Open(filepath.Join(t.TempDir(), "tg.db"))
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	t.Cleanup(func() { st.Close() })

	srv := httptest.NewServer(handler)
	t.Cleanup(srv.Close)
	c := api.New("tok", api.WithBaseURL(srv.URL), api.WithHTTPClient(srv.Client()))
	return st, c
}

func TestPushCreate(t *testing.T) {
	var gotMethod string
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		gotMethod = r.Method
		w.Write([]byte(`{"id":555,"at":"2026-01-02T10:00:00Z"}`))
	})

	start := ts("2026-01-02T09:00:00Z")
	stop := start.Add(5 * time.Minute)
	id, _ := st.CreateEntry(store.Entry{
		WorkspaceID: 1, TaskID: ptrInt(7), Start: start, Stop: &stop,
		Duration: 300, UpdatedAt: stop, Dirty: true,
	})

	res, err := Push(st, c, time.Now())
	if err != nil {
		t.Fatalf("push: %v", err)
	}
	if gotMethod != http.MethodPost {
		t.Errorf("method = %s, want POST", gotMethod)
	}
	if res.Created != 1 {
		t.Errorf("created = %d, want 1", res.Created)
	}
	got, _ := st.EntryByRemoteID(555)
	if got == nil || got.ID != id || got.Dirty {
		t.Fatalf("after create: %+v", got)
	}
	if got.RemoteID == nil || *got.RemoteID != 555 {
		t.Errorf("remote_id = %v, want 555", got.RemoteID)
	}
}

func TestPushUpdate(t *testing.T) {
	var gotMethod, gotPath string
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		gotMethod, gotPath = r.Method, r.URL.Path
		w.Write([]byte(`{"id":555,"at":"2026-01-02T11:00:00Z"}`))
	})

	start := ts("2026-01-02T09:00:00Z")
	st.CreateEntry(store.Entry{
		RemoteID: ptrInt(555), WorkspaceID: 1, Start: start,
		Duration: 600, UpdatedAt: start.Add(time.Hour), Dirty: true,
	})

	res, err := Push(st, c, time.Now())
	if err != nil {
		t.Fatalf("push: %v", err)
	}
	if gotMethod != http.MethodPut || gotPath != "/workspaces/1/time_entries/555" {
		t.Errorf("update -> %s %s", gotMethod, gotPath)
	}
	if res.Updated != 1 {
		t.Errorf("updated = %d, want 1", res.Updated)
	}
}

func TestPushDelete(t *testing.T) {
	var gotMethod string
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		gotMethod = r.Method
		w.WriteHeader(http.StatusOK)
	})

	start := ts("2026-01-02T09:00:00Z")
	st.CreateEntry(store.Entry{
		RemoteID: ptrInt(777), WorkspaceID: 1, Start: start,
		Duration: 300, UpdatedAt: start, Dirty: true, Deleted: true,
	})

	res, err := Push(st, c, time.Now())
	if err != nil {
		t.Fatalf("push: %v", err)
	}
	if gotMethod != http.MethodDelete {
		t.Errorf("method = %s, want DELETE", gotMethod)
	}
	if res.Deleted != 1 {
		t.Errorf("deleted = %d, want 1", res.Deleted)
	}
	if got, _ := st.EntryByRemoteID(777); got != nil {
		t.Errorf("row should be gone, got %+v", got)
	}
}

func TestPushDeleteNeverPushed(t *testing.T) {
	called := false
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		called = true
		w.WriteHeader(http.StatusOK)
	})
	start := ts("2026-01-02T09:00:00Z")
	id, _ := st.CreateEntry(store.Entry{
		WorkspaceID: 1, Start: start, Duration: 300, UpdatedAt: start, Dirty: true, Deleted: true,
	})
	if _, err := Push(st, c, time.Now()); err != nil {
		t.Fatalf("push: %v", err)
	}
	if called {
		t.Error("should not call API for a never-pushed deletion")
	}
	if got, _ := st.EntryByRemoteID(0); got != nil {
		t.Error("row should be dropped")
	}
	// And the local row by id is gone.
	dirty, _ := st.DirtyEntries()
	for _, e := range dirty {
		if e.ID == id {
			t.Error("deleted row still present")
		}
	}
}

func TestPullInsert(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[{"id":900,"workspace_id":1,"description":"Imported",
		  "start":"2026-01-02T09:00:00Z","stop":"2026-01-02T09:30:00Z",
		  "duration":1800,"at":"2026-01-02T09:30:00Z"}]`))
	})
	now := ts("2026-01-02T12:00:00Z")
	res, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), now)
	if err != nil {
		t.Fatalf("pull: %v", err)
	}
	if res.Inserted != 1 {
		t.Errorf("inserted = %d, want 1", res.Inserted)
	}
	got, _ := st.EntryByRemoteID(900)
	if got == nil || got.Description != "Imported" || got.Dirty {
		t.Fatalf("inserted entry = %+v", got)
	}
}

func TestPullMapsBillable(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[{"id":910,"workspace_id":1,"description":"Billed",
		  "start":"2026-01-02T09:00:00Z","stop":"2026-01-02T09:30:00Z",
		  "duration":1800,"billable":true,"at":"2026-01-02T09:30:00Z"}]`))
	})
	if _, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), ts("2026-01-02T12:00:00Z")); err != nil {
		t.Fatalf("pull: %v", err)
	}
	got, _ := st.EntryByRemoteID(910)
	if got == nil || !got.Billable {
		t.Fatalf("entry = %+v, want Billable=true", got)
	}
}

func TestPushSendsBillable(t *testing.T) {
	var body map[string]any
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		raw, _ := io.ReadAll(r.Body)
		json.Unmarshal(raw, &body)
		w.Write([]byte(`{"id":556,"at":"2026-01-02T10:00:00Z"}`))
	})
	start := ts("2026-01-02T09:00:00Z")
	stop := start.Add(5 * time.Minute)
	st.CreateEntry(store.Entry{
		WorkspaceID: 1, ProjectID: ptrInt(3), Start: start, Stop: &stop,
		Duration: 300, Billable: true, UpdatedAt: stop, Dirty: true,
	})
	if _, err := Push(st, c, time.Now()); err != nil {
		t.Fatalf("push: %v", err)
	}
	if body["billable"] != true {
		t.Errorf("billable = %v, want true", body["billable"])
	}
}

func TestPullLWWRemoteNewer(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[{"id":900,"workspace_id":1,"description":"new",
		  "start":"2026-01-02T09:00:00Z","duration":-1,"at":"2026-01-02T10:00:00Z"}]`))
	})
	st.CreateEntry(store.Entry{
		RemoteID: ptrInt(900), WorkspaceID: 1, Description: "old",
		Start: ts("2026-01-02T09:00:00Z"), Duration: -1,
		UpdatedAt: ts("2026-01-02T09:00:00Z"), Dirty: false,
	})

	res, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), ts("2026-01-02T12:00:00Z"))
	if err != nil {
		t.Fatalf("pull: %v", err)
	}
	if res.Updated != 1 {
		t.Errorf("updated = %d, want 1", res.Updated)
	}
	got, _ := st.EntryByRemoteID(900)
	if got.Description != "new" {
		t.Errorf("description = %q, want new", got.Description)
	}
}

func TestPullLWWLocalNewer(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[{"id":901,"workspace_id":1,"description":"remote",
		  "start":"2026-01-02T09:00:00Z","duration":-1,"at":"2026-01-02T10:00:00Z"}]`))
	})
	st.CreateEntry(store.Entry{
		RemoteID: ptrInt(901), WorkspaceID: 1, Description: "local",
		Start: ts("2026-01-02T09:00:00Z"), Duration: -1,
		UpdatedAt: ts("2026-01-02T11:00:00Z"), Dirty: true,
	})

	res, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), ts("2026-01-02T12:00:00Z"))
	if err != nil {
		t.Fatalf("pull: %v", err)
	}
	if res.Skipped != 1 {
		t.Errorf("skipped = %d, want 1", res.Skipped)
	}
	got, _ := st.EntryByRemoteID(901)
	if got.Description != "local" {
		t.Errorf("description = %q, want local (kept)", got.Description)
	}
}

func TestPullRemoteDeleted(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[{"id":902,"workspace_id":1,"start":"2026-01-02T09:00:00Z",
		  "duration":300,"at":"2026-01-02T10:00:00Z","server_deleted_at":"2026-01-02T10:00:00Z"}]`))
	})
	st.CreateEntry(store.Entry{
		RemoteID: ptrInt(902), WorkspaceID: 1,
		Start: ts("2026-01-02T09:00:00Z"), Duration: 300,
		UpdatedAt: ts("2026-01-02T09:00:00Z"),
	})

	res, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), ts("2026-01-02T12:00:00Z"))
	if err != nil {
		t.Fatalf("pull: %v", err)
	}
	if res.Deleted != 1 {
		t.Errorf("deleted = %d, want 1", res.Deleted)
	}
	if got, _ := st.EntryByRemoteID(902); got != nil {
		t.Errorf("entry should be deleted, got %+v", got)
	}
}

func TestPullSkipsRemoteDeletedWithNoLocal(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[{"id":903,"workspace_id":1,"start":"2026-01-02T09:00:00Z",
		  "duration":300,"at":"2026-01-02T10:00:00Z","server_deleted_at":"2026-01-02T10:00:00Z"}]`))
	})
	res, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), ts("2026-01-02T12:00:00Z"))
	if err != nil {
		t.Fatalf("pull: %v", err)
	}
	if res.Inserted != 0 || res.Skipped != 1 {
		t.Errorf("res = %+v, want skipped deletion", res)
	}
}

// TestPullSelfHealsCatalog verifies that a pulled, task-based entry resolves
// its project/task titles via the catalog even when nothing was seeded, by
// self-healing from the meta=true names in the payload.
func TestPullSelfHealsCatalog(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[{"id":950,"workspace_id":1,"project_id":5,"task_id":7,
		  "project_name":"Backend","project_color":"#0B83D9",
		  "task_name":"Fix login bug","description":"",
		  "start":"2026-01-02T09:00:00Z","stop":"2026-01-02T09:30:00Z",
		  "duration":1800,"at":"2026-01-02T09:30:00Z"}]`))
	})

	if _, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), ts("2026-01-02T12:00:00Z")); err != nil {
		t.Fatalf("pull: %v", err)
	}

	entries, err := st.EntriesBetween(ts("2026-01-02T00:00:00Z"), ts("2026-01-03T00:00:00Z"))
	if err != nil {
		t.Fatalf("entries: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("entries = %d, want 1", len(entries))
	}
	if entries[0].TaskName != "Fix login bug" {
		t.Errorf("task name = %q, want %q", entries[0].TaskName, "Fix login bug")
	}
	if entries[0].ProjectName != "Backend" {
		t.Errorf("project name = %q, want %q", entries[0].ProjectName, "Backend")
	}
	// The meta=true project color is healed too, so `tg ls` renders its block.
	if entries[0].ProjectColor != "#0B83D9" {
		t.Errorf("project color = %q, want %q", entries[0].ProjectColor, "#0B83D9")
	}

	// And the healed task is discoverable for `start`.
	tasks, err := st.FindTasksByFragment("login", nil)
	if err != nil {
		t.Fatalf("find: %v", err)
	}
	if len(tasks) != 1 || tasks[0].ID != 7 {
		t.Errorf("FindTasksByFragment = %+v, want task 7", tasks)
	}
}

// TestPullProjectScope verifies a project-scoped pull only reconciles entries
// for that project and, being partial, does not advance the last_pull watermark.
func TestPullProjectScope(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[
		  {"id":1,"workspace_id":1,"project_id":5,"description":"mine",
		   "start":"2026-01-02T09:00:00Z","stop":"2026-01-02T09:30:00Z",
		   "duration":1800,"at":"2026-01-02T09:30:00Z"},
		  {"id":2,"workspace_id":1,"project_id":9,"description":"other",
		   "start":"2026-01-02T10:00:00Z","stop":"2026-01-02T10:30:00Z",
		   "duration":1800,"at":"2026-01-02T10:30:00Z"},
		  {"id":3,"workspace_id":1,"description":"noproject",
		   "start":"2026-01-02T11:00:00Z","stop":"2026-01-02T11:30:00Z",
		   "duration":1800,"at":"2026-01-02T11:30:00Z"}]`))
	})

	pid := int64(5)
	now := ts("2026-01-02T12:00:00Z")
	res, err := Pull(st, c, &pid, ts("2026-01-01T00:00:00Z"), now)
	if err != nil {
		t.Fatalf("pull: %v", err)
	}
	if res.Inserted != 1 {
		t.Errorf("inserted = %d, want 1 (only project 5)", res.Inserted)
	}
	if got, _ := st.EntryByRemoteID(1); got == nil {
		t.Error("entry for project 5 should have been inserted")
	}
	if got, _ := st.EntryByRemoteID(2); got != nil {
		t.Error("entry for other project should be ignored")
	}
	if got, _ := st.EntryByRemoteID(3); got != nil {
		t.Error("entry with no project should be ignored")
	}
	// A scoped pull is partial: the watermark must not advance.
	if _, ok, _ := st.GetMeta(store.MetaLastPull); ok {
		t.Error("scoped pull should not advance last_pull")
	}
}

func TestPullAdvancesLastPull(t *testing.T) {
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`[]`))
	})
	now := ts("2026-01-02T12:00:00Z")
	if _, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), now); err != nil {
		t.Fatalf("pull: %v", err)
	}
	v, ok, _ := st.GetMeta(store.MetaLastPull)
	if !ok || v != "2026-01-02T12:00:00Z" {
		t.Errorf("last_pull = %q ok=%v, want now", v, ok)
	}
}

// TestRoundTrip pushes a fresh local entry, then pulls the server's view of it
// back and asserts convergence (clean, single consistent row).
func TestRoundTrip(t *testing.T) {
	created := false
	st, c := setup(t, func(w http.ResponseWriter, r *http.Request) {
		switch {
		case r.Method == http.MethodPost:
			created = true
			w.Write([]byte(`{"id":1000,"at":"2026-01-02T10:00:00Z"}`))
		case r.Method == http.MethodGet:
			w.Write([]byte(`[{"id":1000,"workspace_id":1,"description":"",
			  "start":"2026-01-02T09:00:00Z","stop":"2026-01-02T09:05:00Z",
			  "duration":300,"at":"2026-01-02T10:00:00Z"}]`))
		default:
			t.Errorf("unexpected %s %s", r.Method, r.URL.Path)
		}
	})

	start := ts("2026-01-02T09:00:00Z")
	stop := start.Add(5 * time.Minute)
	st.CreateEntry(store.Entry{
		WorkspaceID: 1, Start: start, Stop: &stop, Duration: 300,
		UpdatedAt: stop, Dirty: true,
	})

	if _, err := Push(st, c, ts("2026-01-02T10:00:00Z")); err != nil {
		t.Fatalf("push: %v", err)
	}
	if !created {
		t.Fatal("expected a create call")
	}
	if _, err := Pull(st, c, nil, ts("2026-01-01T00:00:00Z"), ts("2026-01-02T12:00:00Z")); err != nil {
		t.Fatalf("pull: %v", err)
	}

	// Converged: exactly one clean entry mirroring remote 1000.
	dirty, _ := st.DirtyEntries()
	if len(dirty) != 0 {
		t.Errorf("dirty entries after round-trip = %d, want 0", len(dirty))
	}
	got, _ := st.EntryByRemoteID(1000)
	if got == nil || got.Duration != 300 {
		t.Fatalf("converged entry = %+v", got)
	}
}

package api

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

// newTestClient spins up an httptest.Server using handler and returns a Client
// pointed at it.
func newTestClient(t *testing.T, handler http.HandlerFunc) *Client {
	t.Helper()
	srv := httptest.NewServer(handler)
	t.Cleanup(srv.Close)
	return New("mytoken", WithBaseURL(srv.URL), WithHTTPClient(srv.Client()))
}

func ptrInt(v int64) *int64 { return &v }

func TestBasicAuthHeader(t *testing.T) {
	var gotAuth string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		gotAuth = r.Header.Get("Authorization")
		w.Write([]byte(`{}`))
	})
	if _, err := c.Me(); err != nil {
		t.Fatalf("Me: %v", err)
	}
	want := "Basic " + base64.StdEncoding.EncodeToString([]byte("mytoken:api_token"))
	if gotAuth != want {
		t.Errorf("Authorization = %q, want %q", gotAuth, want)
	}
}

func TestMeParsesDefaultWorkspace(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/me" {
			t.Errorf("path = %q, want /me", r.URL.Path)
		}
		w.Write([]byte(`{"id":99,"default_workspace_id":12345,"fullname":"A B"}`))
	})
	me, err := c.Me()
	if err != nil {
		t.Fatalf("Me: %v", err)
	}
	if me.DefaultWorkspaceID != 12345 {
		t.Errorf("default workspace = %d, want 12345", me.DefaultWorkspaceID)
	}
}

func TestCurrentHandlesNull(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/me/time_entries/current" {
			t.Errorf("path = %q", r.URL.Path)
		}
		w.Write([]byte(`null`))
	})
	te, err := c.Current()
	if err != nil {
		t.Fatalf("Current: %v", err)
	}
	if te != nil {
		t.Errorf("Current = %+v, want nil", te)
	}
}

func TestCurrentReturnsEntry(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`{"id":7,"workspace_id":1,"duration":-1,"start":"2026-01-02T09:00:00Z"}`))
	})
	te, err := c.Current()
	if err != nil {
		t.Fatalf("Current: %v", err)
	}
	if te == nil || te.ID != 7 {
		t.Fatalf("Current = %+v, want id 7", te)
	}
}

func TestListQuery(t *testing.T) {
	var gotQuery string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		gotQuery = r.URL.RawQuery
		w.Write([]byte(`[]`))
	})
	since := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	if _, err := c.List(since); err != nil {
		t.Fatalf("List: %v", err)
	}
	if !strings.Contains(gotQuery, fmt.Sprintf("since=%d", since.Unix())) {
		t.Errorf("query %q missing since=%d", gotQuery, since.Unix())
	}
	if !strings.Contains(gotQuery, "meta=true") {
		t.Errorf("query %q missing meta=true", gotQuery)
	}
}

func TestCreateBody(t *testing.T) {
	var body map[string]any
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			t.Errorf("method = %s, want POST", r.Method)
		}
		if r.URL.Path != "/workspaces/1/time_entries" {
			t.Errorf("path = %q", r.URL.Path)
		}
		raw, _ := io.ReadAll(r.Body)
		json.Unmarshal(raw, &body)
		w.Write([]byte(`{"id":555,"workspace_id":1,"at":"2026-01-02T09:00:00Z"}`))
	})

	out, err := c.Create(TimeEntry{
		WorkspaceID: 1, ProjectID: ptrInt(20), TaskID: ptrInt(30),
		Start: "2026-01-02T09:00:00Z", Duration: -1,
	})
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	if out.ID != 555 {
		t.Errorf("returned id = %d, want 555", out.ID)
	}
	if body["workspace_id"] != float64(1) {
		t.Errorf("workspace_id = %v", body["workspace_id"])
	}
	if body["start"] != "2026-01-02T09:00:00Z" {
		t.Errorf("start = %v", body["start"])
	}
	if body["duration"] != float64(-1) {
		t.Errorf("duration = %v, want -1", body["duration"])
	}
	if body["created_with"] != "tgl" {
		t.Errorf("created_with = %v, want tgl", body["created_with"])
	}
	if body["task_id"] != float64(30) {
		t.Errorf("task_id = %v, want 30", body["task_id"])
	}
	if body["project_id"] != float64(20) {
		t.Errorf("project_id = %v, want 20", body["project_id"])
	}
}

func TestUpdateMethodPath(t *testing.T) {
	var method, path string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		method, path = r.Method, r.URL.Path
		w.Write([]byte(`{"id":42}`))
	})
	if _, err := c.Update(TimeEntry{ID: 42, WorkspaceID: 1, Start: "2026-01-02T09:00:00Z", Duration: 300}); err != nil {
		t.Fatalf("Update: %v", err)
	}
	if method != http.MethodPut || path != "/workspaces/1/time_entries/42" {
		t.Errorf("Update -> %s %s, want PUT /workspaces/1/time_entries/42", method, path)
	}
}

func TestStopMethodPath(t *testing.T) {
	var method, path string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		method, path = r.Method, r.URL.Path
		w.Write([]byte(`{"id":42}`))
	})
	if _, err := c.Stop(1, 42); err != nil {
		t.Fatalf("Stop: %v", err)
	}
	if method != http.MethodPatch || path != "/workspaces/1/time_entries/42/stop" {
		t.Errorf("Stop -> %s %s, want PATCH .../42/stop", method, path)
	}
}

func TestDeleteMethodPath(t *testing.T) {
	var method, path string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		method, path = r.Method, r.URL.Path
		w.WriteHeader(http.StatusOK)
	})
	if err := c.Delete(1, 42); err != nil {
		t.Fatalf("Delete: %v", err)
	}
	if method != http.MethodDelete || path != "/workspaces/1/time_entries/42" {
		t.Errorf("Delete -> %s %s, want DELETE /workspaces/1/time_entries/42", method, path)
	}
}

func TestProjectsPagination(t *testing.T) {
	// First page returns a full batch (perPage items); second page is short,
	// terminating the loop.
	var pages []string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		pages = append(pages, r.URL.Query().Get("page"))
		if r.URL.Query().Get("active") != "true" {
			t.Errorf("active = %q, want true", r.URL.Query().Get("active"))
		}
		page := r.URL.Query().Get("page")
		w.Write([]byte(pageProjects(page)))
	})
	projects, err := c.Projects(1, false)
	if err != nil {
		t.Fatalf("Projects: %v", err)
	}
	if len(projects) != perPage+2 {
		t.Errorf("projects = %d, want %d", len(projects), perPage+2)
	}
	if len(pages) != 2 || pages[0] != "1" || pages[1] != "2" {
		t.Errorf("requested pages = %v, want [1 2]", pages)
	}
}

func TestTasksActiveBoth(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		if got := r.URL.Query().Get("active"); got != "both" {
			t.Errorf("active = %q, want both", got)
		}
		if r.URL.Path != "/workspaces/1/tasks" {
			t.Errorf("path = %q", r.URL.Path)
		}
		w.Write([]byte(`[{"id":1,"name":"T"}]`))
	})
	tasks, err := c.Tasks(1, true)
	if err != nil {
		t.Fatalf("Tasks: %v", err)
	}
	if len(tasks) != 1 {
		t.Errorf("tasks = %d, want 1", len(tasks))
	}
}

func TestErrorMapping(t *testing.T) {
	t.Run("forbidden", func(t *testing.T) {
		c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusForbidden)
		})
		if _, err := c.Me(); !errors.Is(err, ErrUnauthorized) {
			t.Errorf("err = %v, want ErrUnauthorized", err)
		}
	})
	t.Run("server error", func(t *testing.T) {
		c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(`{"error":"boom"}`))
		})
		_, err := c.Me()
		if err == nil || !strings.Contains(err.Error(), "500") {
			t.Errorf("err = %v, want status 500", err)
		}
	})
	t.Run("non-json body", func(t *testing.T) {
		c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusBadGateway)
			w.Write([]byte(`<html>down</html>`))
		})
		_, err := c.Me()
		if err == nil || !strings.Contains(err.Error(), "down") {
			t.Errorf("err = %v, want body text", err)
		}
	})
}

// pageProjects renders page 1 as a full batch and page 2 as a short final page.
func pageProjects(page string) string {
	var items []string
	switch page {
	case "1":
		for i := 0; i < perPage; i++ {
			items = append(items, fmt.Sprintf(`{"id":%d,"name":"P%d","active":true}`, i+1, i+1))
		}
	case "2":
		items = []string{`{"id":1001,"name":"X","active":true}`, `{"id":1002,"name":"Y","active":true}`}
	}
	return "[" + strings.Join(items, ",") + "]"
}

package api

// Me is the subset of GET /me we rely on.
type Me struct {
	ID                 int64  `json:"id"`
	DefaultWorkspaceID int64  `json:"default_workspace_id"`
	Fullname           string `json:"fullname"`
	Email              string `json:"email"`
}

// TimeEntry mirrors a Toggl time entry. Start/Stop/At are RFC3339 strings as
// returned by the API. A non-nil ServerDeletedAt marks a remote deletion (only
// surfaced by since-based listing). ProjectName/TaskName are only populated
// when the entry is fetched with meta=true (see List) and let a pull self-heal
// the local catalog so titles render even before a full catalog update.
type TimeEntry struct {
	ID              int64   `json:"id"`
	WorkspaceID     int64   `json:"workspace_id"`
	ProjectID       *int64  `json:"project_id"`
	TaskID          *int64  `json:"task_id"`
	Description     string  `json:"description"`
	Start           string  `json:"start"`
	Stop            *string `json:"stop"`
	Duration        int64   `json:"duration"`
	At              string  `json:"at"`
	ServerDeletedAt *string `json:"server_deleted_at"`

	ProjectName string `json:"project_name"` // meta=true only
	TaskName    string `json:"task_name"`    // meta=true only
}

// Deleted reports whether the remote entry has been deleted.
func (t TimeEntry) Deleted() bool { return t.ServerDeletedAt != nil }

// Project mirrors a Toggl project.
type Project struct {
	ID          int64  `json:"id"`
	WorkspaceID int64  `json:"workspace_id"`
	Name        string `json:"name"`
	Color       string `json:"color"`
	ClientName  string `json:"client_name"`
	Active      bool   `json:"active"`
	At          string `json:"at"`
}

// Task mirrors a Toggl task (a paid Toggl Track feature).
type Task struct {
	ID          int64  `json:"id"`
	WorkspaceID int64  `json:"workspace_id"`
	ProjectID   int64  `json:"project_id"`
	Name        string `json:"name"`
	Active      bool   `json:"active"`
	At          string `json:"at"`
}

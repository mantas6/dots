// Package store is the local-first persistence layer for tg. It wraps a
// SQLite database holding tracked time entries plus a read-only mirror of the
// Toggl task/project catalog. All times are stored as RFC3339 UTC strings;
// durations are integer seconds (-1 marks a running entry).
package store

import (
	"database/sql"
	"errors"
	"sort"
	"strings"
	"time"

	_ "modernc.org/sqlite"
)

// Meta keys persisted in the meta table.
const (
	MetaSchemaVersion = "schema_version"
	MetaLastPull      = "last_pull"
)

// Store is a handle to the SQLite database.
type Store struct {
	db *sql.DB
}

// Entry is a tracked time entry. RemoteID/ProjectID/TaskID/Stop/SyncedAt are
// nil when unset. TaskName and ProjectName are populated from a catalog join on
// read and are not persisted directly.
type Entry struct {
	ID          int64
	RemoteID    *int64
	WorkspaceID int64
	ProjectID   *int64
	TaskID      *int64
	Description string
	Start       time.Time
	Stop        *time.Time
	Duration    int64 // seconds; -1 while running
	Billable    bool
	UpdatedAt   time.Time
	SyncedAt    *time.Time
	Dirty       bool
	Deleted     bool

	TaskName     string // joined, display only
	ProjectName  string // joined, display only
	ProjectColor string // joined, display only; "#RRGGBB" hex
}

// Running reports whether the entry is currently running.
func (e Entry) Running() bool { return e.Duration < 0 || e.Stop == nil }

// Project mirrors a Toggl project. Billable is carried through to entries
// created against the project so workspaces that forbid non-billable entries in
// billable projects accept them.
type Project struct {
	ID          int64
	WorkspaceID int64
	Name        string
	Color       string
	ClientName  string
	Active      bool
	Billable    bool
	At          string
}

// Task mirrors a Toggl task. ProjectName is populated from a catalog join on
// read (display only) and is not persisted directly.
type Task struct {
	ID          int64
	WorkspaceID int64
	ProjectID   int64
	Name        string
	Active      bool
	At          string

	ProjectName string // joined, display only
}

// Open opens (creating if needed) the SQLite database at path and applies the
// schema. WAL + a busy timeout keep concurrent CLI invocations well behaved.
func Open(path string) (*Store, error) {
	dsn := path + "?_pragma=busy_timeout(5000)&_pragma=journal_mode(WAL)"
	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, err
	}
	s := &Store{db: db}
	if err := s.migrate(); err != nil {
		db.Close()
		return nil, err
	}
	return s, nil
}

// Close releases the underlying database handle.
func (s *Store) Close() error { return s.db.Close() }

// --- time helpers -----------------------------------------------------------

func fmtTime(t time.Time) string { return t.UTC().Format(time.RFC3339) }

func parseTime(s string) (time.Time, error) { return time.Parse(time.RFC3339, s) }

func nullTime(p *time.Time) any {
	if p == nil {
		return nil
	}
	return fmtTime(*p)
}

func nullInt(p *int64) any {
	if p == nil {
		return nil
	}
	return *p
}

// --- entry reads -------------------------------------------------------------

// entrySelect lists every entry column plus the joined task/project display
// fields (task name, project name and color).
const entrySelect = `
SELECT e.id, e.remote_id, e.workspace_id, e.project_id, e.task_id,
       e.description, e.start, e.stop, e.duration, e.billable, e.updated_at,
       e.synced_at, e.dirty, e.deleted, t.name, p.name, p.color
FROM entries e
LEFT JOIN tasks t ON t.id = e.task_id
LEFT JOIN projects p ON p.id = e.project_id
`

func scanEntry(sc interface{ Scan(...any) error }) (Entry, error) {
	var (
		e         Entry
		remoteID  sql.NullInt64
		projectID sql.NullInt64
		taskID    sql.NullInt64
		start     string
		stop      sql.NullString
		updatedAt string
		syncedAt  sql.NullString
		taskName  sql.NullString
		projName  sql.NullString
		projColor sql.NullString
	)
	if err := sc.Scan(&e.ID, &remoteID, &e.WorkspaceID, &projectID, &taskID,
		&e.Description, &start, &stop, &e.Duration, &e.Billable, &updatedAt, &syncedAt,
		&e.Dirty, &e.Deleted, &taskName, &projName, &projColor); err != nil {
		return Entry{}, err
	}
	if remoteID.Valid {
		e.RemoteID = &remoteID.Int64
	}
	if projectID.Valid {
		e.ProjectID = &projectID.Int64
	}
	if taskID.Valid {
		e.TaskID = &taskID.Int64
	}
	var err error
	if e.Start, err = parseTime(start); err != nil {
		return Entry{}, err
	}
	if stop.Valid {
		t, err := parseTime(stop.String)
		if err != nil {
			return Entry{}, err
		}
		e.Stop = &t
	}
	if e.UpdatedAt, err = parseTime(updatedAt); err != nil {
		return Entry{}, err
	}
	if syncedAt.Valid {
		t, err := parseTime(syncedAt.String)
		if err != nil {
			return Entry{}, err
		}
		e.SyncedAt = &t
	}
	e.TaskName = taskName.String
	e.ProjectName = projName.String
	e.ProjectColor = projColor.String
	return e, nil
}

// Running returns the single running entry (stop IS NULL, not deleted) or nil.
func (s *Store) Running() (*Entry, error) {
	row := s.db.QueryRow(entrySelect +
		" WHERE e.stop IS NULL AND e.deleted = 0 ORDER BY e.start DESC LIMIT 1")
	e, err := scanEntry(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &e, nil
}

// EntriesBetween returns non-deleted entries with start in [from, to), ordered
// by start ascending.
func (s *Store) EntriesBetween(from, to time.Time) ([]Entry, error) {
	rows, err := s.db.Query(entrySelect+
		" WHERE e.deleted = 0 AND e.start >= ? AND e.start < ? ORDER BY e.start ASC",
		fmtTime(from), fmtTime(to))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return collectEntries(rows)
}

// DirtyEntries returns every entry with unsynced local changes, oldest first.
func (s *Store) DirtyEntries() ([]Entry, error) {
	rows, err := s.db.Query(entrySelect + " WHERE e.dirty = 1 ORDER BY e.start ASC")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return collectEntries(rows)
}

// EntryByRemoteID returns the entry mirroring the given Toggl id, or nil.
func (s *Store) EntryByRemoteID(remoteID int64) (*Entry, error) {
	row := s.db.QueryRow(entrySelect+" WHERE e.remote_id = ?", remoteID)
	e, err := scanEntry(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &e, nil
}

func collectEntries(rows *sql.Rows) ([]Entry, error) {
	var out []Entry
	for rows.Next() {
		e, err := scanEntry(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

// --- entry writes ------------------------------------------------------------

// CreateEntry inserts a new entry and returns its local id. The caller sets all
// fields (Start/UpdatedAt/Dirty/Duration etc.); Duration -1 marks it running.
func (s *Store) CreateEntry(e Entry) (int64, error) {
	res, err := s.db.Exec(`
INSERT INTO entries
  (remote_id, workspace_id, project_id, task_id, description, start, stop,
   duration, billable, updated_at, synced_at, dirty, deleted)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		nullInt(e.RemoteID), e.WorkspaceID, nullInt(e.ProjectID), nullInt(e.TaskID),
		e.Description, fmtTime(e.Start), nullTime(e.Stop), e.Duration, boolToInt(e.Billable),
		fmtTime(e.UpdatedAt), nullTime(e.SyncedAt), boolToInt(e.Dirty), boolToInt(e.Deleted))
	if err != nil {
		return 0, err
	}
	return res.LastInsertId()
}

// StopRunning finalizes the running entry: both the start and the stop are
// snapped to 5-minute wall-clock marks (snap), duration = snappedStop -
// snappedStart, marking it dirty with updated_at = now. It returns the stopped
// entry, or nil if nothing was running. snap lets the caller inject the snapping
// policy (snap5) while keeping the field-setting logic here. When both ends snap
// to the same mark the entry is clamped to a single 5-minute block so a duration
// is never zero or negative.
func (s *Store) StopRunning(now time.Time, snap func(time.Time) time.Time) (*Entry, error) {
	e, err := s.Running()
	if err != nil || e == nil {
		return nil, err
	}
	start := snap(e.Start)
	stop := snap(now)
	if !stop.After(start) {
		stop = start.Add(5 * time.Minute)
	}
	secs := int64(stop.Sub(start) / time.Second)
	if _, err := s.db.Exec(`
UPDATE entries SET start = ?, stop = ?, duration = ?, dirty = 1, updated_at = ? WHERE id = ?`,
		fmtTime(start), fmtTime(stop), secs, fmtTime(now), e.ID); err != nil {
		return nil, err
	}
	e.Start = start
	e.Stop = &stop
	e.Duration = secs
	e.Dirty = true
	e.UpdatedAt = now
	return e, nil
}

// MarkSynced records a successful push: stores the remote id, clears dirty, and
// aligns updated_at/synced_at to the remote clock so a later pull is a no-op.
func (s *Store) MarkSynced(id, remoteID int64, at time.Time) error {
	_, err := s.db.Exec(`
UPDATE entries SET remote_id = ?, synced_at = ?, updated_at = ?, dirty = 0 WHERE id = ?`,
		remoteID, fmtTime(at), fmtTime(at), id)
	return err
}

// UpdateFromRemote overwrites a local entry with remote state (remote wins) and
// marks it clean, aligning the LWW clocks to the remote at.
func (s *Store) UpdateFromRemote(e Entry) error {
	_, err := s.db.Exec(`
UPDATE entries SET workspace_id = ?, project_id = ?, task_id = ?, description = ?,
  start = ?, stop = ?, duration = ?, billable = ?, updated_at = ?, synced_at = ?,
  dirty = 0, deleted = 0 WHERE remote_id = ?`,
		e.WorkspaceID, nullInt(e.ProjectID), nullInt(e.TaskID), e.Description,
		fmtTime(e.Start), nullTime(e.Stop), e.Duration, boolToInt(e.Billable),
		fmtTime(e.UpdatedAt), nullTime(e.SyncedAt), nullInt(e.RemoteID))
	return err
}

// DeleteRow hard-deletes a local row (used after a remote delete is confirmed).
func (s *Store) DeleteRow(id int64) error {
	_, err := s.db.Exec("DELETE FROM entries WHERE id = ?", id)
	return err
}

// DeleteByRemoteID hard-deletes the local mirror of a remote-deleted entry.
func (s *Store) DeleteByRemoteID(remoteID int64) error {
	_, err := s.db.Exec("DELETE FROM entries WHERE remote_id = ?", remoteID)
	return err
}

// --- catalog -----------------------------------------------------------------

// ReplaceProjects atomically replaces the entire projects mirror.
func (s *Store) ReplaceProjects(projects []Project) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.Exec("DELETE FROM projects"); err != nil {
		return err
	}
	for _, p := range projects {
		if _, err := tx.Exec(`
INSERT INTO projects (id, workspace_id, name, color, client_name, active, billable, at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
			p.ID, p.WorkspaceID, p.Name, p.Color, p.ClientName,
			boolToInt(p.Active), boolToInt(p.Billable), p.At); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// ReplaceProjectTasks atomically replaces the cached tasks of a single project,
// leaving every other project's tasks untouched. It backs the project-scoped
// `tg update`, which never refreshes the whole workspace.
func (s *Store) ReplaceProjectTasks(projectID int64, tasks []Task) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.Exec("DELETE FROM tasks WHERE project_id = ?", projectID); err != nil {
		return err
	}
	for _, t := range tasks {
		if _, err := tx.Exec(`
INSERT INTO tasks (id, workspace_id, project_id, name, active, at)
VALUES (?, ?, ?, ?, ?, ?)`,
			t.ID, t.WorkspaceID, t.ProjectID, t.Name, boolToInt(t.Active), t.At); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// ReplaceTasks atomically replaces the entire tasks mirror.
func (s *Store) ReplaceTasks(tasks []Task) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.Exec("DELETE FROM tasks"); err != nil {
		return err
	}
	for _, t := range tasks {
		if _, err := tx.Exec(`
INSERT INTO tasks (id, workspace_id, project_id, name, active, at)
VALUES (?, ?, ?, ?, ?, ?)`,
			t.ID, t.WorkspaceID, t.ProjectID, t.Name, boolToInt(t.Active), t.At); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// PutProject inserts or fully updates a single project row by id, refreshing
// every display and state field (name, color, client, active, billable, at).
// Unlike UpsertProject (which is a conservative self-heal from meta pulls),
// this is authoritative and backs the project-scoped `tg update`.
func (s *Store) PutProject(p Project) error {
	_, err := s.db.Exec(`
INSERT INTO projects (id, workspace_id, name, color, client_name, active, billable, at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  workspace_id = excluded.workspace_id, name = excluded.name, color = excluded.color,
  client_name = excluded.client_name, active = excluded.active,
  billable = excluded.billable, at = excluded.at`,
		p.ID, p.WorkspaceID, p.Name, p.Color, p.ClientName,
		boolToInt(p.Active), boolToInt(p.Billable), p.At)
	return err
}

// UpsertProject inserts or updates a single project row by id, refreshing the
// display fields. It is used to self-heal the catalog from meta-enriched pulls
// so entries always resolve a project name (and color), even before a full
// `tg update`. It deliberately leaves active/at untouched on conflict so an
// authoritative `tg update` is never downgraded. Color is only refreshed when a
// non-empty value is supplied, so a meta payload lacking a color never clobbers
// a color already stored by an authoritative update.
func (s *Store) UpsertProject(p Project) error {
	_, err := s.db.Exec(`
INSERT INTO projects (id, workspace_id, name, color, client_name, active, billable, at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  workspace_id = excluded.workspace_id, name = excluded.name,
  color = COALESCE(NULLIF(excluded.color, ''), color)`,
		p.ID, p.WorkspaceID, p.Name, p.Color, p.ClientName,
		boolToInt(p.Active), boolToInt(p.Billable), p.At)
	return err
}

// UpsertTask inserts or updates a single task row by id, refreshing the display
// fields (see UpsertProject for the rationale).
func (s *Store) UpsertTask(t Task) error {
	_, err := s.db.Exec(`
INSERT INTO tasks (id, workspace_id, project_id, name, active, at)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  workspace_id = excluded.workspace_id, project_id = excluded.project_id,
  name = excluded.name`,
		t.ID, t.WorkspaceID, t.ProjectID, t.Name, boolToInt(t.Active), t.At)
	return err
}

// activeTasks loads every active task for matching.
func (s *Store) activeTasks() ([]Task, error) {
	rows, err := s.db.Query(
		"SELECT id, workspace_id, project_id, name, active, at FROM tasks WHERE active = 1")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Task
	for rows.Next() {
		var t Task
		if err := rows.Scan(&t.ID, &t.WorkspaceID, &t.ProjectID, &t.Name, &t.Active, &t.At); err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	return out, rows.Err()
}

// ListProjects returns catalog projects for display, ordered by name. Inactive
// projects are included only when includeInactive is set.
func (s *Store) ListProjects(includeInactive bool) ([]Project, error) {
	q := `
SELECT id, workspace_id, name, COALESCE(color, ''), COALESCE(client_name, ''),
       active, billable, COALESCE(at, '')
FROM projects`
	if !includeInactive {
		q += "\nWHERE active = 1"
	}
	q += "\nORDER BY name"

	rows, err := s.db.Query(q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Project
	for rows.Next() {
		var p Project
		if err := rows.Scan(&p.ID, &p.WorkspaceID, &p.Name, &p.Color,
			&p.ClientName, &p.Active, &p.Billable, &p.At); err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

// ProjectByID returns the cached project with the given id, or nil if it is not
// in the local catalog (e.g. before `tg update`). It is used to carry a
// project's billable flag onto entries created against it.
func (s *Store) ProjectByID(id int64) (*Project, error) {
	row := s.db.QueryRow(`
SELECT id, workspace_id, name, COALESCE(color, ''), COALESCE(client_name, ''),
       active, billable, COALESCE(at, '')
FROM projects WHERE id = ?`, id)
	var p Project
	err := row.Scan(&p.ID, &p.WorkspaceID, &p.Name, &p.Color,
		&p.ClientName, &p.Active, &p.Billable, &p.At)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

// ListTasks returns catalog tasks for display, with the project name joined and
// ordered by project then task name. Inactive tasks are included only when
// includeInactive is set; a non-nil projectID scopes the listing to one project.
func (s *Store) ListTasks(includeInactive bool, projectID *int64) ([]Task, error) {
	q := `
SELECT t.id, t.workspace_id, t.project_id, t.name, t.active, COALESCE(t.at, ''),
       COALESCE(p.name, '')
FROM tasks t
LEFT JOIN projects p ON p.id = t.project_id`
	var conds []string
	var args []any
	if !includeInactive {
		conds = append(conds, "t.active = 1")
	}
	if projectID != nil {
		conds = append(conds, "t.project_id = ?")
		args = append(args, *projectID)
	}
	if len(conds) > 0 {
		q += "\nWHERE " + strings.Join(conds, " AND ")
	}
	q += "\nORDER BY p.name, t.name"

	rows, err := s.db.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Task
	for rows.Next() {
		var t Task
		if err := rows.Scan(&t.ID, &t.WorkspaceID, &t.ProjectID, &t.Name,
			&t.Active, &t.At, &t.ProjectName); err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	return out, rows.Err()
}

// FindTasksByFragment returns active tasks matching fragment (see matchTasks),
// optionally scoped to a project.
func (s *Store) FindTasksByFragment(fragment string, projectID *int64) ([]Task, error) {
	tasks, err := s.activeTasks()
	if err != nil {
		return nil, err
	}
	return matchTasks(tasks, fragment, projectID), nil
}

// FindProjectsByFragment returns active projects matching fragment (see
// matchProjects).
func (s *Store) FindProjectsByFragment(fragment string) ([]Project, error) {
	projects, err := s.ListProjects(false)
	if err != nil {
		return nil, err
	}
	return matchProjects(projects, fragment), nil
}

// matchProjects mirrors matchTasks for projects: a case-insensitive substring
// match on the project name, with an exact (case-insensitive) full-name match
// taking precedence over mere substrings. Results are sorted by name then id
// for stable candidate listings.
func matchProjects(projects []Project, fragment string) []Project {
	frag := strings.ToLower(strings.TrimSpace(fragment))
	if frag == "" {
		return nil
	}
	var subs, exact []Project
	for _, p := range projects {
		name := strings.ToLower(p.Name)
		if !strings.Contains(name, frag) {
			continue
		}
		subs = append(subs, p)
		if name == frag {
			exact = append(exact, p)
		}
	}
	res := subs
	if len(exact) > 0 {
		res = exact
	}
	sort.Slice(res, func(i, j int) bool {
		if res[i].Name != res[j].Name {
			return res[i].Name < res[j].Name
		}
		return res[i].ID < res[j].ID
	})
	return res
}

// matchTasks is a pure, deterministic matcher: case-insensitive substring on
// the task name, optionally scoped to projectID. An exact (case-insensitive)
// full-title match takes precedence over mere substring matches. Results are
// sorted by name then id for stable candidate listings.
func matchTasks(tasks []Task, fragment string, projectID *int64) []Task {
	frag := strings.ToLower(strings.TrimSpace(fragment))
	if frag == "" {
		return nil
	}
	var subs, exact []Task
	for _, t := range tasks {
		if projectID != nil && t.ProjectID != *projectID {
			continue
		}
		name := strings.ToLower(t.Name)
		if !strings.Contains(name, frag) {
			continue
		}
		subs = append(subs, t)
		if name == frag {
			exact = append(exact, t)
		}
	}
	res := subs
	if len(exact) > 0 {
		res = exact
	}
	sort.Slice(res, func(i, j int) bool {
		if res[i].Name != res[j].Name {
			return res[i].Name < res[j].Name
		}
		return res[i].ID < res[j].ID
	})
	return res
}

// --- meta --------------------------------------------------------------------

// GetMeta returns the value for key and whether it was present.
func (s *Store) GetMeta(key string) (string, bool, error) {
	var v string
	err := s.db.QueryRow("SELECT value FROM meta WHERE key = ?", key).Scan(&v)
	if errors.Is(err, sql.ErrNoRows) {
		return "", false, nil
	}
	if err != nil {
		return "", false, err
	}
	return v, true, nil
}

// SetMeta upserts a meta key/value pair.
func (s *Store) SetMeta(key, value string) error {
	_, err := s.db.Exec(
		"INSERT INTO meta (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
		key, value)
	return err
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

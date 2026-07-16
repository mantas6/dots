package main

import (
	"errors"
	"fmt"
	"io"
	"strings"
	"time"

	"mantas6/tg/api"
	"mantas6/tg/config"
	"mantas6/tg/store"
	"mantas6/tg/sync"
)

// cmdStart resolves a task-title fragment to a single task and starts tracking
// it: 1 match -> auto-stop the running entry and create a new running entry
// (empty description, task + project set); many -> error listing candidates;
// none -> error suggesting `tg update`. projectID scopes the candidates when
// set; it comes from TOGGL_PROJECT_ID or, for the 2-argument form
// (`tg start <project> <task>`), from the resolved project-name argument (see
// runStart / resolveStartProject).
//
// When c is non-nil the newly created running entry (and any just auto-stopped
// entry) is pushed to Toggl immediately so the entry shows as running in the
// web app with its task_id set, rather than waiting for a later `tg push`. The
// push is best-effort: a sync failure leaves the entries dirty (a warning is
// printed) so the local-first flow still works offline.
func cmdStart(w io.Writer, st *store.Store, c *api.Client, workspaceID int64, projectID *int64, fragment string, now time.Time) error {
	fragment = strings.TrimSpace(fragment)
	if fragment == "" {
		return errors.New("usage: tg start <task-fragment>")
	}

	tasks, err := st.FindTasksByFragment(fragment, projectID)
	if err != nil {
		return err
	}

	switch len(tasks) {
	case 0:
		return fmt.Errorf("no task matches %q; run `tg update` to refresh the catalog", fragment)
	case 1:
		task := tasks[0]
		if _, err := st.StopRunning(now, snap5); err != nil {
			return err
		}
		taskID := task.ID
		projID := task.ProjectID
		// Carry the project's billable flag onto the entry: workspaces can
		// reject non-billable entries in billable projects.
		billable, err := projectBillable(st, projID)
		if err != nil {
			return err
		}
		if _, err := st.CreateEntry(store.Entry{
			WorkspaceID: workspaceID,
			ProjectID:   &projID,
			TaskID:      &taskID,
			Description: "",
			Start:       snap5(now),
			Duration:    -1,
			Billable:    billable,
			UpdatedAt:   now,
			Dirty:       true,
		}); err != nil {
			return err
		}
		fmt.Fprintf(w, "Started: %s\n", task.Name)
		// Push the running entry (and any just auto-stopped entry) so Toggl
		// shows it as running with its task set. Best-effort: keep the local
		// entry dirty for a later `tg push` if the sync fails.
		if c != nil {
			if _, err := sync.Push(st, c, now); err != nil {
				fmt.Fprintf(w, "warning: could not sync to Toggl: %v\n", err)
			}
		}
		return nil
	default:
		return fmt.Errorf("multiple tasks match %q:\n%s", fragment, candidateList(tasks))
	}
}

// cmdStop finalizes the running entry (snapping start/end to the nearest
// 5-minute wall-clock mark).
func cmdStop(w io.Writer, st *store.Store, now time.Time) error {
	stopped, err := st.StopRunning(now, snap5)
	if err != nil {
		return err
	}
	if stopped == nil {
		fmt.Fprintln(w, "Nothing is running.")
		return nil
	}
	dur := time.Duration(stopped.Duration) * time.Second
	fmt.Fprintf(w, "Stopped: %s (%s)\n", entryLabel(*stopped), formatHM(dur))
	return nil
}

// cmdCurrent shows the running entry (or its absence).
func cmdCurrent(w io.Writer, st *store.Store, now time.Time, loc *time.Location, jsonOut bool) error {
	e, err := st.Running()
	if err != nil {
		return err
	}
	return renderCurrent(w, e, now, loc, jsonOut)
}

// cmdToday lists entries for the current day (or the last `days` days). color
// enables ANSI project-color blocks in the human output (never in JSON) and
// should reflect whether w is a terminal.
func cmdToday(w io.Writer, st *store.Store, now time.Time, loc *time.Location, days int, jsonOut, color bool) error {
	if days < 1 {
		days = 1
	}
	dayStart := startOfDay(now, loc)
	from := dayStart.AddDate(0, 0, -(days - 1))
	to := dayStart.Add(24 * time.Hour)

	entries, err := st.EntriesBetween(from, to)
	if err != nil {
		return err
	}
	if jsonOut {
		return renderTodayJSON(w, entries, now)
	}
	renderToday(w, entries, now, loc, color)
	return nil
}

// cmdTasks lists the locally cached task catalog. `--all` includes inactive
// tasks; a non-nil projectID (from TOGGL_PROJECT_ID) scopes the listing to one
// project. Refresh the cache with `tg update`.
func cmdTasks(w io.Writer, st *store.Store, all bool, projectID *int64, jsonOut bool) error {
	tasks, err := st.ListTasks(all, projectID)
	if err != nil {
		return err
	}
	if jsonOut {
		return renderTasksJSON(w, tasks)
	}
	renderTasks(w, tasks)
	return nil
}

// cmdProjects lists the locally cached project catalog with ids so the id can
// be exported as TOGGL_PROJECT_ID to scope other commands. `--all` includes
// inactive projects; refresh the cache with `tg update`.
func cmdProjects(w io.Writer, st *store.Store, all, jsonOut bool) error {
	projects, err := st.ListProjects(all)
	if err != nil {
		return err
	}
	if jsonOut {
		return renderProjectsJSON(w, projects)
	}
	renderProjects(w, projects)
	return nil
}

// cmdUpdate refreshes the cached catalog for a SINGLE project (never the whole
// workspace): its metadata plus its tasks are fetched and upserted. The project
// is chosen by projectID (from TOGGL_PROJECT_ID) when set; otherwise fragment
// must uniquely match a cached project name. Refreshing every project at once
// is intentionally disallowed (see resolveUpdateProject).
func cmdUpdate(w io.Writer, st *store.Store, c *api.Client, workspaceID int64, projectID *int64, fragment string, all, jsonOut bool) error {
	pid, err := resolveUpdateProject(st, projectID, fragment)
	if err != nil {
		return err
	}
	// Progress lines go to the same writer as the summary, but only in human
	// mode: suppressing them under --json keeps the JSON output clean.
	if !jsonOut {
		fmt.Fprintln(w, "Fetching project...")
	}
	project, err := c.Project(workspaceID, *pid)
	if err != nil {
		return err
	}
	if !jsonOut {
		fmt.Fprintln(w, "Fetching tasks...")
	}
	tasks, err := c.ProjectTasks(workspaceID, *pid, all)
	if err != nil {
		return err
	}
	if err := st.PutProject(toStoreProject(project)); err != nil {
		return err
	}
	if err := st.ReplaceProjectTasks(*pid, toStoreTasks(tasks)); err != nil {
		return err
	}

	if jsonOut {
		return writeJSON(w, map[string]any{"project": project.Name, "tasks": len(tasks)})
	}
	fmt.Fprintf(w, "Updated catalog for %s: %d tasks.\n", project.Name, len(tasks))
	return nil
}

// cmdUpdateProjects syncs the WHOLE workspace project catalog: every available
// project is fetched from Toggl and upserted into the local store. Unlike
// cmdUpdate (which is deliberately scoped to a single project), this walks the
// entire workspace, but it never fetches tasks — refresh a project's tasks with
// `tg update`. `--all` includes inactive projects.
func cmdUpdateProjects(w io.Writer, st *store.Store, c *api.Client, workspaceID int64, all, jsonOut bool) error {
	// Progress line goes to the writer only in human mode; under --json it is
	// suppressed so the JSON output stays clean (see cmdUpdate).
	if !jsonOut {
		fmt.Fprintln(w, "Fetching projects...")
	}
	projects, err := c.Projects(workspaceID, all)
	if err != nil {
		return err
	}
	for _, p := range projects {
		if err := st.PutProject(toStoreProject(p)); err != nil {
			return err
		}
	}
	if jsonOut {
		return writeJSON(w, map[string]any{"projects": len(projects)})
	}
	fmt.Fprintf(w, "Updated project catalog: %d projects.\n", len(projects))
	return nil
}

// cmdPush sends dirty local entries to Toggl.
func cmdPush(w io.Writer, st *store.Store, c *api.Client, now time.Time, jsonOut bool) error {
	res, err := sync.Push(st, c, now)
	if err != nil {
		return err
	}
	if jsonOut {
		return writeJSON(w, res)
	}
	fmt.Fprintf(w, "Pushed: %d created, %d updated, %d deleted.\n", res.Created, res.Updated, res.Deleted)
	return nil
}

// cmdPull reconciles remote entries into the local store (LWW). With no project
// scope (neither TOGGL_PROJECT_ID nor a project-name fragment) it pulls EVERY
// project's entries in a single pass and advances the last_pull watermark. When
// a project is given — via projectID (TOGGL_PROJECT_ID) or a fragment that
// uniquely matches a cached project name — the pull is scoped to that one
// project (and, being partial, leaves the watermark untouched).
func cmdPull(w io.Writer, st *store.Store, c *api.Client, projectID *int64, fragment string, since, now time.Time, jsonOut bool) error {
	pid, err := resolvePullScope(st, projectID, fragment)
	if err != nil {
		return err
	}
	res, err := sync.Pull(st, c, pid, since, now)
	if err != nil {
		return err
	}
	if jsonOut {
		return writeJSON(w, res)
	}
	fmt.Fprintf(w, "Pulled: %d inserted, %d updated, %d deleted, %d skipped.\n",
		res.Inserted, res.Updated, res.Deleted, res.Skipped)
	return nil
}

// resolveCachedProject resolves an optional env project id or a project-name
// fragment to exactly one cached project id. When projectID (TOGGL_PROJECT_ID)
// is non-nil it wins and fragment is ignored. Otherwise fragment is required
// (emptyErr is returned verbatim when it is blank) and must resolve to exactly
// one cached project: none -> error + noMatchHint; many -> error listing
// candidates. This is the shared machinery that keeps `start`, `pull`, and
// `update` scoped to a single project rather than the whole workspace.
func resolveCachedProject(st *store.Store, projectID *int64, fragment string, emptyErr error, noMatchHint string) (*int64, error) {
	if projectID != nil {
		return projectID, nil
	}
	fragment = strings.TrimSpace(fragment)
	if fragment == "" {
		return nil, emptyErr
	}
	projects, err := st.FindProjectsByFragment(fragment)
	if err != nil {
		return nil, err
	}
	switch len(projects) {
	case 0:
		return nil, fmt.Errorf("no project matches %q%s", fragment, noMatchHint)
	case 1:
		id := projects[0].ID
		return &id, nil
	default:
		return nil, fmt.Errorf("multiple projects match %q:\n%s", fragment, projectCandidateList(projects))
	}
}

// resolvePullScope decides which project(s) `tg pull` reconciles. A nil result
// means "all projects", which is the default when no scope is requested
// (neither TOGGL_PROJECT_ID nor a project-name fragment). Otherwise the pull is
// scoped to exactly one cached project (see resolvePullProject).
func resolvePullScope(st *store.Store, projectID *int64, fragment string) (*int64, error) {
	if projectID == nil && strings.TrimSpace(fragment) == "" {
		return nil, nil // no scope -> pull every project
	}
	return resolvePullProject(st, projectID, fragment)
}

// resolvePullProject resolves the single-project scope requested for `tg pull`
// (an env id or a project-name fragment); see resolveCachedProject. The
// unscoped "pull all projects" case is handled earlier by resolvePullScope.
func resolvePullProject(st *store.Store, projectID *int64, fragment string) (*int64, error) {
	return resolveCachedProject(st, projectID, fragment,
		errors.New("pull requires a project-name fragment (or set TOGGL_PROJECT_ID)"),
		"; run `tg update` to refresh the catalog")
}

// resolveUpdateProject decides which single project `tg update` refreshes. When
// TOGGL_PROJECT_ID is set it wins; otherwise the project-name argument must
// uniquely match a cached project. This keeps update from ever refreshing every
// project at once.
func resolveUpdateProject(st *store.Store, projectID *int64, fragment string) (*int64, error) {
	return resolveCachedProject(st, projectID, fragment,
		errors.New("update requires a project-name argument (or set TOGGL_PROJECT_ID)"),
		"; set TOGGL_PROJECT_ID to its id to update a project not yet cached")
}

// resolveStartProject resolves the project-name argument accepted by the 2-arg
// form of `tg start` (`tg start <project> <task>`) to exactly one cached
// project id, so the task search can be scoped to it.
func resolveStartProject(st *store.Store, fragment string) (*int64, error) {
	return resolveCachedProject(st, nil, fragment,
		errors.New("usage: tg start [project] <task-fragment>"),
		"; run `tg update` to refresh the catalog")
}

// cmdAuth acquires a token (via tokenSource), verifies it against GET /me, and
// on success writes config.json. Nothing is written on an invalid token.
func cmdAuth(w io.Writer, tokenSource func() (string, error), newClient func(token string) *api.Client) error {
	token, err := tokenSource()
	if err != nil {
		return err
	}
	token = strings.TrimSpace(token)
	if token == "" {
		return errors.New("no API token provided")
	}

	me, err := newClient(token).Me()
	if err != nil {
		if errors.Is(err, api.ErrUnauthorized) {
			return errors.New("authentication failed: invalid token (nothing written)")
		}
		return err
	}

	cfg := &config.Config{APIToken: token, WorkspaceID: me.DefaultWorkspaceID}
	if err := cfg.Save(); err != nil {
		return err
	}
	name := me.Fullname
	if name == "" {
		name = me.Email
	}
	fmt.Fprintf(w, "Authenticated as %s (workspace %d).\n", name, me.DefaultWorkspaceID)
	return nil
}

// projectBillable reports whether the cached project is billable, defaulting to
// false when the project is not in the local catalog yet (e.g. before the first
// `tg update`).
func projectBillable(st *store.Store, projectID int64) (bool, error) {
	p, err := st.ProjectByID(projectID)
	if err != nil {
		return false, err
	}
	if p == nil {
		return false, nil
	}
	return p.Billable, nil
}

// startOfDay returns midnight of t's calendar day in loc.
func startOfDay(t time.Time, loc *time.Location) time.Time {
	t = t.In(loc)
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, loc)
}

func toStoreProject(p api.Project) store.Project {
	return store.Project{
		ID: p.ID, WorkspaceID: p.WorkspaceID, Name: p.Name,
		Color: p.Color, ClientName: p.ClientName, Active: p.Active,
		Billable: p.Billable, At: p.At,
	}
}

func toStoreTasks(ts []api.Task) []store.Task {
	out := make([]store.Task, len(ts))
	for i, t := range ts {
		out[i] = store.Task{
			ID: t.ID, WorkspaceID: t.WorkspaceID, ProjectID: t.ProjectID,
			Name: t.Name, Active: t.Active, At: t.At,
		}
	}
	return out
}

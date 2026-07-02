package main

import (
	"errors"
	"fmt"
	"io"
	"strings"
	"time"

	"mantas6/tgl/api"
	"mantas6/tgl/config"
	"mantas6/tgl/store"
	"mantas6/tgl/sync"
)

// cmdStart resolves a task-title fragment to a single task and starts tracking
// it: 1 match -> auto-stop the running entry and create a new running entry
// (empty description, task + project set); many -> error listing candidates;
// none -> error suggesting `tgl update`. projectID (from TOGGL_PROJECT_ID)
// scopes the candidates when set.
func cmdStart(w io.Writer, st *store.Store, workspaceID int64, projectID *int64, fragment string, now time.Time) error {
	fragment = strings.TrimSpace(fragment)
	if fragment == "" {
		return errors.New("usage: tgl start <task-fragment>")
	}

	tasks, err := st.FindTasksByFragment(fragment, projectID)
	if err != nil {
		return err
	}

	switch len(tasks) {
	case 0:
		return fmt.Errorf("no task matches %q; run `tgl update` to refresh the catalog", fragment)
	case 1:
		task := tasks[0]
		if _, err := st.StopRunning(now, ceil5); err != nil {
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
			Start:       now,
			Duration:    -1,
			Billable:    billable,
			UpdatedAt:   now,
			Dirty:       true,
		}); err != nil {
			return err
		}
		fmt.Fprintf(w, "Started: %s\n", task.Name)
		return nil
	default:
		return fmt.Errorf("multiple tasks match %q:\n%s", fragment, candidateList(tasks))
	}
}

// cmdStop finalizes the running entry (rounding up to the next 5 minutes).
func cmdStop(w io.Writer, st *store.Store, now time.Time) error {
	stopped, err := st.StopRunning(now, ceil5)
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

// cmdToday lists entries for the current day (or the last `days` days).
func cmdToday(w io.Writer, st *store.Store, now time.Time, loc *time.Location, days int, jsonOut bool) error {
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
	renderToday(w, entries, now, loc)
	return nil
}

// cmdTasks lists the locally cached task catalog. `--all` includes inactive
// tasks; a non-nil projectID (from TOGGL_PROJECT_ID) scopes the listing to one
// project. Refresh the cache with `tgl update`.
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
// inactive projects; refresh the cache with `tgl update`.
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

// cmdUpdate mirrors the Toggl catalog (projects + tasks) via full replace.
func cmdUpdate(w io.Writer, st *store.Store, c *api.Client, workspaceID int64, all, jsonOut bool) error {
	projects, err := c.Projects(workspaceID, all)
	if err != nil {
		return err
	}
	tasks, err := c.Tasks(workspaceID, all)
	if err != nil {
		return err
	}
	if err := st.ReplaceProjects(toStoreProjects(projects)); err != nil {
		return err
	}
	if err := st.ReplaceTasks(toStoreTasks(tasks)); err != nil {
		return err
	}

	if jsonOut {
		return writeJSON(w, map[string]int{"projects": len(projects), "tasks": len(tasks)})
	}
	fmt.Fprintf(w, "Updated catalog: %d projects, %d tasks.\n", len(projects), len(tasks))
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

// cmdPull reconciles a single project's remote entries into the local store
// (LWW). The project is chosen by projectID (from TOGGL_PROJECT_ID) when set;
// otherwise fragment must uniquely match a cached project name. Pulling every
// project at once is intentionally disallowed (see resolvePullProject).
func cmdPull(w io.Writer, st *store.Store, c *api.Client, projectID *int64, fragment string, since, now time.Time, jsonOut bool) error {
	pid, err := resolvePullProject(st, projectID, fragment)
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

// resolvePullProject decides which project `pull` scopes to. When projectID is
// set (from TOGGL_PROJECT_ID) it wins and fragment is ignored. Otherwise a
// fragment is required and must resolve to exactly one cached project: none ->
// error suggesting `tgl update`; many -> error listing candidates. This keeps
// `pull` from ever fetching every project's entries at once.
func resolvePullProject(st *store.Store, projectID *int64, fragment string) (*int64, error) {
	if projectID != nil {
		return projectID, nil
	}
	fragment = strings.TrimSpace(fragment)
	if fragment == "" {
		return nil, errors.New("pull requires a project-name fragment (or set TOGGL_PROJECT_ID)")
	}
	projects, err := st.FindProjectsByFragment(fragment)
	if err != nil {
		return nil, err
	}
	switch len(projects) {
	case 0:
		return nil, fmt.Errorf("no project matches %q; run `tgl update` to refresh the catalog", fragment)
	case 1:
		id := projects[0].ID
		return &id, nil
	default:
		return nil, fmt.Errorf("multiple projects match %q:\n%s", fragment, projectCandidateList(projects))
	}
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
// `tgl update`).
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

func toStoreProjects(ps []api.Project) []store.Project {
	out := make([]store.Project, len(ps))
	for i, p := range ps {
		out[i] = store.Project{
			ID: p.ID, WorkspaceID: p.WorkspaceID, Name: p.Name,
			Color: p.Color, ClientName: p.ClientName, Active: p.Active,
			Billable: p.Billable, At: p.At,
		}
	}
	return out
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

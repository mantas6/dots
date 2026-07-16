// Package sync reconciles local time entries with Toggl using a two-way
// last-writer-wins (LWW) strategy keyed on each entry's updated_at vs the
// remote at. Pull brings remote changes down; Push sends local changes up.
// Correct convergence is achieved by running Pull then Push.
package sync

import (
	"time"

	"mantas6/tg/api"
	"mantas6/tg/store"
)

// PullResult summarizes what a pull reconciled.
type PullResult struct {
	Inserted int `json:"inserted"`
	Updated  int `json:"updated"`
	Deleted  int `json:"deleted"`
	Skipped  int `json:"skipped"` // local-newer entries left for push
}

// PushResult summarizes what a push sent.
type PushResult struct {
	Created int `json:"created"`
	Updated int `json:"updated"`
	Deleted int `json:"deleted"`
}

// Pull fetches remote entries modified since `since`, applies LWW against local
// state, and advances last_pull to `now`. A non-nil projectID scopes the pull
// to a single project: entries belonging to other projects (or to none) are
// ignored, and last_pull is left untouched so a later full pull still
// reconciles those other projects. Callers pass nil to reconcile every project.
func Pull(st *store.Store, c *api.Client, projectID *int64, since, now time.Time) (PullResult, error) {
	var res PullResult
	remotes, err := c.List(since)
	if err != nil {
		return res, err
	}

	for _, r := range remotes {
		if projectID != nil && (r.ProjectID == nil || *r.ProjectID != *projectID) {
			continue
		}

		local, err := st.EntryByRemoteID(r.ID)
		if err != nil {
			return res, err
		}

		mapped, err := toStoreEntry(r)
		if err != nil {
			return res, err
		}

		// Self-heal the catalog from the meta-enriched payload so the entry's
		// project/task titles resolve on display even if the local catalog is
		// stale or was never populated (e.g. before the first `tg update`).
		if err := healCatalog(st, r); err != nil {
			return res, err
		}

		switch {
		case local == nil:
			if r.Deleted() {
				res.Skipped++
				continue
			}
			if _, err := st.CreateEntry(mapped); err != nil {
				return res, err
			}
			res.Inserted++

		case !mapped.UpdatedAt.Before(local.UpdatedAt): // remote at >= local updated_at
			if r.Deleted() {
				if err := st.DeleteByRemoteID(r.ID); err != nil {
					return res, err
				}
				res.Deleted++
				continue
			}
			if err := st.UpdateFromRemote(mapped); err != nil {
				return res, err
			}
			res.Updated++

		default: // local is newer; keep it for push
			res.Skipped++
		}
	}

	// Only advance the watermark on a full (unscoped) pull; a project-scoped
	// pull is partial and must not hide other projects' changes from a later
	// full pull.
	if projectID == nil {
		if err := st.SetMeta(store.MetaLastPull, now.UTC().Format(time.RFC3339)); err != nil {
			return res, err
		}
	}
	return res, nil
}

// Push sends every dirty local entry to Toggl: deletions are DELETEd then
// dropped, new entries are POSTed, existing entries are PUT. now is the fallback
// clock used if the server omits an `at` timestamp.
func Push(st *store.Store, c *api.Client, now time.Time) (PushResult, error) {
	var res PushResult
	dirty, err := st.DirtyEntries()
	if err != nil {
		return res, err
	}

	for _, e := range dirty {
		switch {
		case e.Deleted:
			if e.RemoteID != nil {
				if err := c.Delete(e.WorkspaceID, *e.RemoteID); err != nil {
					return res, err
				}
				res.Deleted++
			}
			if err := st.DeleteRow(e.ID); err != nil {
				return res, err
			}

		case e.RemoteID == nil:
			created, err := c.Create(toAPIEntry(e))
			if err != nil {
				return res, err
			}
			if err := st.MarkSynced(e.ID, created.ID, remoteAt(created.At, now)); err != nil {
				return res, err
			}
			res.Created++

		default:
			updated, err := c.Update(toAPIEntry(e))
			if err != nil {
				return res, err
			}
			if err := st.MarkSynced(e.ID, updated.ID, remoteAt(updated.At, now)); err != nil {
				return res, err
			}
			res.Updated++
		}
	}
	return res, nil
}

// healCatalog upserts the project/task referenced by a (non-deleted) remote
// entry using the names (and project color) from its meta=true payload. Missing
// names or ids are skipped, so this is a no-op when meta is absent. A task is
// only healed when its project id is known, since the catalog requires it.
func healCatalog(st *store.Store, r api.TimeEntry) error {
	if r.Deleted() {
		return nil
	}
	if r.ProjectID != nil && r.ProjectName != "" {
		if err := st.UpsertProject(store.Project{
			ID:          *r.ProjectID,
			WorkspaceID: r.WorkspaceID,
			Name:        r.ProjectName,
			Color:       r.ProjectColor,
			Active:      true,
		}); err != nil {
			return err
		}
	}
	if r.TaskID != nil && r.ProjectID != nil && r.TaskName != "" {
		if err := st.UpsertTask(store.Task{
			ID:          *r.TaskID,
			WorkspaceID: r.WorkspaceID,
			ProjectID:   *r.ProjectID,
			Name:        r.TaskName,
			Active:      true,
		}); err != nil {
			return err
		}
	}
	return nil
}

// --- conversions -------------------------------------------------------------

// toStoreEntry maps a remote entry to a clean local entry whose LWW clocks
// (updated_at, synced_at) are pinned to the remote `at`.
func toStoreEntry(r api.TimeEntry) (store.Entry, error) {
	start, err := time.Parse(time.RFC3339, r.Start)
	if err != nil {
		return store.Entry{}, err
	}
	at, err := time.Parse(time.RFC3339, r.At)
	if err != nil {
		return store.Entry{}, err
	}
	e := store.Entry{
		RemoteID:    &r.ID,
		WorkspaceID: r.WorkspaceID,
		ProjectID:   r.ProjectID,
		TaskID:      r.TaskID,
		Description: r.Description,
		Start:       start,
		Duration:    r.Duration,
		Billable:    r.Billable,
		UpdatedAt:   at,
		SyncedAt:    &at,
		Dirty:       false,
		Deleted:     r.Deleted(),
	}
	if r.Stop != nil && *r.Stop != "" {
		stop, err := time.Parse(time.RFC3339, *r.Stop)
		if err != nil {
			return store.Entry{}, err
		}
		e.Stop = &stop
	}
	return e, nil
}

// toAPIEntry maps a local entry to an API time entry for create/update.
func toAPIEntry(e store.Entry) api.TimeEntry {
	te := api.TimeEntry{
		WorkspaceID: e.WorkspaceID,
		ProjectID:   e.ProjectID,
		TaskID:      e.TaskID,
		Description: e.Description,
		Start:       e.Start.UTC().Format(time.RFC3339),
		Duration:    e.Duration,
		Billable:    e.Billable,
	}
	if e.RemoteID != nil {
		te.ID = *e.RemoteID
	}
	if e.Stop != nil {
		stop := e.Stop.UTC().Format(time.RFC3339)
		te.Stop = &stop
	}
	return te
}

// remoteAt parses the server's `at`, falling back to now when absent/invalid.
func remoteAt(at string, now time.Time) time.Time {
	if at == "" {
		return now
	}
	t, err := time.Parse(time.RFC3339, at)
	if err != nil {
		return now
	}
	return t
}

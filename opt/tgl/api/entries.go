package api

import (
	"fmt"
	"net/url"
	"strconv"
	"time"
)

// createdWith identifies this client to Toggl on entry creation.
const createdWith = "tgl"

// entryPayload is the request body for creating/updating a time entry.
type entryPayload struct {
	WorkspaceID int64   `json:"workspace_id"`
	ProjectID   *int64  `json:"project_id,omitempty"`
	TaskID      *int64  `json:"task_id,omitempty"`
	Description string  `json:"description"`
	Start       string  `json:"start"`
	Stop        *string `json:"stop,omitempty"`
	Duration    int64   `json:"duration"`
	CreatedWith string  `json:"created_with,omitempty"`
}

func payloadFrom(e TimeEntry, withCreatedWith bool) entryPayload {
	p := entryPayload{
		WorkspaceID: e.WorkspaceID,
		ProjectID:   e.ProjectID,
		TaskID:      e.TaskID,
		Description: e.Description,
		Start:       e.Start,
		Stop:        e.Stop,
		Duration:    e.Duration,
	}
	if withCreatedWith {
		p.CreatedWith = createdWith
	}
	return p
}

// Me returns the authenticated user (used to verify the token and discover the
// default workspace).
func (c *Client) Me() (*Me, error) {
	var me Me
	if err := c.do("GET", "/me", nil, &me); err != nil {
		return nil, err
	}
	return &me, nil
}

// Current returns the running time entry, or nil if none is running.
func (c *Client) Current() (*TimeEntry, error) {
	var te *TimeEntry
	if err := c.do("GET", "/me/time_entries/current", nil, &te); err != nil {
		return nil, err
	}
	return te, nil
}

// List returns time entries modified at/after since, including remote
// deletions (meta=true enriches the payload with project/task metadata).
func (c *Client) List(since time.Time) ([]TimeEntry, error) {
	q := url.Values{}
	q.Set("since", strconv.FormatInt(since.UTC().Unix(), 10))
	q.Set("meta", "true")
	var entries []TimeEntry
	if err := c.do("GET", "/me/time_entries?"+q.Encode(), nil, &entries); err != nil {
		return nil, err
	}
	return entries, nil
}

// Create posts a new time entry (tagged created_with:"tgl") and returns the
// server's representation (with id and at).
func (c *Client) Create(e TimeEntry) (*TimeEntry, error) {
	var out TimeEntry
	path := fmt.Sprintf("/workspaces/%d/time_entries", e.WorkspaceID)
	if err := c.do("POST", path, payloadFrom(e, true), &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// Update PUTs changes to an existing time entry.
func (c *Client) Update(e TimeEntry) (*TimeEntry, error) {
	var out TimeEntry
	path := fmt.Sprintf("/workspaces/%d/time_entries/%d", e.WorkspaceID, e.ID)
	if err := c.do("PUT", path, payloadFrom(e, false), &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// Stop PATCHes a running entry to stop it, returning the stopped entry.
func (c *Client) Stop(workspaceID, id int64) (*TimeEntry, error) {
	var out TimeEntry
	path := fmt.Sprintf("/workspaces/%d/time_entries/%d/stop", workspaceID, id)
	if err := c.do("PATCH", path, nil, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// Delete removes a time entry.
func (c *Client) Delete(workspaceID, id int64) error {
	path := fmt.Sprintf("/workspaces/%d/time_entries/%d", workspaceID, id)
	return c.do("DELETE", path, nil, nil)
}

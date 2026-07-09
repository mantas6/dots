package api

import (
	"fmt"
	"net/url"
	"strconv"
)

// perPage is the catalog pagination batch size.
const perPage = 200

// pageQuery builds the shared pagination/active query for catalog endpoints.
// active=both is requested when includeInactive is set, otherwise active=true.
func pageQuery(page int, includeInactive bool) url.Values {
	q := url.Values{}
	q.Set("page", strconv.Itoa(page))
	q.Set("per_page", strconv.Itoa(perPage))
	if includeInactive {
		q.Set("active", "both")
	} else {
		q.Set("active", "true")
	}
	return q
}

// getPaged walks a workspace-scoped endpoint that returns a bare JSON array,
// page by page, until a short (or empty) page signals the end.
func getPaged[T any](c *Client, path string, includeInactive bool) ([]T, error) {
	var out []T
	for page := 1; ; page++ {
		var batch []T
		if err := c.do("GET", path+"?"+pageQuery(page, includeInactive).Encode(), nil, &batch); err != nil {
			return nil, err
		}
		out = append(out, batch...)
		if len(batch) < perPage {
			return out, nil
		}
	}
}

// Projects returns the workspace's projects (active only unless includeInactive).
// This endpoint returns a bare JSON array.
func (c *Client) Projects(workspaceID int64, includeInactive bool) ([]Project, error) {
	return getPaged[Project](c, fmt.Sprintf("/workspaces/%d/projects", workspaceID), includeInactive)
}

// Project returns a single workspace project by id. It is used by the
// project-scoped `tg update` to refresh (or bootstrap) one project's metadata
// without listing the whole workspace.
func (c *Client) Project(workspaceID, projectID int64) (Project, error) {
	var p Project
	err := c.do("GET", fmt.Sprintf("/workspaces/%d/projects/%d", workspaceID, projectID), nil, &p)
	return p, err
}

// ProjectTasks returns the tasks of a single project (active only unless
// includeInactive). Unlike the workspace tasks endpoint (which paginates inside
// a {data, ...} envelope), this project-scoped endpoint is NOT paginated: it
// accepts only an `active` filter and returns every task as a bare JSON array
// in a single response. It must therefore be fetched with one request — walking
// pages here would loop forever, because the endpoint ignores page/per_page and
// returns the full list again for every page, so no page is ever short enough
// to terminate a getPaged-style walk once a project has perPage+ tasks.
func (c *Client) ProjectTasks(workspaceID, projectID int64, includeInactive bool) ([]Task, error) {
	path := fmt.Sprintf("/workspaces/%d/projects/%d/tasks", workspaceID, projectID)
	// The endpoint returns all tasks unless active=true is set; omitting the
	// filter (includeInactive) yields both active and inactive tasks.
	if !includeInactive {
		path += "?active=true"
	}
	var tasks []Task
	if err := c.do("GET", path, nil, &tasks); err != nil {
		return nil, err
	}
	return tasks, nil
}

// tasksResponse is the paginated envelope returned by the workspace tasks
// endpoint. Unlike projects (a bare array), tasks arrive wrapped in
// {data, total_count, per_page}; decoding into a slice is what previously
// failed with "cannot unmarshal object into Go value of type []api.Task".
type tasksResponse struct {
	Data       []Task `json:"data"`
	TotalCount int    `json:"total_count"`
	PerPage    int    `json:"per_page"`
}

// Tasks returns the workspace's tasks (active only unless includeInactive).
// The endpoint paginates inside a {data, ...} envelope, so it is walked
// separately from the bare-array collections. The walk stops on a short page or
// once total_count items have been collected.
func (c *Client) Tasks(workspaceID int64, includeInactive bool) ([]Task, error) {
	path := fmt.Sprintf("/workspaces/%d/tasks", workspaceID)
	var out []Task
	for page := 1; ; page++ {
		var resp tasksResponse
		if err := c.do("GET", path+"?"+pageQuery(page, includeInactive).Encode(), nil, &resp); err != nil {
			return nil, err
		}
		out = append(out, resp.Data...)
		if len(resp.Data) < perPage || (resp.TotalCount > 0 && len(out) >= resp.TotalCount) {
			return out, nil
		}
	}
}

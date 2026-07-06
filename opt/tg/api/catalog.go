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

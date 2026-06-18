package api

import (
	"fmt"
	"net/url"
	"strconv"
)

// perPage is the catalog pagination batch size.
const perPage = 200

// getPaged walks a workspace-scoped collection endpoint page by page until a
// short (or empty) page signals the end, accumulating every item. active=both
// is requested when includeInactive is set, otherwise active=true.
func getPaged[T any](c *Client, path string, includeInactive bool) ([]T, error) {
	var out []T
	for page := 1; ; page++ {
		q := url.Values{}
		q.Set("page", strconv.Itoa(page))
		q.Set("per_page", strconv.Itoa(perPage))
		if includeInactive {
			q.Set("active", "both")
		} else {
			q.Set("active", "true")
		}

		var batch []T
		if err := c.do("GET", path+"?"+q.Encode(), nil, &batch); err != nil {
			return nil, err
		}
		out = append(out, batch...)
		if len(batch) < perPage {
			return out, nil
		}
	}
}

// Projects returns the workspace's projects (active only unless includeInactive).
func (c *Client) Projects(workspaceID int64, includeInactive bool) ([]Project, error) {
	return getPaged[Project](c, fmt.Sprintf("/workspaces/%d/projects", workspaceID), includeInactive)
}

// Tasks returns the workspace's tasks (active only unless includeInactive).
func (c *Client) Tasks(workspaceID int64, includeInactive bool) ([]Task, error) {
	return getPaged[Task](c, fmt.Sprintf("/workspaces/%d/tasks", workspaceID), includeInactive)
}

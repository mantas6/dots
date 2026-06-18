// Package api is a thin client for the Toggl Track API v9. It uses HTTP Basic
// auth (the API token as username, the literal "api_token" as password) and
// maps non-2xx responses to Go errors. The base URL and *http.Client are
// injectable so tests can point at an httptest.Server.
package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// DefaultBaseURL is the production Toggl Track API v9 root.
const DefaultBaseURL = "https://api.track.toggl.com/api/v9"

// ErrUnauthorized is returned when Toggl rejects the credentials (401/403).
var ErrUnauthorized = errors.New("invalid API token")

// Client talks to the Toggl Track API.
type Client struct {
	token      string
	baseURL    string
	httpClient *http.Client
}

// Option configures a Client.
type Option func(*Client)

// WithBaseURL overrides the API root (used in tests).
func WithBaseURL(u string) Option {
	return func(c *Client) { c.baseURL = strings.TrimRight(u, "/") }
}

// WithHTTPClient injects a custom *http.Client (used in tests).
func WithHTTPClient(h *http.Client) Option {
	return func(c *Client) { c.httpClient = h }
}

// New returns a Client authenticating with the given API token.
func New(token string, opts ...Option) *Client {
	c := &Client{
		token:      token,
		baseURL:    DefaultBaseURL,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}
	for _, o := range opts {
		o(c)
	}
	return c
}

// do performs an HTTP request, marshaling body (if non-nil) as JSON and
// unmarshaling a 2xx response into out (if non-nil). Non-2xx responses become
// errors: 401/403 -> ErrUnauthorized, otherwise an error carrying the status
// and (possibly non-JSON) response body.
func (c *Client) do(method, path string, body, out any) error {
	var reqBody io.Reader
	if body != nil {
		buf, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reqBody = bytes.NewReader(buf)
	}

	req, err := http.NewRequest(method, c.baseURL+path, reqBody)
	if err != nil {
		return err
	}
	req.SetBasicAuth(c.token, "api_token")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
		return ErrUnauthorized
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		msg := strings.TrimSpace(string(respBody))
		if msg == "" {
			msg = http.StatusText(resp.StatusCode)
		}
		return fmt.Errorf("toggl api: status %d: %s", resp.StatusCode, msg)
	}

	if out == nil || len(bytes.TrimSpace(respBody)) == 0 {
		return nil
	}
	if err := json.Unmarshal(respBody, out); err != nil {
		return fmt.Errorf("decoding response: %w", err)
	}
	return nil
}

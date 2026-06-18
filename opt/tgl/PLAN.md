# `tgl` — local-first Toggl time tracker

A small, fast CLI for managing time entries during the day. Time is tracked
**locally in SQLite** (fully offline) and synchronized to **Toggl Track API v9**
on demand.

## Concept

Two independent sync directions:

- **Time entries** &harr; Toggl via `push` / `pull` (two-way, last-writer-wins).
- **Task catalog** (projects + tasks) &larr; Toggl via `update` (read-only
  mirror), so `start <fragment>` can resolve a task by title.

Durations round **up to the next 5 minutes** (minimum 5m). `start` takes a
**task-title fragment**, not a free-form description.

## Scope (v1)

Commands: `auth`, `start`, `stop`, `current` (`status`), `today` (`list`),
`push`, `pull`, `update`. Read and sync commands support `--json`.

Out of v1: tags, manual `add`/`edit`/`delete`, interactive pickers, a combined
`sync` command.

## Locked decisions

| Area | Decision |
| --- | --- |
| Binary name | `tgl` |
| Packaging | Standalone like `bar`/`sessionizer`: `build` script &rarr; `$HOME/.local/bin/tgl`, auto-run by `bin/dot/init-dots`. No Nix, no stow. |
| Go / module | `go 1.26`, module `mantas6/tgl` |
| Dependencies | `modernc.org/sqlite` (pure Go, no cgo) + `golang.org/x/term` (masked auth input). First `go.sum` in the repo. |
| Storage | SQLite at `~/.local/state/tgl/tgl.db`; token + workspace in `~/.local/state/tgl/config.json` |
| Rounding | Duration rounded **up** to next 5 min (min 5), applied on `stop` |
| Entry sync | Two-way last-writer-wins via `push` + `pull` (run `pull` then `push`). No `sync` command. |
| Catalog sync | `update` mirrors projects + tasks (full replace, active-only; `--all` for inactive) |
| `start` matching | Task-title case-insensitive substring; exact title wins; scoped/set by `TOGGL_PROJECT_ID`; 1 = start, many = error+list, none = error. Always auto-stops the running entry. |
| Project env var | `TOGGL_PROJECT_ID` (scopes match candidates **and** sets the entry project) |
| `auth` | Interactive masked prompt (also accepts arg / piped stdin); verifies `/me`; writes `config.json` (0600) |
| First `pull` window | 90 days (`--since DATE` to override) |
| Toggl Tasks | Paid feature (Starter+); confirmed available on the target account |

## Repository conventions

Lives at `opt/tgl/`, mirroring `opt/sessionizer/` (multi-package + `build`
script). Format Go with `gofmt`, the `build` script with `shfmt`.

`build` (mirrors `opt/sessionizer/build`):

```sh
#!/bin/sh
cd "$(dirname "$(realpath "$0")")" || exit 1
[ ! -x "$(command -v go)" ] && exit 0
exec go build -o "$HOME/.local/bin/tgl"
```

`.gitignore`: `/tgl` (built binary if compiled in-tree).

## State directory

`${XDG_STATE_HOME:-~/.local/state}/tgl/` (created with mode `0700`):

- `config.json` (mode `0600`): `{ "api_token": "…", "workspace_id": 12345 }`
- `tgl.db`: SQLite, opened with
  `?_pragma=busy_timeout(5000)&_pragma=journal_mode(WAL)`

The token is kept in `config.json`, out of the database.

## SQLite schema

```sql
CREATE TABLE entries (              -- locally tracked time
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  remote_id    INTEGER UNIQUE,      -- Toggl id; NULL until pushed
  workspace_id INTEGER NOT NULL,
  project_id   INTEGER,
  task_id      INTEGER,             -- set when started from a task
  description  TEXT NOT NULL DEFAULT '',
  start        TEXT NOT NULL,       -- RFC3339 UTC
  stop         TEXT,                -- NULL while running
  duration     INTEGER NOT NULL,    -- seconds (quantized); -1 running
  updated_at   TEXT NOT NULL,       -- LWW clock, bumped on local change
  synced_at    TEXT,                -- remote `at` last reconciled
  dirty        INTEGER NOT NULL DEFAULT 1,
  deleted      INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_entries_start ON entries(start);

CREATE TABLE projects (             -- catalog mirror (read-only locally)
  id           INTEGER PRIMARY KEY,
  workspace_id INTEGER NOT NULL,
  name         TEXT NOT NULL,
  color        TEXT,
  client_name  TEXT,
  active       INTEGER NOT NULL DEFAULT 1,
  at           TEXT
);

CREATE TABLE tasks (
  id           INTEGER PRIMARY KEY,
  workspace_id INTEGER NOT NULL,
  project_id   INTEGER NOT NULL,
  name         TEXT NOT NULL,
  active       INTEGER NOT NULL DEFAULT 1,
  at           TEXT
);

CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);  -- schema_version, last_pull
```

Invariant: at most one row with `stop IS NULL AND deleted = 0` (the running
entry).

## Package layout

```
opt/tgl/
  go.mod / go.sum     mantas6/tgl; modernc.org/sqlite, golang.org/x/term
  build               sh: go build -o $HOME/.local/bin/tgl  (no cgo)
  .gitignore          /tgl
  PLAN.md             this document
  main.go             subcommand dispatch + top-level error handling
  commands.go         auth/start/stop/current/today/push/pull/update handlers
  format.go           ceil5, duration/time formatting, tables, JSON shapes
  store/
    store.go          entries CRUD, catalog upsert/replace, task lookup, meta
    schema.go         DDL + migrations
  api/
    client.go         Basic auth, do() helper, error mapping; injectable baseURL + *http.Client
    types.go          Me, TimeEntry, Project, Task
    entries.go        Me, Current, List, Create, Update, Delete
    catalog.go        Projects, Tasks (paginated)
  config/
    config.go         config.json load/save (honors XDG_STATE_HOME)
  sync/
    sync.go           Pull / Push time entries (LWW)
```

## Rounding (`format.go`)

```go
// ceil5 rounds a duration up to the next 5 minutes, minimum 5 minutes.
func ceil5(d time.Duration) time.Duration {
    const s = 5 * time.Minute
    if d <= 0 {
        return s
    }
    return ((d + s - 1) / s) * s
}
```

Applied on `stop`: keep the real `start`; set `duration = ceil5(now - start)`
and `stop = start + duration`. Running entries display live (un-rounded)
elapsed; rounding finalizes on stop.

## Commands

| Command | Behavior |
| --- | --- |
| `tgl auth` | Interactive **masked** prompt (`golang.org/x/term`); also accepts `tgl auth <token>` arg or piped stdin. Verifies `GET /me`, writes `config.json` (0600), caches `workspace_id`. On `403`, writes nothing. |
| `tgl start <fragment>` | Match cached **task names** (case-insensitive substring; exact title wins). If `TOGGL_PROJECT_ID` is set, restrict candidates to that project and set the entry project to it. **1 match** &rarr; auto-stop the running entry, create a local running entry with `task_id` + `project_id` and **empty description**. **Many** &rarr; print candidates, exit error. **None** &rarr; error suggesting `tgl update`. |
| `tgl stop` | Finalize the running entry with `ceil5`; set `dirty=1`. No-op message if nothing is running. |
| `tgl current` / `status` `[--json]` | Show the running entry (task/project via join, start, live elapsed). |
| `tgl today` / `list` `[--days N] [--json]` | Local entries (default today; `--days N` looks back N days). Join `task_id`/`project_id` &rarr; names; table + total; running entry marked. |
| `tgl push` `[--json]` | Send `dirty` entries: no `remote_id` &rarr; POST create; has id &rarr; PUT update; `deleted=1` &rarr; DELETE then drop row. Sends `task_id` + `project_id`, `created_with:"tgl"`. Store returned id, clear `dirty`, set `synced_at`. |
| `tgl pull` `[--json]` | `GET /me/time_entries?since=<last_pull>&meta=true` (first run: 90-day window, `--since DATE`). Upsert by `remote_id` with **LWW** vs `updated_at`. Update `last_pull`. |
| `tgl update` `[--all] [--json]` | Refresh catalog: paginated `GET /workspaces/{wid}/projects` + `/tasks` (active only; `--all` includes inactive). **Full replace** of `projects` / `tasks` tables. |

### `start` fragment matching

A pure function drives matching so it is unit-testable without SQLite:

```go
func matchTasks(tasks []Task, fragment string, projectID *int) []Task
```

- Case-insensitive substring against `task.name`.
- If `projectID != nil`, only consider tasks in that project.
- An exact (case-insensitive) full-title match wins even if it is also a
  substring of other tasks.
- Returns deterministic ordering (by name) for stable candidate listing.

## Sync (entries, `sync/`) — two-way last-writer-wins

- **Pull** (remote &rarr; local): for each remote `R` matched by `remote_id`:
  - no local &rarr; insert (skip if `R` is deleted), mark clean.
  - `R.at >= L.updated_at` &rarr; remote wins (apply, or delete local if `R`
    deleted); set `dirty=0`, `updated_at = synced_at = R.at`.
  - `L.updated_at > R.at` &rarr; local newer, keep it (push will send it).
- **Push** (local &rarr; remote): for each `dirty` `L`, create/update/delete on
  Toggl, then clear `dirty`, set `remote_id` / `synced_at`.
- Correct LWW = run `pull` then `push` (documented in `--help`). Plain `push`
  can overwrite a newer remote edit.

## API client (`api/`)

Base `https://api.track.toggl.com/api/v9`. Basic auth with `token:api_token`.
A single `do(method, path, body, out)` helper handles JSON marshal/unmarshal and
maps non-2xx responses to errors (`403` &rarr; "invalid token", `500` &rarr;
generic, non-JSON bodies handled).

- `Me()` &rarr; `GET /me` (default workspace).
- `Current()` &rarr; `GET /me/time_entries/current` (`null` &rarr; nil).
- `List(since|range)` &rarr; `GET /me/time_entries?...&meta=true`.
- `Create / Update / Delete / Stop` time entries (workspace-scoped).
- `Projects(since, all)` / `Tasks(since, all)` &rarr; paginated
  (`page` / `per_page`), loop until `total_count`; `active=both` when `all`.

`baseURL` and `*http.Client` are injectable so tests can target an
`httptest.Server`.

## Output

- Human `today`:

  ```
  09:15-10:30  1h15m  Fix login bug   [Backend]
  10:30-  *    0h45m  Code review     [Backend]
  ----------------------------------------
  Total: 2h00m   (* running)
  ```

  Labels come from the `tasks` join (fallback to `description` for any
  free-form entry).
- `--json` emits a stable normalized shape (not the raw API), e.g. `current`:

  ```json
  {"running":true,"task":"Code review","project":"Backend","start":"…","elapsed_seconds":2520,"id":12}
  ```

## Testing plan

- **Style:** real boundaries — temp SQLite via `t.TempDir()` + `httptest.Server`
  fakes; minimal interfaces; stdlib `testing`, table-driven. No interface mocks
  for store/api. No real-API end-to-end test.
- **Determinism:** injected clock (`now func() time.Time`, default `time.Now`);
  explicit `*time.Location` (UTC) in formatters; `t.Setenv` for
  `XDG_STATE_HOME` and `TOGGL_PROJECT_ID`.
- **Output assertions:** golden files in `testdata/` with a `-update` flag.

### Testability tweaks to the design

1. `api.New(token, opts…)` with injectable `baseURL` + `*http.Client`.
2. Clock `now func() time.Time` threaded through `store` / `sync` / commands.
3. Command handlers take explicit deps + an `io.Writer` for output; `auth`'s
   token acquisition sits behind an injectable reader func (non-TTY path tested
   directly).
4. Formatting helpers take an explicit `*time.Location`.
5. Pure `matchTasks(tasks, fragment, projectID)` matcher.

### Suites

- `format_test.go` — `ceil5` table (0&rarr;5m, 1s&rarr;5m, 5m&rarr;5m,
  5m1s&rarr;10m, 46m&rarr;50m, 45m&rarr;45m, negative&rarr;5m); duration/time
  formatting; rendered `today` table and `--json` shapes (golden).
- `store/store_test.go` — migrate idempotency; stop sets
  `stop`/`duration`/`dirty`/`updated_at`; single-running invariant;
  `EntriesBetween` ordering; `DirtyEntries` / `MarkSynced`; catalog full
  replace; `FindTasksByFragment` (substring, exact-title precedence,
  `TOGGL_PROJECT_ID` scoping, active-only); `meta` round-trip.
- `api/client_test.go` — Basic auth header `base64(token:api_token)`; `Me`
  parses `default_workspace_id`; `Current` handles `null`; `List` query
  (`since`/`meta`); `Create` body (`workspace_id`, `start`, `duration:-1`,
  `created_with:"tgl"`, `task_id`, `project_id`); `Stop`/`Update`/`Delete`
  method+path; tasks/projects pagination loops to `total_count`; error mapping
  (403/500/non-JSON).
- `sync/sync_test.go` — push create/update/delete; pull insert; LWW
  remote-newer / local-newer / remote-deleted; `last_pull` advances; pull&rarr;push
  round-trip consistency.
- command integration tests — `start` 1/many/none + exact-wins + env scope +
  auto-stop + empty description; `stop` quantize via injected clock;
  `current`/`today` golden (fixed tz); `auth` 200 writes `config.json` 0600 /
  403 writes nothing.

## Verification gate

`gofmt -l` · `go vet ./...` · `go build ./...` · `go test ./...`
(optional `go test -race ./...`).

## Implementation order

1. `go.mod` (+ `go mod tidy`), `build`, `.gitignore`.
2. `store/` — schema + migrations + entries CRUD + catalog + lookups (+ tests).
3. `config/`; local commands `start` / `stop` / `current` / `today` +
   `format.go` (+ tests).
4. `api/` — client, entries, catalog pagination (+ tests).
5. `update` — catalog refresh.
6. `sync/` + `push` / `pull` (+ tests).
7. `auth` — interactive masked input.
8. Integration tests + golden files; full `go test ./...` / `go vet` /
   `gofmt` pass.

## Caveats / non-goals

- Toggl Tasks require a paid plan; on a free workspace `update` finds 0 tasks
  and `start <fragment>` always errors.
- `update` does a full catalog replace (not `since`-incremental) for simplicity.
- Task-started entries leave `description` empty; the label is the linked task.
- `start` always auto-stops the running entry (no overlap; mirrors Toggl).
- First `pull` imports a 90-day window by default.
- Tags are out of v1.

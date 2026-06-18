package store

// schemaVersion is the current logical schema version, recorded in meta.
const schemaVersion = "1"

// schemaSQL creates every table and index. It is idempotent (IF NOT EXISTS),
// so applying it repeatedly is safe and forms the basis of migration.
const schemaSQL = `
CREATE TABLE IF NOT EXISTS entries (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  remote_id    INTEGER UNIQUE,
  workspace_id INTEGER NOT NULL,
  project_id   INTEGER,
  task_id      INTEGER,
  description  TEXT NOT NULL DEFAULT '',
  start        TEXT NOT NULL,
  stop         TEXT,
  duration     INTEGER NOT NULL,
  updated_at   TEXT NOT NULL,
  synced_at    TEXT,
  dirty        INTEGER NOT NULL DEFAULT 1,
  deleted      INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_entries_start ON entries(start);

CREATE TABLE IF NOT EXISTS projects (
  id           INTEGER PRIMARY KEY,
  workspace_id INTEGER NOT NULL,
  name         TEXT NOT NULL,
  color        TEXT,
  client_name  TEXT,
  active       INTEGER NOT NULL DEFAULT 1,
  at           TEXT
);

CREATE TABLE IF NOT EXISTS tasks (
  id           INTEGER PRIMARY KEY,
  workspace_id INTEGER NOT NULL,
  project_id   INTEGER NOT NULL,
  name         TEXT NOT NULL,
  active       INTEGER NOT NULL DEFAULT 1,
  at           TEXT
);

CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT);
`

// migrate applies the schema and records the schema version. It is safe to run
// on every Open (idempotent).
func (s *Store) migrate() error {
	if _, err := s.db.Exec(schemaSQL); err != nil {
		return err
	}
	return s.SetMeta(MetaSchemaVersion, schemaVersion)
}

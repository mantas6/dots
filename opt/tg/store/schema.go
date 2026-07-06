package store

import "database/sql"

// schemaVersion is the current logical schema version, recorded in meta.
// v2 added the billable flag to entries and projects.
const schemaVersion = "2"

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
  billable     INTEGER NOT NULL DEFAULT 0,
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
  billable     INTEGER NOT NULL DEFAULT 0,
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

// addColumns holds columns introduced after the initial schema. Fresh databases
// get them from schemaSQL; pre-existing ones are upgraded in place by migrate.
var addColumns = []struct{ table, column, ddl string }{
	{"entries", "billable", "ALTER TABLE entries ADD COLUMN billable INTEGER NOT NULL DEFAULT 0"},
	{"projects", "billable", "ALTER TABLE projects ADD COLUMN billable INTEGER NOT NULL DEFAULT 0"},
}

// migrate applies the schema, back-fills any columns added in later versions on
// pre-existing databases, and records the schema version. It is safe to run on
// every Open (idempotent).
func (s *Store) migrate() error {
	if _, err := s.db.Exec(schemaSQL); err != nil {
		return err
	}
	for _, c := range addColumns {
		has, err := s.hasColumn(c.table, c.column)
		if err != nil {
			return err
		}
		if has {
			continue
		}
		if _, err := s.db.Exec(c.ddl); err != nil {
			return err
		}
	}
	return s.SetMeta(MetaSchemaVersion, schemaVersion)
}

// hasColumn reports whether table already has the named column. SQLite lacks
// ADD COLUMN IF NOT EXISTS, so migrations probe the schema first. The table name
// is a trusted constant (never user input), so interpolating it is safe.
func (s *Store) hasColumn(table, column string) (bool, error) {
	rows, err := s.db.Query("PRAGMA table_info(" + table + ")")
	if err != nil {
		return false, err
	}
	defer rows.Close()
	for rows.Next() {
		var (
			cid     int
			name    string
			ctype   string
			notnull int
			dflt    sql.NullString
			pk      int
		)
		if err := rows.Scan(&cid, &name, &ctype, &notnull, &dflt, &pk); err != nil {
			return false, err
		}
		if name == column {
			return true, nil
		}
	}
	return false, rows.Err()
}

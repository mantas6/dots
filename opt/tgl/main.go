// Command tgl is a local-first time tracker that records entries in SQLite and
// synchronizes them with Toggl Track on demand. See PLAN.md for the full design.
package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"time"

	"golang.org/x/term"

	"mantas6/tgl/api"
	"mantas6/tgl/config"
	"mantas6/tgl/store"
)

func main() {
	if len(os.Args) < 2 {
		printUsage(os.Stderr)
		os.Exit(1)
	}
	if err := run(os.Args[1], os.Args[2:]); err != nil {
		fmt.Fprintln(os.Stderr, "tgl: "+err.Error())
		os.Exit(1)
	}
}

func run(cmd string, args []string) error {
	switch cmd {
	case "auth":
		return runAuth(args)
	case "start":
		return runStart(args)
	case "stop":
		return runStop(args)
	case "current", "status":
		return runCurrent(args)
	case "today", "list":
		return runToday(args)
	case "tasks":
		return runTasks(args)
	case "update":
		return runUpdate(args)
	case "push":
		return runPush(args)
	case "pull":
		return runPull(args)
	case "help", "-h", "--help":
		printUsage(os.Stdout)
		return nil
	default:
		printUsage(os.Stderr)
		return fmt.Errorf("unknown command %q", cmd)
	}
}

// --- command wiring ----------------------------------------------------------

func runStart(args []string) error {
	fs := newFlagSet("start")
	if err := fs.Parse(args); err != nil {
		return err
	}
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()
	return cmdStart(os.Stdout, st, cfg.WorkspaceID, projectIDFromEnv(), strings.Join(fs.Args(), " "), time.Now())
}

func runStop(args []string) error {
	fs := newFlagSet("stop")
	if err := fs.Parse(args); err != nil {
		return err
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()
	return cmdStop(os.Stdout, st, time.Now())
}

func runCurrent(args []string) error {
	fs := newFlagSet("current")
	jsonOut := fs.Bool("json", false, "emit JSON")
	if err := fs.Parse(args); err != nil {
		return err
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()
	return cmdCurrent(os.Stdout, st, time.Now(), time.Local, *jsonOut)
}

func runToday(args []string) error {
	fs := newFlagSet("today")
	jsonOut := fs.Bool("json", false, "emit JSON")
	days := fs.Int("days", 1, "number of days to look back")
	if err := fs.Parse(args); err != nil {
		return err
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()
	return cmdToday(os.Stdout, st, time.Now(), time.Local, *days, *jsonOut)
}

func runTasks(args []string) error {
	fs := newFlagSet("tasks")
	all := fs.Bool("all", false, "include inactive tasks")
	jsonOut := fs.Bool("json", false, "emit JSON")
	if err := fs.Parse(args); err != nil {
		return err
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()
	return cmdTasks(os.Stdout, st, *all, *jsonOut)
}

func runUpdate(args []string) error {
	fs := newFlagSet("update")
	all := fs.Bool("all", false, "include inactive projects/tasks")
	jsonOut := fs.Bool("json", false, "emit JSON")
	if err := fs.Parse(args); err != nil {
		return err
	}
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()
	return cmdUpdate(os.Stdout, st, api.New(cfg.APIToken), cfg.WorkspaceID, *all, *jsonOut)
}

func runPush(args []string) error {
	fs := newFlagSet("push")
	jsonOut := fs.Bool("json", false, "emit JSON")
	if err := fs.Parse(args); err != nil {
		return err
	}
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()
	return cmdPush(os.Stdout, st, api.New(cfg.APIToken), time.Now(), *jsonOut)
}

func runPull(args []string) error {
	fs := newFlagSet("pull")
	jsonOut := fs.Bool("json", false, "emit JSON")
	sinceFlag := fs.String("since", "", "pull entries modified since DATE (YYYY-MM-DD)")
	if err := fs.Parse(args); err != nil {
		return err
	}
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()

	now := time.Now()
	since, err := resolveSince(st, *sinceFlag, now, time.Local)
	if err != nil {
		return err
	}
	return cmdPull(os.Stdout, st, api.New(cfg.APIToken), since, now, *jsonOut)
}

func runAuth(args []string) error {
	fs := newFlagSet("auth")
	if err := fs.Parse(args); err != nil {
		return err
	}
	return cmdAuth(os.Stdout, tokenSource(fs.Args()), func(token string) *api.Client {
		return api.New(token)
	})
}

// --- helpers -----------------------------------------------------------------

// openStore ensures the state directory exists and opens the SQLite database.
func openStore() (*store.Store, error) {
	if _, err := config.EnsureDir(); err != nil {
		return nil, err
	}
	path, err := config.DBPath()
	if err != nil {
		return nil, err
	}
	return store.Open(path)
}

// projectIDFromEnv parses TOGGL_PROJECT_ID, returning nil when unset/invalid.
func projectIDFromEnv() *int64 {
	v := strings.TrimSpace(os.Getenv("TOGGL_PROJECT_ID"))
	if v == "" {
		return nil
	}
	id, err := strconv.ParseInt(v, 10, 64)
	if err != nil {
		return nil
	}
	return &id
}

// resolveSince determines the pull window start: an explicit --since date, else
// the recorded last_pull, else a 90-day default window.
func resolveSince(st *store.Store, sinceFlag string, now time.Time, loc *time.Location) (time.Time, error) {
	if sinceFlag != "" {
		t, err := time.ParseInLocation("2006-01-02", sinceFlag, loc)
		if err != nil {
			return time.Time{}, fmt.Errorf("invalid --since %q (want YYYY-MM-DD)", sinceFlag)
		}
		return t, nil
	}
	if v, ok, err := st.GetMeta(store.MetaLastPull); err != nil {
		return time.Time{}, err
	} else if ok {
		return time.Parse(time.RFC3339, v)
	}
	return now.AddDate(0, 0, -90), nil
}

// tokenSource returns a function that yields the API token: an explicit arg, a
// piped (non-TTY) stdin line, or an interactive masked prompt.
func tokenSource(args []string) func() (string, error) {
	return func() (string, error) {
		if len(args) > 0 {
			return args[0], nil
		}
		fd := int(os.Stdin.Fd())
		if !term.IsTerminal(fd) {
			data, err := io.ReadAll(os.Stdin)
			return string(data), err
		}
		fmt.Fprint(os.Stderr, "Toggl API token: ")
		b, err := term.ReadPassword(fd)
		fmt.Fprintln(os.Stderr)
		return string(b), err
	}
}

func newFlagSet(name string) *flag.FlagSet {
	fs := flag.NewFlagSet(name, flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	return fs
}

func printUsage(w io.Writer) {
	fmt.Fprintln(w, "usage: tgl <command> [flags]")
	fmt.Fprintln(w, "")
	fmt.Fprintln(w, "commands:")
	fmt.Fprintln(w, "  auth [token]          verify a Toggl API token and store config")
	fmt.Fprintln(w, "  start <fragment>      start tracking the task matching <fragment>")
	fmt.Fprintln(w, "  stop                  stop the running entry (rounds up to 5m)")
	fmt.Fprintln(w, "  current | status      show the running entry            [--json]")
	fmt.Fprintln(w, "  today   | list        show today's entries     [--days N] [--json]")
	fmt.Fprintln(w, "  tasks                 list cached tasks                 [--all] [--json]")
	fmt.Fprintln(w, "  update                refresh the project/task catalog  [--all] [--json]")
	fmt.Fprintln(w, "  push                  send local changes to Toggl       [--json]")
	fmt.Fprintln(w, "  pull                  fetch remote changes      [--since DATE] [--json]")
	fmt.Fprintln(w, "")
	fmt.Fprintln(w, "sync: run `tgl pull` then `tgl push` for correct last-writer-wins.")
	fmt.Fprintln(w, "env:  TOGGL_PROJECT_ID scopes `start` matches and sets the entry project.")
}

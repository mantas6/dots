package main

import (
	"encoding/json"
	"fmt"
	"io"
	"strconv"
	"strings"
	"time"

	"mantas6/tg/store"
)

// ceil5 rounds a duration up to the next 5 minutes, minimum 5 minutes.
func ceil5(d time.Duration) time.Duration {
	const s = 5 * time.Minute
	if d <= 0 {
		return s
	}
	return ((d + s - 1) / s) * s
}

// formatHM renders a duration as "<h>h<mm>m" (e.g. 75m -> "1h15m", 50m ->
// "0h50m"). Negative durations clamp to zero.
func formatHM(d time.Duration) string {
	if d < 0 {
		d = 0
	}
	total := int(d / time.Minute)
	return fmt.Sprintf("%dh%02dm", total/60, total%60)
}

// formatClock renders the wall-clock time (HH:MM) in loc.
func formatClock(t time.Time, loc *time.Location) string {
	return t.In(loc).Format("15:04")
}

// entryLabel is the task name, falling back to the free-form description.
func entryLabel(e store.Entry) string {
	if e.TaskName != "" {
		return e.TaskName
	}
	return e.Description
}

// displayDuration is the duration shown for an entry: live (un-rounded) elapsed
// while running, otherwise the stored quantized duration.
func displayDuration(e store.Entry, now time.Time) time.Duration {
	if e.Stop == nil {
		return now.Sub(e.Start)
	}
	return time.Duration(e.Duration) * time.Second
}

const todayDivider = "----------------------------------------"

// parseHexColor parses a "#RRGGBB" hex color (as stored on projects) into its
// 8-bit channels. ok is false for any other shape (empty, short, bad digits).
func parseHexColor(s string) (r, g, b uint8, ok bool) {
	if len(s) != 7 || s[0] != '#' {
		return 0, 0, 0, false
	}
	v, err := strconv.ParseUint(s[1:], 16, 32)
	if err != nil {
		return 0, 0, 0, false
	}
	return uint8(v >> 16), uint8(v >> 8), uint8(v), true
}

// colorBlock renders a small block tinted with the given "#RRGGBB" color via a
// 24-bit ANSI foreground escape, reset afterwards. Missing or malformed colors
// yield "" so callers never emit broken escape codes.
func colorBlock(hex string) string {
	r, g, b, ok := parseHexColor(hex)
	if !ok {
		return ""
	}
	return fmt.Sprintf("\x1b[38;2;%d;%d;%dm\u25a0\x1b[0m", r, g, b)
}

// gapThreshold is the smallest stop-to-start distance rendered as a gap line.
// Durations are quantized to 5-minute blocks (ceil5), so sub-minute gaps are
// rounding noise from adjacent entries rather than real idle time.
const gapThreshold = time.Minute

// gapBetween returns the idle time between prev and next worth showing, or 0.
// No gap is reported when prev is still running, when the entries overlap or
// sit closer than gapThreshold, or when they fall on different calendar days
// in loc (a "gap" across midnight is just the night, not tracked idle time).
func gapBetween(prev, next store.Entry, loc *time.Location) time.Duration {
	if prev.Stop == nil {
		return 0
	}
	gap := next.Start.Sub(*prev.Stop)
	if gap < gapThreshold {
		return 0
	}
	ps, ns := prev.Stop.In(loc), next.Start.In(loc)
	py, pm, pd := ps.Date()
	ny, nm, nd := ns.Date()
	if py != ny || pm != nm || pd != nd {
		return 0
	}
	return gap
}

// renderToday writes the human-readable daily table to w. color enables the
// per-project ANSI color block and should only be set when w is a terminal.
func renderToday(w io.Writer, entries []store.Entry, now time.Time, loc *time.Location, color bool) {
	if len(entries) == 0 {
		fmt.Fprintln(w, "No entries.")
		return
	}

	// leadPad is the blank lead-in that matches the width of a color block plus
	// its trailing space (the block is one display column). It keeps lines
	// without a project color aligned with colored ones in color mode, and is
	// empty when color is off so plain output carries no stray indentation.
	leadPad := ""
	if color {
		leadPad = "  "
	}

	var total time.Duration
	anyRunning := false
	for i, e := range entries {
		if i > 0 {
			if gap := gapBetween(entries[i-1], e, loc); gap > 0 {
				// Indented to the duration column so it reads as a filler row.
				fmt.Fprintf(w, "%s%-12s(gap %s)\n", leadPad, "", formatHM(gap))
			}
		}
		startClk := formatClock(e.Start, loc)
		stopClk := "  *"
		if e.Stop != nil {
			stopClk = formatClock(*e.Stop, loc)
		} else {
			anyRunning = true
		}
		dur := displayDuration(e, now)
		total += dur

		label := entryLabel(e)
		project := ""
		if e.ProjectName != "" {
			project = "[" + e.ProjectName + "]"
		}
		// Lead the line with the project's color block (padded to leadPad so
		// entries without a color still line up).
		lead := leadPad
		if color {
			if block := colorBlock(e.ProjectColor); block != "" {
				lead = block + " "
			}
		}
		fmt.Fprintf(w, "%s%-12s%-7s%-17s%s\n",
			lead, startClk+"-"+stopClk, formatHM(dur), label, project)
	}

	fmt.Fprintln(w, todayDivider)
	footer := "Total: " + formatHM(total)
	if anyRunning {
		footer += "   (* running)"
	}
	fmt.Fprintln(w, footer)
}

// currentJSON is the stable --json shape for `current`.
type currentJSON struct {
	Running        bool   `json:"running"`
	Task           string `json:"task,omitempty"`
	Project        string `json:"project,omitempty"`
	Start          string `json:"start,omitempty"`
	ElapsedSeconds int64  `json:"elapsed_seconds,omitempty"`
	ID             int64  `json:"id,omitempty"`
}

// renderCurrent writes the running entry (or its absence) to w.
func renderCurrent(w io.Writer, e *store.Entry, now time.Time, loc *time.Location, jsonOut bool) error {
	if jsonOut {
		out := currentJSON{Running: e != nil}
		if e != nil {
			out.Task = entryLabel(*e)
			out.Project = e.ProjectName
			out.Start = e.Start.UTC().Format(time.RFC3339)
			out.ElapsedSeconds = int64(now.Sub(e.Start) / time.Second)
			out.ID = e.ID
		}
		return writeJSON(w, out)
	}

	if e == nil {
		fmt.Fprintln(w, "No entry running.")
		return nil
	}
	elapsed := formatHM(now.Sub(e.Start))
	label := entryLabel(*e)
	if e.ProjectName != "" {
		label += " [" + e.ProjectName + "]"
	}
	fmt.Fprintf(w, "Running: %s since %s (%s)\n", label, formatClock(e.Start, loc), elapsed)
	return nil
}

// todayEntryJSON / todayJSON are the stable --json shapes for `today`.
type todayEntryJSON struct {
	ID              int64  `json:"id"`
	Task            string `json:"task,omitempty"`
	Project         string `json:"project,omitempty"`
	Description     string `json:"description,omitempty"`
	Start           string `json:"start"`
	Stop            string `json:"stop,omitempty"`
	DurationSeconds int64  `json:"duration_seconds"`
	Running         bool   `json:"running"`
}

type todayJSON struct {
	Entries      []todayEntryJSON `json:"entries"`
	TotalSeconds int64            `json:"total_seconds"`
}

// renderTodayJSON writes the daily entries as the stable JSON shape.
func renderTodayJSON(w io.Writer, entries []store.Entry, now time.Time) error {
	out := todayJSON{Entries: []todayEntryJSON{}}
	var total time.Duration
	for _, e := range entries {
		dur := displayDuration(e, now)
		total += dur
		je := todayEntryJSON{
			ID:              e.ID,
			Task:            e.TaskName,
			Project:         e.ProjectName,
			Start:           e.Start.UTC().Format(time.RFC3339),
			DurationSeconds: int64(dur / time.Second),
			Running:         e.Stop == nil,
		}
		if e.TaskName == "" {
			je.Description = e.Description
		}
		if e.Stop != nil {
			je.Stop = e.Stop.UTC().Format(time.RFC3339)
		}
		out.Entries = append(out.Entries, je)
	}
	out.TotalSeconds = int64(total / time.Second)
	return writeJSON(w, out)
}

// taskRow is the stable --json shape for `tasks`.
type taskRow struct {
	ID      int64  `json:"id"`
	Name    string `json:"name"`
	Project string `json:"project,omitempty"`
	Active  bool   `json:"active"`
}

// renderTasks writes the catalog task list, aligning the project column to the
// widest task name.
func renderTasks(w io.Writer, tasks []store.Task) {
	if len(tasks) == 0 {
		fmt.Fprintln(w, "No tasks. Run `tg update` to refresh the catalog.")
		return
	}
	width := 0
	for _, t := range tasks {
		if n := len(t.Name); n > width {
			width = n
		}
	}
	for _, t := range tasks {
		if t.ProjectName != "" {
			fmt.Fprintf(w, "%-*s  [%s]\n", width, t.Name, t.ProjectName)
		} else {
			fmt.Fprintln(w, t.Name)
		}
	}
}

// renderTasksJSON writes the catalog tasks as the stable JSON shape.
func renderTasksJSON(w io.Writer, tasks []store.Task) error {
	out := make([]taskRow, 0, len(tasks))
	for _, t := range tasks {
		out = append(out, taskRow{ID: t.ID, Name: t.Name, Project: t.ProjectName, Active: t.Active})
	}
	return writeJSON(w, out)
}

// projectRow is the stable --json shape for `projects`.
type projectRow struct {
	ID       int64  `json:"id"`
	Name     string `json:"name"`
	Client   string `json:"client,omitempty"`
	Active   bool   `json:"active"`
	Billable bool   `json:"billable"`
}

// renderProjects writes the catalog project list with ids, leading with the id
// column (right-aligned) so it can be exported as TOGGL_PROJECT_ID.
func renderProjects(w io.Writer, projects []store.Project) {
	if len(projects) == 0 {
		fmt.Fprintln(w, "No projects. Run `tg update` to refresh the catalog.")
		return
	}
	width := 0
	for _, p := range projects {
		if n := len(strconv.FormatInt(p.ID, 10)); n > width {
			width = n
		}
	}
	for _, p := range projects {
		if p.ClientName != "" {
			fmt.Fprintf(w, "%*d  %s  [%s]\n", width, p.ID, p.Name, p.ClientName)
		} else {
			fmt.Fprintf(w, "%*d  %s\n", width, p.ID, p.Name)
		}
	}
}

// renderProjectsJSON writes the catalog projects as the stable JSON shape.
func renderProjectsJSON(w io.Writer, projects []store.Project) error {
	out := make([]projectRow, 0, len(projects))
	for _, p := range projects {
		out = append(out, projectRow{
			ID: p.ID, Name: p.Name, Client: p.ClientName,
			Active: p.Active, Billable: p.Billable,
		})
	}
	return writeJSON(w, out)
}

// writeJSON emits compact JSON followed by a newline.
func writeJSON(w io.Writer, v any) error {
	data, err := json.Marshal(v)
	if err != nil {
		return err
	}
	_, err = fmt.Fprintln(w, string(data))
	return err
}

// candidateList renders task match candidates for the ambiguous `start` case.
func candidateList(tasks []store.Task) string {
	var b strings.Builder
	for _, t := range tasks {
		fmt.Fprintf(&b, "  %s\n", t.Name)
	}
	return b.String()
}

// projectCandidateList renders project match candidates (name + id) for the
// ambiguous `pull` case so the fragment can be refined or the id exported.
func projectCandidateList(projects []store.Project) string {
	var b strings.Builder
	for _, p := range projects {
		fmt.Fprintf(&b, "  %s (%d)\n", p.Name, p.ID)
	}
	return b.String()
}

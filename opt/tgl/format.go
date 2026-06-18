package main

import (
	"encoding/json"
	"fmt"
	"io"
	"strings"
	"time"

	"mantas6/tgl/store"
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

// renderToday writes the human-readable daily table to w.
func renderToday(w io.Writer, entries []store.Entry, now time.Time, loc *time.Location) {
	if len(entries) == 0 {
		fmt.Fprintln(w, "No entries.")
		return
	}

	var total time.Duration
	anyRunning := false
	for _, e := range entries {
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
		fmt.Fprintf(w, "%-12s%-7s%-17s%s\n",
			startClk+"-"+stopClk, formatHM(dur), label, project)
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

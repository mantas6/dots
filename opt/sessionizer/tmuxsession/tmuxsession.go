package tmuxsession

import (
	"strconv"
	"strings"
)

const LineFormat = "#{session_last_attached} #{session_name} #{session_path}"

type TmuxSession struct {
	Name         string
	Path         string
	LastAttached int
}

func CreateFromLine(line string) TmuxSession {
	parts := strings.SplitN(line, " ", 3)

	lastAttached, _ := strconv.Atoi(parts[0])

	return TmuxSession{
		LastAttached: lastAttached,
		Name:         parts[1],
		Path:         parts[2],
	}
}

package tmuxsession

import (
	"strconv"
	"strings"
)

// session_last_attached is empty for sessions that were never attached, which
// would leave a leading space that gets trimmed away with the rest of the
// output and shift every field of the first line
const LineFormat = "#{?session_last_attached,#{session_last_attached},0} #{session_name} #{session_path}"

type TmuxSession struct {
	Name         string
	Path         string
	LastAttached int
}

// NewFromLine parses a LineFormat line. A session with an empty Name means the
// line was malformed and should be skipped.
func NewFromLine(line string) TmuxSession {
	parts := strings.SplitN(line, " ", 3)
	if len(parts) < 3 {
		return TmuxSession{}
	}

	lastAttached, _ := strconv.Atoi(parts[0])

	return TmuxSession{
		LastAttached: lastAttached,
		Name:         parts[1],
		Path:         parts[2],
	}
}

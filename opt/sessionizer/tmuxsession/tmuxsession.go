package tmuxsession

import (
	"strconv"
	"strings"
)

type TmuxSession struct {
	Name         string
	Path         string
	LastAttached int
}

func CreateFromLineItem(line string) TmuxSession {
	parts := strings.SplitN(line, " ", 3)

	lastAttached, _ := strconv.Atoi(parts[0])

	return TmuxSession{
		LastAttached: lastAttached,
		Name:         parts[1],
		Path:         parts[2],
	}
}

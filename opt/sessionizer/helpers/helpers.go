package helpers

import (
	"os"
	"path/filepath"
	"strings"
)

func ExpandWildcardPaths(pattern string) []string {
	if strings.HasPrefix(pattern, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return []string{}
		}

		pattern = filepath.Join(home, pattern[2:])
	}

	matches, err := filepath.Glob(pattern)
	if err != nil {
		return []string{}
	}

	return matches
}

func RemoveHomeFromPath(path string) string {
	home, err := os.UserHomeDir()
	if err != nil {
		return path
	}

	trimmed := strings.TrimPrefix(path, home)
	if trimmed != path {
		return "~" + trimmed
	}

	return path
}

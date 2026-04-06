package main

import (
	"os"
	"path/filepath"
	"strings"
)

func expandWildcardPaths(pattern string) []string {
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

func expandHome(path string) string {
	if strings.HasPrefix(path, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return path
		}
		return filepath.Join(home, path[2:])
	}
	return path
}

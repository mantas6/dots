package main

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestExpandWildcardPathsOnlyDirectories(t *testing.T) {
	root := t.TempDir()
	for _, name := range []string{"project", "project with spaces", ".hidden"} {
		if err := os.Mkdir(filepath.Join(root, name), 0o700); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(root, "README.md"), []byte("notes"), 0o600); err != nil {
		t.Fatal(err)
	}
	for name, target := range map[string]string{
		"linked-project": "project",
		"linked-file":    "README.md",
		"broken-link":    "missing",
	} {
		if err := os.Symlink(target, filepath.Join(root, name)); err != nil {
			t.Fatal(err)
		}
	}

	got := expandWildcardPaths(filepath.Join(root, "*"))
	want := []string{
		filepath.Join(root, "linked-project"),
		filepath.Join(root, "project"),
		filepath.Join(root, "project with spaces"),
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("expandWildcardPaths() = %q, want %q", got, want)
	}
}

func TestExpandWildcardPathsEmptyMatches(t *testing.T) {
	for _, pattern := range []string{filepath.Join(t.TempDir(), "*"), "["} {
		if got := expandWildcardPaths(pattern); len(got) != 0 {
			t.Fatalf("expandWildcardPaths(%q) = %q, want no matches", pattern, got)
		}
	}
}

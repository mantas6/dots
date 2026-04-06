package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		return
	}

	switch os.Args[1] {
	case "list":
		cmdList()
	case "last":
		cmdLast()
	case "connect":
		cmdConnect()
	default:
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Fprintf(os.Stderr, "usage: %s <command>\n", os.Args[0])
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "commands:")
	fmt.Fprintln(os.Stderr, "  list            list sessions")
	fmt.Fprintln(os.Stderr, "  last            switch to last accessed session")
	fmt.Fprintln(os.Stderr, "  connect <name>  connect to a session by name")
}

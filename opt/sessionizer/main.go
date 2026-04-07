package main

import "os"

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

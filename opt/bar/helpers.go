package main

import "fmt"

func formatBytes(bytes int64) string {
	bytes /= 1024
	sign := "K"

	if (bytes > 1024) {
		bytes /= 1024
		sign = "M"
	}

	if (bytes > 1024) {
		bytes /= 1024
		sign = "G"
	}

	return fmt.Sprintf("%v%s", bytes, sign)
}

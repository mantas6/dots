package main

import "fmt"

func formatBytes(bytes int64) string {
	bytes /= 1024
	sign := "K"

	if (bytes > 1024) {
		bytes /= 1024
		sign = "M"
	}

	return fmt.Sprintf("%v%s", bytes, sign)
}

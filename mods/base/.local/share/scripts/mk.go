#!/usr/bin/env sh

[ -f "$1" ] && exit 1

echo '//usr/bin/go run $0 $@ ; exit $?' >> "$1"
echo '// vim: set filetype=go:' >> "$1"
echo '' >> "$1"
echo 'package main' >> "$1"
echo '' >> "$1"
echo 'import "fmt"' >> "$1"
echo '' >> "$1"
echo 'func main() {' >> "$1"
echo '  fmt.Println("Hello, world!")' >> "$1"
echo '}' >> "$1"

chmod +x "$1"

[ "$2" = '-e' ] && nvim "$1"

exit 0

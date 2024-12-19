#!/usr/bin/env sh

[ -f "$1" ] && exit 1

echo '#!/usr/bin/env bash' >> "$1"
chmod +x "$1"

[ "$2" = '-e' ] && nvim "$1"

exit 0

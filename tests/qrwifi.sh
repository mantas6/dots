#!/usr/bin/env bash
# Check Wi-Fi payloads without accessing pass or generating real QR images.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
workdir=$(mktemp -d "$repo/tests/.qrwifi.XXXXXX")
trap 'rm -rf -- "$workdir"' EXIT
mkdir -p "$workdir/bin" "$workdir/home"

# Variables expand when the mock runs, not while it is written.
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env sh' \
    '[ "$#" -eq 1 ] && [ "$1" = local/wifi ] || exit 1' \
    'printf "%s\n" "$TEST_PASSWORD"' >"$workdir/bin/pass"
# Variables expand when the mock runs, not while it is written.
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env sh' \
    'printf "%s\n" "$@" > "$TEST_QR_LOG"' \
    'exit "${TEST_QR_STATUS:-0}"' >"$workdir/bin/qrencode"
chmod +x "$workdir/bin/pass" "$workdir/bin/qrencode"

export PATH="$workdir/bin:$PATH" HOME="$workdir/home"
export TEST_QR_LOG="$workdir/actual"
cd "$workdir"

check_password() {
    export TEST_PASSWORD="$1"
    printf '%s\n' '-o' 'Wildcard.png' "WIFI:S:Wildcard;T:WPA;P:$2;;" >"$workdir/expected"
    sh "$repo/bin/qrwifi"
    diff -u "$workdir/expected" "$TEST_QR_LOG"
}

check_password 'ordinary-password' 'ordinary-password'
check_password 'semi;colon' 'semi\;colon'
check_password 'back\slash' 'back\\slash'
check_password 'comma,colon:quote"' 'comma\,colon\:quote\"'
check_password 'mixed\;,:"& text' 'mixed\\\;\,\:\"& text'
check_password '-literal & spaces ą' '-literal & spaces ą'
check_password $'first;line\nNotes: ignored;metadata' 'first\;line'

export TEST_QR_STATUS=23
if sh "$repo/bin/qrwifi"; then
    printf '%s\n' 'Expected qrencode failure to propagate' >&2
    exit 1
else
    status=$?
    [[ "$status" -eq 23 ]]
fi
printf '%s\n' 'PASS: seven password fixtures and qrencode exit status'

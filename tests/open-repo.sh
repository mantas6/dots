#!/usr/bin/env bash
# Run with: bash tests/open-repo.sh
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
fixture=$(mktemp -d "$root/tests/.open-repo.XXXXXX")
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin" "$fixture/home" "$fixture/repo"
export HOME="$fixture/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export PATH="$fixture/bin:$PATH" OPEN_REPO_LOG="$fixture/opened"

# shellcheck disable=SC2016 # Expand variables when the mock runs.
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$@" > "$OPEN_REPO_LOG"' 'exit "${OPEN_REPO_STATUS:-0}"' >"$fixture/bin/open-url"
chmod +x "$fixture/bin/open-url"
git init -q "$fixture/repo"
cd "$fixture/repo"

check_url() {
    local remote=$1 expected=$2
    git config remote.origin.url "$remote"
    rm -f "$OPEN_REPO_LOG"
    bash "$root/bin/open-repo"
    printf '%s\n' "$expected" >"$fixture/expected"
    diff -u "$fixture/expected" "$OPEN_REPO_LOG"
    printf 'PASS: %s\n' "$remote"
}

check_url 'git@github.com:example/project.git' 'https://github.com/example/project'
check_url 'git@github.com:example/project' 'https://github.com/example/project'
check_url 'git@gitlab.com:group/subgroup/project' 'https://gitlab.com/group/subgroup/project'
check_url 'git@github.com:example/project.git.git' 'https://github.com/example/project.git'
check_url 'https://github.com/example/project.git' 'https://github.com/example/project'
check_url 'https://github.com/example/project' 'https://github.com/example/project'
check_url 'http://git.example.test/group/project.git' 'http://git.example.test/group/project'

for remote in '/local/repository' 'git@github.com:'; do
    git config remote.origin.url "$remote"
    rm -f "$OPEN_REPO_LOG"
    if bash "$root/bin/open-repo" >"$fixture/output" 2>&1; then
        printf 'FAIL: accepted unsupported remote %s\n' "$remote" >&2
        exit 1
    fi
    [[ ! -e "$OPEN_REPO_LOG" ]]
    printf 'PASS: unsupported remote rejected\n'
done

git config remote.origin.url 'git@github.com:example/project'
status=0
OPEN_REPO_STATUS=23 bash "$root/bin/open-repo" || status=$?
[[ $status == 23 ]]
printf 'PASS: opener failure propagated\n'

git config --unset remote.origin.url
rm -f "$OPEN_REPO_LOG"
if bash "$root/bin/open-repo"; then
    printf 'FAIL: accepted missing origin\n' >&2
    exit 1
fi
[[ ! -e "$OPEN_REPO_LOG" ]]
printf 'PASS: missing origin rejected\n'

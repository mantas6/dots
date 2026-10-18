#!/usr/bin/env bash
# Run with: bash tests/start-tmux-session.sh (requires Git; tmux is mocked).

set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "$repo/tests/.start-tmux-session.XXXXXX")
trap 'rm -rf -- "$fixture"' EXIT

mkdir -p "$fixture/bin" "$fixture/plain" "$fixture/composer" "$fixture/npm"
cat >"$fixture/bin/tmux" <<'EOF'
#!/usr/bin/env sh
printf '<%s>' "$@" >> "$TMUX_TEST_LOG"
printf '\n' >> "$TMUX_TEST_LOG"
EOF
chmod +x "$fixture/bin/tmux"
export PATH="$fixture/bin:$PATH"
export TMUX_TEST_LOG="$fixture/actual"
export ADDITIONAL_CMD='' ADDITIONAL_WINDOW_CMD=''
# Do not let the caller's Git context affect the isolated fixture repositories.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR

git init -q "$fixture/repository"
git -C "$fixture/repository" -c user.name=Fixture -c user.email=fixture@example.invalid \
    -c commit.gpgSign=false commit -qm fixture --allow-empty
git -C "$fixture/repository" worktree add -q --detach "$fixture/worktree with spaces"
git init -q --separate-git-dir="$fixture/separate-metadata" "$fixture/separate"
touch "$fixture/composer/composer.json" "$fixture/npm/package.json"

cat >"$fixture/expected" <<'EOF'
<rename-window><vi>
<send-keys><nvim .><C-m>
<new-window><-n><ex>
<new-window><-n><git>
<send-keys><onefetch><C-m>
<new-window><-n><tin>
<new-window><-n><llm>
<send-keys><opencode --continue><C-m>
<select-window><-t><vi>
EOF

check_project() {
    : >"$TMUX_TEST_LOG"
    (cd -- "$fixture/$1" && sh "$repo/bin/start-tmux-session")
    diff -u "$fixture/expected" "$TMUX_TEST_LOG"
    printf 'PASS: %s\n' "$1"
}

check_project repository
[[ -f "$fixture/worktree with spaces/.git" ]]
check_project 'worktree with spaces'
[[ -f "$fixture/separate/.git" ]]
check_project separate
check_project composer
check_project npm

: >"$TMUX_TEST_LOG"
(cd -- "$fixture/plain" && sh "$repo/bin/start-tmux-session")
[[ ! -s "$TMUX_TEST_LOG" ]]
printf 'PASS: plain directory leaves tmux untouched\n'

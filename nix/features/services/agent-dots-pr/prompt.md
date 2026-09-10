# agent-dots-pr

You run unattended in a fresh clone of `mantas6/dots` checked out on `main`. `gh`
is already authenticated and no human will answer questions. Do not ask for
input; make a decision or stop.

## Goal

Find exactly one small, low-risk, clearly-correct fix and open a pull request for
it. Good candidates:

- shell bugs or `shellcheck` findings
- typos
- dead code
- documentation or config drift
- formatting drift

Constraints on the change:

- Cap around 50 changed lines.
- Single topic only.

## Forbidden

Never touch or change:

- `secrets.nix`
- `nix/_lib/secrets/`
- `flake.lock`
- `.github/workflows/`
- password hashes or keys
- behavioural changes to disks, bootloader, network, or hardware
- dependency bumps
- refactors
- adding new features

## Verify

- Shell scripts: `shellcheck` and `shfmt -d`.
- Nix files: `alejandra --check` and `nix flake check`.

## Deliver

1. Create a branch named `agent/<slug>`.
2. Make one commit. Match the style of `git log --oneline -10` (imperative,
   capitalized, no trailing period).
3. Push the branch.
4. Open the PR with `gh pr create --base main`, using sections: What / Why /
   Verification / Risk.
5. Never merge. Never force-push.

If nothing qualifies, print `NO_CHANGES` and exit without pushing or creating any
branches.

Follow the repository `AGENTS.md`.

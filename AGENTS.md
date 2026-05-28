# AGENTS.md

## Overview

This is a dotfiles repository that manages configuration for both NixOS Linux systems and macOS.

## Scope

Only read and modify files within this repository. Never read or write files directly in the user's home directory (`~`). All dotfile changes must be made inside the repo (e.g. `home/`, `bin/`) and deployed via stow.

## Bash/Shell Script Conventions

- Shebang: `#!/usr/bin/env bash` (or `#!/usr/bin/env sh` for POSIX)
- Optional one-line comment on line 2 describing the script's purpose
- Keep scripts direct and concise, minimal boilerplate
- Prefer shorthand conditionals for simple single-action checks: `[[ condition ]] && action`
- Use full `if...then...fi` for multi-statement blocks
- Always use `shfmt` for formatting

## Verification

- After changing any Nix files (`nix/`, `flake.nix`, `flake.lock`), run `nix flake check` to validate the configuration

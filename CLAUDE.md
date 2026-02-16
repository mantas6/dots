# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository that manages configuration for both NixOS Linux systems and macOS. It uses GNU Stow for symlink management.

## Repository Structure

- `home/` - Dotfiles stowed to `$HOME` (contains `.config/` for XDG configs)
- `bin/` - Scripts stowed to `~/.local/sbin`, organized by category:
  - `all/` - General utilities
  - `dot/` - Dotfiles management (`stw`, `dchk`, `init-dots`)
  - `mac/` - macOS-specific scripts
  - `sat/` - SAT work-related tools
- `nix/` - NixOS configurations
  - `hosts/` - Per-machine configs (ix, l4, tp, pd, amd, rt, iso)
  - `modules/` - Shared NixOS modules
- `sh/` - Shell configs (zprofile.d/, zshrc.d/ sourced in order by prefix number)
- `opt/` - Optional projects (kbd, wolf)
- `etc/dirs.conf` - Directories created before stow runs

## How Stow Works

The `stw` script:
1. Creates base directories from `etc/dirs.conf` to prevent Stow from linking entire directories
2. Stows `home/` to `$HOME`
3. Stows all `bin/` subdirectories to `~/.local/sbin`

## Environment Variables

- `DOTS_DIR` - Points to this repository (used by `dchk` and other scripts)
- `XDG_CONFIG_HOME` - Set to `~/.config`

## Nix Hosts

Defined in `flake.nix`: ix, l4, tp, pd, amd, rt, iso (installer)

## Bash/Shell Script Conventions

- Shebang: `#!/usr/bin/env bash` (or `#!/usr/bin/env sh` for POSIX)
- Optional one-line comment on line 2 describing the script's purpose
- Keep scripts direct and concise, minimal boilerplate
- Prefer shorthand conditionals for simple single-action checks: `[[ condition ]] && action`
- Use full `if...then...fi` for multi-statement blocks
- Always use `shfmt` for formatting

## Verification

- After changing any Nix files (`nix/`, `flake.nix`, `flake.lock`), run `nix flake check` to validate the configuration

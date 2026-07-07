# dash

Deterministic stats dashboard for this repository, deployed to GitHub Pages on
a weekly schedule (and on manual `workflow_dispatch`).

## What it shows

- **Code over time** — lines/files per language, sampled at the last commit of
  each month across the full git history (counts all git-tracked files).
- **Hosts × features** — which flake-parts `nixosModules` each host imports.
- **Nix modules** — every `flake.nixosModules.*` and the file(s) defining it,
  grouped by category.
- **Scripts** — `bin/` scripts with their self-described purpose (line-2 comment
  for shell, head docblock for PHP).

## Generate locally

```sh
nix develop .#dash -c ./opt/dash/generate.sh opt/dash/out
```

Output goes to `opt/dash/out/` (gitignored): the static `site/` plus
`data/*.json`. Serve it with any static server, e.g.:

```sh
python3 -m http.server -d opt/dash/out
```

## How it works

- `generate.sh` — orchestrator; copies `site/` and runs each generator in `lib/`.
- `lib/languages.sh` — `git archive` per month → `tokei` → `data/languages.json`.
- `lib/nix-modules.sh` — parses `nix/**` → `data/modules.json`.
- `lib/hosts.sh` — parses each host's `imports` block → `data/hosts.json`.
- `lib/scripts.sh` — scans `bin/**` → `data/scripts.json`.
- `site/` — static page (Tailwind + Chart.js via CDN) that fetches the JSON.

Tools (`tokei`, `jq`, `git`) are pinned via the `dash` devShell in
`nix/dash.nix`, so a given commit always produces the same data.

## One-time setup (manual)

1. Repo **Settings → Pages → Source: GitHub Actions**.
2. After the first deploy, set the repo homepage link:

   ```sh
   gh repo edit --homepage https://<user>.github.io/<repo>/
   ```

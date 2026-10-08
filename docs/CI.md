All three Woodpecker reports are in. Here is the rewritten plan.

**Short version.** Woodpecker covers the hard parts of the original idea: Bitbucket Cloud login, PR webhooks, build statuses, a UI with live logs and restart, cancel-previous, approvals, secrets, and NixOS modules for server and agent. What is left for you is a fixed pipeline that runs the script, a failure comment step, a public webhook endpoint, hardening of the agent, and some operational glue Woodpecker lacks. Two things from the original idea still do not survive: title emojis, and "every updated PR triggers a run" now works too well, because title edits re-run CI.

## What Woodpecker changes about the original plan

- **Repos can still carry only the script.** Woodpecker's config extension can serve one server-side pipeline for every repo. Run it in exclusive mode so in-repo yaml is ignored and PR authors cannot change the pipeline. The endpoint must listen on loopback and should verify Woodpecker's ed25519 request signatures, because local-backend steps can reach loopback too. The served pipeline is roughly this:

```yaml
when: [{event: pull_request}]
clone:
  - name: clone
    image: woodpeckerci/plugin-git
    settings: {partial: false, merge_pull_request: true}
steps:
  - name: kaimoci
    image: bash
    commands: [./.kaimoci]
```

- **Webhooks are mandatory, there is no polling.** Bitbucket must reach the hook endpoint from the public internet. Use a separate webhook host setting so only the hook path is public while the UI stays on your tailnet or behind your existing Caddy pattern. Cloudflare Tunnel breaks Bitbucket login because it cuts the SSE stream. Woodpecker sets no webhook secret, so the per-repo signed token in the hook URL is the only auth. Treat that URL as a secret and strip query strings from proxy logs.
- **Title edits re-run CI.** Woodpecker maps both PR created and PR updated to the same event and does no SHA dedup, so a title, description or reviewer edit cancels the running pipeline and starts a new one on the same commit. A workflow-level evaluate expression comparing the previous pipeline's commit can filter these, but that is untested.
- **Title emoji is now guaranteed to loop.** The edit fires an update event, Woodpecker starts a new pipeline, cancel-previous kills the one that edited, and the new one edits again. It also needs a write scope that grants push access. Use the Builds indicator and the "minimum successful builds" merge check, which only enforces on Premium.
- **Comments need a step you write.** Nothing in the plugin index does Bitbucket comments. A failure-only step can tee the script output, find the bot's existing comment by a marker, and update it in place, using a repository access token with the pull request scope stored as a repo secret. The log tail can leak secrets into the PR, since Woodpecker only masks in its own UI.
- **The checkout is the PR head, not the merge.** The plugin-git clone settings above merge the target branch and fail the clone on conflict. Statuses still attach to the source SHA.
- **You need 3.19.0, nixpkgs ships 3.18.0.** Two Bitbucket fixes landed yesterday: activating a repo that already has any webhook fails on 3.18, and Bitbucket's single-use refresh tokens break the login user. Override the package until nixpkgs catches up.

| Item | Value |
| --- | --- |
| Woodpecker in nixos-26.05 and unstable | 3.18.0 |
| Latest upstream | 3.19.0 (2026-10-07) |
| Default pipeline timeout | 60 min, max 120 |
| Agent job lease after agent death | about 1 min, then re-run |
| Bitbucket status key limit | 40 chars, default key is 24 |

## Decisions you need to make

1. **Backend.** The local backend runs steps as the agent's user with the agent's full environment, so any pusher can read the agent token, pull other repos' queued jobs including their secrets and the bot's Bitbucket token, and post fake successes. Rootless Podman with the host Nix store and daemon socket mounted read-only fixes that at the cost of building a CI image and Podman setup. Recommended for v1: hardened local, if the team is trusted and no valuable secret gets the pull request event. Otherwise rootless Podman.
2. **Local backend hardening, if chosen.** Single-workflow mode with Restart=always so every workflow gets a fresh cgroup and private tmp. One agent instance per concurrency slot, each with its own dynamic user. Per-agent tokens from the UI, no shared system secret, and user agent registration disabled. Token via LoadCredential, never via the module's environment file. Disable MemoryDenyWriteExecute or Node and JVM crash. The syscall filter kills bwrap and unshare with SIGSYS, so no nested sandboxing inside scripts. Add memory, task and CPU limits, deny private IP ranges, and make the nix daemon's own unit memory-limited since builds escape the agent cgroup.
3. **Bot account.** Activate repos as a dedicated Bitbucket bot with repo admin rights. Its OAuth token does all cloning and status posting. If the owner leaves, another admin must chown the repo and then repair it, in that order. An idle repo for over 3 months needs a fresh login.
4. **Approval mode.** The default requires approval for fork PRs only. Approved fork PRs receive every pull request secret, since Woodpecker has no GitHub-style fork exclusion. Approving needs push rights and self-approval is allowed.
5. **Secrets strategy.** Secrets are stored in plaintext in the database next to OAuth tokens, because at-rest encryption is commented out upstream. Keep sensitive secrets off the pull request event entirely. For declarative management either sync from agenix with a boot-time CLI oneshot, or run the secret extension served from agenix files.
6. **Nix inside jobs.** On local, put nix on the agent PATH and use the daemon. On Podman, mount the host store read-only plus the daemon socket, and never make the CI user a trusted Nix user. Rootful containers would make container root equal host root, which the daemon trusts, so rootless is required for that option.
7. **Public exposure.** Caddy with ACME, matching the app-server pattern already in this repo, versus Tailscale Funnel on port 8443 for the hook path only. Caddy is simpler here and allows IP allowlisting of Atlassian ranges.
8. **Dedup of metadata edits.** Accept the re-runs, or ship the evaluate filter after testing it on a real repo.

## Things to build or design in

- **NixOS feature module.** Server with SQLite, file log store, Bitbucket forge from an agenix environment file, gRPC bound to localhost, admin set to the bot username, workspace allowlist. Agent with StateDirectory so its ID persists, healthcheck bound to localhost since the default listens on all interfaces, and the default port moved because sat's Octane already uses 8000. The research produced a full sketch in your flake-parts style that I can turn into a module when you want it.
- **Retention and disk.** Woodpecker has no log retention or total log size cap. Add a timer running the CLI purge per repo, put the temp dir and log store on a quota'd filesystem, and vacuum SQLite after purges.
- **Resilience gaps you inherit.** Webhooks missed while the server is down are lost, and Bitbucket retries only twice on 5xx. Status post failures are logged and not retried. An agent death re-runs the workflow from scratch under the same number. On the docker backend, leftover containers are not cleaned on agent restart.
- **Alerting.** None built in. Use systemd OnFailure, a Prometheus scrape of the metrics endpoint with its bearer token, and a cron pipeline that pings a dead-man's switch so the whole queue, agent and execution path is exercised.
- **Script contract under Woodpecker.** The useful variables are the commit SHA, source and target branch, PR id, pipeline URL, and the PR title in the commit message variable. The draft flag is always false on Bitbucket, so drafts cannot be skipped. Path filters do work on Bitbucket despite the stale docs page. A skip-ci marker is checked against the PR title, not commit messages.
- **Queued pipelines can fail to clone.** The clone credentials are generated at pipeline creation, so anything waiting longer than roughly an hour in the queue fails. Keep enough agent slots or use an SSH deploy key for cloning.
- **Backups.** SQLite backup plus the log directory, encrypted, since the database holds plaintext secrets.

Untested items worth a half-day spike before committing: the exclusive config extension actually serving repos with no yaml, the evaluate dedup expression, the comment step's Bitbucket query filter, and Funnel path handling if you go that route. The first concrete step is to override the package to 3.19.0, deploy server plus one local agent on a test host, activate one repo as the bot, and open a PR with a trivial script.

# agent-dots-pr

You run unattended in a fresh clone of the synchronized
`mantas6-agent/dots-agent` fork checked out on `main`. Its `origin` remote is the
fork and its `upstream` remote is `mantas6/dots`. `gh` is already authenticated
and no human will answer questions. Do not ask for input; make a decision or
stop.

## Goal

Find exactly one small, low-risk, clearly-correct fix and open a pull request for
it. Good candidates:

- shell bugs or `shellcheck` findings
- typos
- dead code
- documentation or config drift
- formatting drift

Constraints on the change:

- Single topic only.

## Deliver

1. Create a branch named `agent/<slug>` from `main`.
2. Commit the change with a concise imperative subject (capitalized, no trailing
   period).
3. Push the branch to `origin` with `git push --set-upstream origin HEAD`.
4. Open a PR from `mantas6-agent:<branch>` to `mantas6/dots:main` using the REST
   API because `gh pr create` does not support organization-owned head forks:

   ```sh
   GH_TOKEN="$UPSTREAM_GH_TOKEN" gh api \
     --method POST repos/mantas6/dots/pulls \
     --field title='<title>' \
     --field head="mantas6-agent:<branch>" \
     --field base=main \
     --field body='<body>' \
     --jq .html_url
   ```

   The body must use sections: What / Why / Verification / Risk.
5. Never merge. Never force-push.

If nothing qualifies, print `NO_CHANGES` and exit without pushing or creating any
branches.

Follow the repository `AGENTS.md`.

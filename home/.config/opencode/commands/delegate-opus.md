---
description: Run the current plan in Opus subagents
agent: build
---

Execute current plan in separate `general` subagents / todos, explicitly using model `claude-agent/opus#high` for each subagent. Commit and push after each, when all is done execute `sat notify "{} done"`, replace `{}` with repo name.

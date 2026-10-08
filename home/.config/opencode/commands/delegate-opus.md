---
agent: build
---

Execute current plan in separate `general` subagents / todos, explicitly using model `anthropic/claude-opus-5-5#high` for each subagent. Commit and push after each, when all is done execute `sat notify "{} done"`, replace `{}` with repo name.

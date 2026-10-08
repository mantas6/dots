---
agent: build
---

Execute current plan in separate `general` subagents / todos, explicitly using model `openai/gpt-6.1-sol#high` or `openai/gpt-6.1-sol#medium` for each subagent, depending on complexity. Commit and push after each, when all is done execute `sat notify "{} done"`, replace `{}` with repo name.

---
name: delegate-gpt
agent: build
---

Execute current plan in separate gpt (sol or terra, depending on complexity) subagents / todos. Commit after each, push when all is done + execute `sat-notify "{} done"`, replace `{}` with repo name.

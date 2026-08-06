---
agent: build
---

Execute current plan in separate gpt (sol high, sol medium or terra, depending on complexity) subagents / todos. Commit and push after each, when all is done execute `sat-notify "{} done"`, replace `{}` with repo name.

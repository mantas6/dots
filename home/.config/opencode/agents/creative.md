---
description: Creative and divergent thinking with high variability
mode: subagent
temperature: 0.8
permission:
  edit: deny
  write: deny
  bash:
    "*": deny
    "git log*": allow
    "git diff*": allow
    "git status*": allow
---

Be creative. You cannot modify files or run destructive commands.

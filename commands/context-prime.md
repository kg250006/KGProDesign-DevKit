---
command: context-prime
description: Prime context for claude code before starting a new task
arguments: Specify the area of the codebase where you will be working on.
---

Read README.md, THEN run git ls-files | grep -v -f (sed 's|^|^|; s|$|/|' .cursorignore | psub) to understand the context of the project

the user might specify the area of the codebase where they will be working on here: $ARGUMENTS

---
description: "[KGP] Prime context for Claude Code before starting a new task"
argument-hint: "[area of the codebase you will be working on]"
allowed-tools: [Read, Bash, Glob, Grep]
---

Read README.md, then run `git ls-files` (respecting any ignore files) to understand the context of the project.

The user might specify the area of the codebase where they will be working on here: $ARGUMENTS

If a `PRPs/` directory exists, list any PRP files and note which appear in-flight (rows in `.claude/prp-task-progress.md`).

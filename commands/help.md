---
description: "[KGP] Explain Ralph Loop plugin and available commands"
---

# Ralph Loop Plugin Help

Please explain the following to the user:

## What is Ralph Loop?

Ralph Loop implements the Ralph Wiggum technique - an iterative development methodology based on continuous AI loops, pioneered by Geoffrey Huntley.

**Core concept:**
```bash
while :; do
  cat PROMPT.md | claude-code --continue
done
```

The same prompt is fed to Claude repeatedly. The "self-referential" aspect comes from Claude seeing its own previous work in the files and git history, not from feeding output back as input.

**Each iteration:**
1. Claude receives the SAME prompt
2. Works on the task, modifying files
3. Tries to exit
4. Stop hook intercepts and feeds the same prompt again
5. Claude sees its previous work in the files
6. Iteratively improves until completion

The technique is described as "deterministically bad in an undeterministic world" - failures are predictable, enabling systematic improvement through prompt tuning.

## Available Commands

### /$PLUGIN_NAME:ralph-loop <PROMPT> [OPTIONS]

Start a Ralph loop in your current session.

**Usage:**
```
/$PLUGIN_NAME:ralph-loop "Refactor the cache layer" --max-iterations 20
/$PLUGIN_NAME:ralph-loop "Add tests" --completion-promise "TESTS COMPLETE"
/$PLUGIN_NAME:ralph-loop "Complex feature" --fresh-context --max-iterations 30
/$PLUGIN_NAME:ralph-loop --resume
```

**Options:**
- `--max-iterations <n>` - Max iterations before auto-stop (default: 20)
- `--completion-promise <text>` - Promise phrase to signal completion
- `--max-retries <n>` - Max retries per task before marking blocked (default: 0/disabled)
- `--fresh-context` - Enable session isolation mode (fresh context each iteration)
- `--resume` - Resume from previous progress file
- `--args-stdin` - Read all arguments from stdin (for multi-line prompts)

**How it works:**
1. Creates `.claude/ralph-loop.local.md` state file
2. You work on the task
3. When you try to exit, stop hook intercepts
4. Same prompt fed back
5. You see your previous work
6. Continues until promise detected or max iterations

### Fresh Context Mode (--fresh-context)

For long-running tasks (10+ iterations), enables session isolation to prevent context rot:
- Each iteration ends the session cleanly with zero context
- Progress tracked in `.claude/ralph-progress.md`
- Use `--resume` to continue manually, or use wrapper scripts for automatic continuation
- Prevents degraded performance from overly long conversations

**Wrapper scripts for automatic respawn:**
```bash
./scripts/ralph-auto.sh     # macOS/Linux
./scripts/ralph-auto.ps1    # Windows
```

---

### /$PLUGIN_NAME:cancel-ralph

Cancel an active Ralph loop (removes the loop state file).

**Usage:**
```
/$PLUGIN_NAME:cancel-ralph
```

**How it works:**
- Checks for active loop state file
- Removes `.claude/ralph-loop.local.md`
- Reports cancellation with iteration count

---

### /$PLUGIN_NAME:prp-execute-isolated <PRP> [OPTIONS]

Execute a PRP with hard session isolation - each task in its own fresh context.

**Usage:**
```
/$PLUGIN_NAME:prp-execute-isolated PRPs/feature.md
/$PLUGIN_NAME:prp-execute-isolated PRPs/feature.md --max-retries 5 --timeout 600
```

**Options:**
- `--max-retries <n>` - Max retry attempts per task (default: 3)
- `--timeout <n>` - Timeout in seconds per task (default: 300)

**How it works:**
1. External orchestrator script takes control
2. Parses PRP and extracts individual tasks
3. For each task: writes to file, spawns fresh Claude, waits, logs result
4. Claude sees ONLY current task - never the full PRP
5. Progress tracked in `.claude/prp-progress.md`

**When to use:**
- Complex PRPs (10+ tasks)
- When you need guaranteed context isolation
- When previous `prp-execute` runs showed unwanted optimization

**Comparison:**
- `prp-execute` - Claude controls, shared context, interactive
- `prp-execute-isolated` - Script controls, fresh context per task, batch mode

**Monitoring:**
```bash
# View progress
cat .claude/prp-progress.md

# View current task
cat .claude/current-task.md

# Watch in real-time
tail -f .claude/prp-progress.md
```

---

## Available Agents

Use the Task tool with `subagent_type` to delegate work to specialized agents during Ralph Loop iterations:

| Agent | Specialization | Use For |
|-------|---------------|---------|
| `backend-engineer` | Server-side development | APIs, auth, services, business logic, scripts |
| `frontend-engineer` | UI development | Components, accessibility, performance, responsive design |
| `data-engineer` | Database & data | Schema design, migrations, queries, data modeling |
| `qa-engineer` | Quality assurance | Testing, security, code review, quality analysis |
| `devops-engineer` | Infrastructure | CI/CD, Docker, infrastructure, monitoring |
| `document-specialist` | Documentation | PRDs, technical writing, README files, API docs |
| `project-coordinator` | Project management | Sprint planning, task breakdown, progress tracking |

**How to delegate to agents:**

Include instructions in your Ralph Loop prompt to leverage agents:

```
"For API implementation tasks, use the Task tool with subagent_type='backend-engineer'"
"Delegate testing to the qa-engineer agent"
"Use frontend-engineer for UI components"
```

**Example prompt with agent delegation:**
```
/$PLUGIN_NAME:ralph-loop "Build a REST API with tests. Use backend-engineer for API code, qa-engineer for tests, and document-specialist for API docs." --completion-promise "API COMPLETE" --max-iterations 25
```

---

## Key Concepts

### Completion Promises

To signal completion, Claude must output a `<promise>` tag:

```
<promise>TASK COMPLETE</promise>
```

The stop hook looks for this specific tag. Without it (or `--max-iterations`), Ralph runs infinitely.

### Self-Reference Mechanism

The "loop" doesn't mean Claude talks to itself. It means:
- Same prompt repeated
- Claude's work persists in files
- Each iteration sees previous attempts
- Builds incrementally toward goal

## Example

### Interactive Bug Fix

```
/$PLUGIN_NAME:ralph-loop "Fix the token refresh logic in auth.ts. Output <promise>FIXED</promise> when all tests pass." --completion-promise "FIXED" --max-iterations 10
```

You'll see Ralph:
- Attempt fixes
- Run tests
- See failures
- Iterate on solution
- In your current session

## When to Use Ralph

**Good for:**
- Well-defined tasks with clear success criteria
- Tasks requiring iteration and refinement
- Iterative development with self-correction
- Greenfield projects
- Complex multi-phase implementations (use `--fresh-context`)
- PRP execution with multiple tasks

**Not good for:**
- Tasks requiring human judgment or design decisions
- One-shot operations
- Tasks with unclear success criteria
- Debugging production issues (use targeted debugging instead)

**Choosing the right mode:**
- **In-session (default):** Quick iterations (< 10), interactive work
- **Fresh-context (`--fresh-context`):** Long tasks (10+ iterations), complex PRPs, prevents context rot

## Learn More

- Original technique: https://ghuntley.com/ralph/
- Ralph Orchestrator: https://github.com/mikeyobrien/ralph-orchestrator

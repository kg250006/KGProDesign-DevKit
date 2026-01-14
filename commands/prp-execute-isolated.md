---
description: "[KGP] Execute PRP with hard session isolation - each task in fresh context"
argument-hint: "<prp-file.md> [--max-retries N] [--timeout M]"
allowed-tools: [Bash, Read]
---

# Execute PRP with Task Isolation

Execute a PRP where each task runs in a completely fresh Claude session with zero context sharing.

<objective>
Launch the external orchestrator script to execute the PRP at: $ARGUMENTS

This command uses hard process boundaries - Claude becomes the worker, not the orchestrator.
Each task sees ONLY its own context. No task can see or "optimize" based on other tasks.
</objective>

<when_to_use>
## When to Use This Command

Use `/$PLUGIN_NAME:prp-execute-isolated` when:
- You need guaranteed fresh context per task (no context bleed)
- The PRP has many tasks (10+) and you want to prevent context rot
- Previous `/$PLUGIN_NAME:prp-execute` runs showed Claude "optimizing" by combining tasks
- You want deterministic, reproducible task execution

Use `/$PLUGIN_NAME:prp-execute` (original) when:
- Quick PRPs with few tasks (< 5)
- Interactive execution where you want to monitor progress
- Tasks are highly interdependent and benefit from shared context
</when_to_use>

<process>

## Step 1: Validate PRP File

Parse the path from $ARGUMENTS (first argument before any flags).

```bash
# Extract PRP file path from arguments
PRP_FILE=$(echo "$ARGUMENTS" | awk '{print $1}')

# Verify file exists
if [[ ! -f "$PRP_FILE" ]]; then
  echo "Error: PRP file not found: $PRP_FILE"
  echo ""
  echo "Create a new PRP with: /$PLUGIN_NAME:prp-create"
  exit 1
fi
```

## Step 2: Detect Platform and Script

Determine which orchestrator script to use based on the operating system.

- **macOS/Linux**: Use `scripts/prp-orchestrator.sh`
- **Windows**: Use `scripts/prp-orchestrator.ps1`

## Step 3: Show Execution Plan

Display what will happen before launching:

```
## Isolated PRP Execution

**PRP File:** [path]
**Mode:** External orchestrator (hard session isolation)
**Script:** [prp-orchestrator.sh or .ps1]

Each task will run in a completely fresh Claude session.
Progress will be logged to: .claude/prp-progress.md

Starting orchestrator...
```

## Step 4: Launch Orchestrator

Use the Bash tool to launch the orchestrator script:

```bash
# Get plugin root directory
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/plugins/KGProDesign-DevKit}"

# Launch orchestrator
bash "$PLUGIN_ROOT/scripts/prp-orchestrator.sh" $ARGUMENTS
```

**CRITICAL**: After launching, this Claude session should exit.
The orchestrator controls everything from this point - spawning fresh Claude sessions for each task.

</process>

<comparison>
## Comparison: prp-execute vs prp-execute-isolated

| Aspect | prp-execute | prp-execute-isolated |
|--------|-------------|---------------------|
| **Context** | Shared (one session) | Isolated (fresh per task) |
| **Control** | Claude decides | Script controls |
| **Task visibility** | Claude sees all tasks | Claude sees only current |
| **Use case** | Quick, interactive | Complex, deterministic |
| **Context rot** | Possible (long PRPs) | Prevented |
| **Speed** | Faster (no process overhead) | Slower (process per task) |
</comparison>

<philosophy>
## Session Isolation Philosophy

**HARD LINE:** Every task runs in a completely separate session. No judgment. No optimization. Even if a task is 2% of context, it gets its own fresh window.

**Why this matters:**
1. **Prevents context rot** - Claude's performance degrades as context fills
2. **Deterministic execution** - Same PRP always executes the same way
3. **No accidental optimization** - Claude cannot decide to "combine" tasks
4. **Reproducible results** - Fresh context means consistent behavior
</philosophy>

<example>
## Example Usage

```bash
# Basic usage - execute a PRP with isolation
/$PLUGIN_NAME:prp-execute-isolated PRPs/my-feature.md

# With retry configuration for flaky tasks
/$PLUGIN_NAME:prp-execute-isolated PRPs/complex-feature.md --max-retries 5

# With longer timeout for complex tasks
/$PLUGIN_NAME:prp-execute-isolated PRPs/big-refactor.md --timeout 600

# Both options
/$PLUGIN_NAME:prp-execute-isolated PRPs/mega-feature.md --max-retries 5 --timeout 600
```
</example>

<monitoring>
## Monitoring Execution

While the orchestrator runs, you can monitor progress:

```bash
# View progress log
cat .claude/prp-progress.md

# View current task being executed
cat .claude/current-task.md

# Watch progress in real-time
tail -f .claude/prp-progress.md
```
</monitoring>

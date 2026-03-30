---
description: "[KGP] Execute multiple PRPs sequentially with full context per PRP"
argument-hint: "<prp1.md> <prp2.md> ... OR --batch-file PRPs/batch.txt [--fresh] [--retry-failed] [--isolated] [--iterations N] [--timeout N]"
allowed-tools: [Bash, Read, Glob]
---

# Execute Multiple PRPs in Batch

Execute multiple PRPs sequentially where each PRP runs in its own Claude session. By default, each PRP executes in a single context window (same-context mode via `prp-execute`). Use `--isolated` to opt into per-task isolation.

<objective>
Launch the batch runner script to execute multiple PRPs from: $ARGUMENTS

This command ensures:
- Each PRP runs in its own process/tmux session
- Sequential execution (PRP N finishes before PRP N+1 starts)
- Aggregated results in a batch progress file
- Auto-resume on interruption (skips completed PRPs)
- Per-PRP progress archival for post-batch review

**Default mode (same-context):** Each PRP executes entirely within a single Claude context window. With larger context windows, full PRPs can be executed in a single go without context rot concerns.

**Isolated mode (`--isolated`):** Each task within a PRP runs in a fresh Claude session. Use this for very large PRPs or when deterministic per-task isolation is required.
</objective>

<when_to_use>
## When to Use This Command

Use `/KGP:prp-execute-batch` when:
- You have multiple related PRPs to execute in order (e.g., release pipeline)
- You want to queue up work and let it run unattended
- Previous attempts to chain PRPs manually broke or had context issues

Use `/KGP:prp-execute-batch --isolated` when:
- PRPs are very large (20+ tasks) and you need per-task isolation
- You need guaranteed fresh context per task (no context bleed within a PRP)

Use `/KGP:prp-execute-isolated` when:
- You only have a single PRP to execute with per-task isolation
- You want to monitor a single PRP interactively with isolation
</when_to_use>

<process>

## Step 1: Parse Arguments

Extract the PRP files and options from $ARGUMENTS.

Supported formats:
- Direct files: `PRP1.md PRP2.md PRP3.md`
- Batch file: `--batch-file PRPs/release-queue.txt`
- Wildcard (expand first): `PRPs/*.md` needs Glob expansion

Options:
- `--isolated`: Use per-task isolation mode (each task in fresh Claude session)
- `--iterations N`: Min successful iterations per task (default: 1, only used with --isolated)
- `--dry-run`: Simulate execution without running Claude
- `--timeout N`: Timeout per PRP in seconds (default: 600)
- `--max-retries N`: Max retries per task (default: 3, only used with --isolated)
- `--no-safety`: Disable safety mode
- `--skip-validation`: Skip acceptance criteria validation
- `--fresh`: Start fresh - ignore previous progress (default: auto-resume)
- `--retry-failed`: Retry PRPs that previously failed (marked with [~])

**Note:** Auto-resume is enabled by default. If a previous batch run exists in
`.claude/prp-batch-progress.md`, completed PRPs (marked [x]) will be skipped.
Failed PRPs (marked [~]) are also skipped unless `--retry-failed` is used.

## Step 2: Validate PRP Files

If arguments contain wildcards or a directory pattern, use Glob to expand:

```
# If user provided something like "PRPs/*.md", expand it
```

Verify all PRP files exist before proceeding.

## Step 3: Detect Platform and Script

Determine which batch runner to use:

- **macOS/Linux**: Use `scripts/prp-batch-runner.sh` (tmux-based)
- **Windows**: Use `scripts/prp-batch-runner.ps1` (process-based)

## Step 4: Show Execution Plan

Display what will be executed:

```
## Batch PRP Execution

**PRPs to Execute:**
1. [path/to/prp1.md]
2. [path/to/prp2.md]
3. ...

**Mode:** Sequential (same-context by default, --isolated for per-task isolation)
**Script:** [prp-batch-runner.sh or .ps1]

Each PRP will run in its own session.
Progress tracked in: .claude/prp-batch-progress.md

Starting batch execution...
```

## Step 5: Launch Batch Runner

Use the Bash tool to launch the appropriate script:

**For Unix/macOS:**
```bash
# Get plugin root
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/plugins/cache/KGP/KGP/$LATEST_PLUGIN_VERSION}"

# Launch batch runner
bash "$PLUGIN_ROOT/scripts/prp-batch-runner.sh" $ARGUMENTS
```

**For Windows:**
```powershell
# Get plugin root
$PluginRoot = "$env:USERPROFILE\.claude\plugins\cache\KGP\KGP\$LATEST_PLUGIN_VERSION"

# Launch batch runner
& "$PluginRoot\scripts\prp-batch-runner.ps1" $ARGUMENTS
```

**CRITICAL**: After launching, this Claude session should exit or wait for completion.
The batch runner handles all orchestration and will spawn isolated sessions for each PRP.

</process>

<batch_file_format>
## Batch File Format

Create a text file with one PRP path per line:

```
# PRPs/release-1.0.txt
# Comments start with #

# Phase 1: Database changes
PRPs/PRP-db-migration.md
PRPs/PRP-db-indexes.md

# Phase 2: API changes
PRPs/PRP-api-auth.md
PRPs/PRP-api-endpoints.md

# Phase 3: Frontend
PRPs/PRP-ui-login.md
PRPs/PRP-ui-dashboard.md
```

Then execute with:
```
/KGP:prp-execute-batch --batch-file PRPs/release-1.0.txt
```
</batch_file_format>

<example>
## Examples

```bash
# Execute three PRPs in sequence - each PRP in single context (default)
/KGP:prp-execute-batch PRPs/step1.md PRPs/step2.md PRPs/step3.md

# Use a batch file for a release
/KGP:prp-execute-batch --batch-file PRPs/release-queue.txt

# Dry run to verify the queue
/KGP:prp-execute-batch PRPs/*.md --dry-run

# With longer timeout for complex PRPs
/KGP:prp-execute-batch PRPs/big1.md PRPs/big2.md --timeout 600

# Full options
/KGP:prp-execute-batch --batch-file PRPs/queue.txt --timeout 900

# Use per-task isolation for very large PRPs
/KGP:prp-execute-batch --batch-file PRPs/release.txt --isolated

# Isolated mode with iterations and retries
/KGP:prp-execute-batch --batch-file PRPs/release.txt --isolated --iterations 3 --max-retries 5

# Resume/Retry Examples:

# After interruption, run the same command again - completed PRPs are skipped
/KGP:prp-execute-batch PRPs/step1.md PRPs/step2.md PRPs/step3.md

# Retry failed PRPs from previous batch
/KGP:prp-execute-batch --batch-file PRPs/release.txt --retry-failed

# Force fresh start (ignore previous progress)
/KGP:prp-execute-batch PRPs/*.md --fresh
```
</example>

<monitoring>
## Monitoring Batch Execution

While the batch runs, you can monitor progress:

```bash
# View batch-level progress (which PRPs completed/failed)
cat .claude/prp-batch-progress.md

# View per-task progress for the currently executing PRP (same-context mode)
cat .claude/prp-task-progress.md

# Watch per-task progress in real-time
tail -f .claude/prp-task-progress.md

# Watch batch progress in real-time
tail -f .claude/prp-batch-progress.md

# On Unix, attach to current PRP's tmux session
tmux list-sessions | grep prp-batch
tmux attach -t <session-name>

# View archived progress files after batch completes
ls .claude/prp-task-progress-*.md    # Same-context mode (per-task)
ls .claude/prp-progress-*.md         # Isolated mode (per-task)
```

**Progress tiers:**

| File | Scope | Updated By |
|------|-------|-----------|
| `.claude/prp-batch-progress.md` | Batch (all PRPs) | Batch runner script |
| `.claude/prp-task-progress.md` | Current PRP tasks | Claude (during execution) |
| `.claude/ralph-progress.md` | Ralph Loop iterations | Stop hook |

The batch runner also prints progress to the terminal every ~2 minutes in same-context mode,
showing task completion percentage or Ralph Loop iteration count.
</monitoring>

<architecture>
## How It Works

### Default Mode (Same-Context)

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code Session                       │
│  /KGP:prp-execute-batch → Launch batch runner                │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                    Batch Runner Script                       │
│  prp-batch-runner.sh (Unix) or .ps1 (Windows)               │
│  Iterates through PRP list sequentially                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   PRP 1 (tmux)  │ │   PRP 2 (tmux)  │ │   PRP 3 (tmux)  │
│   ↓             │ │   ↓             │ │   ↓             │
│   claude -p     │ │   claude -p     │ │   claude -p     │
│   "/KGP:prp-    │ │   "/KGP:prp-    │ │   "/KGP:prp-    │
│   execute"      │ │   execute"      │ │   execute"      │
│   ↓             │ │   ↓             │ │   ↓             │
│   Full PRP in   │ │   Full PRP in   │ │   Full PRP in   │
│   single context│ │   single context│ │   single context│
└─────────────────┘ └─────────────────┘ └─────────────────┘
     (wait)              (wait)              (done)
```

### Isolated Mode (`--isolated`)

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code Session                       │
│  /KGP:prp-execute-batch --isolated → Launch batch runner     │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                    Batch Runner Script                       │
│  prp-batch-runner.sh (Unix) or .ps1 (Windows)               │
│  Iterates through PRP list sequentially                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   PRP 1 (tmux)  │ │   PRP 2 (tmux)  │ │   PRP 3 (tmux)  │
│   ↓             │ │   ↓             │ │   ↓             │
│   orchestrator  │ │   orchestrator  │ │   orchestrator  │
│   ↓             │ │   ↓             │ │   ↓             │
│   task→task→... │ │   task→task→... │ │   task→task→... │
│   (fresh each)  │ │   (fresh each)  │ │   (fresh each)  │
└─────────────────┘ └─────────────────┘ └─────────────────┘
     (wait)              (wait)              (done)
```

**Key Design Decision:**
With larger context windows, full PRPs can execute in a single Claude session without
context rot. The default mode uses `claude -p "/KGP:prp-execute <prp>"` for each PRP,
giving Claude the full picture of all tasks at once. The `--isolated` flag switches to
`prp-orchestrator.sh` for per-task isolation when needed.

**Unix (tmux-based):**
- Each PRP runs in a detached tmux session
- Default: `claude -p "/KGP:prp-execute <prp>"`
- Isolated: `prp-orchestrator.sh <prp>` (fresh Claude per task)
- Batch runner waits for session completion via tmux wait-for
- Captures output and exit status
- Cleans up session before next PRP

**Windows (process-based):**
- Each PRP runs via `Start-Process -Wait`
- Default: `claude -p "/KGP:prp-execute <prp>"`
- Isolated: `prp-orchestrator.ps1 <prp>` (fresh Claude per task)
- Blocks until process completes
- Captures exit code
</architecture>

<resume>
## Resume and Recovery

The batch runner supports automatic resumption after interruption:

### Auto-Resume (Default)
- If batch is interrupted (Ctrl+C, crash, etc.), simply re-run the same command
- Completed PRPs (marked `[x]`) are automatically skipped
- Failed PRPs (marked `[~]`) are also skipped (use `--retry-failed` to retry)
- Progress is preserved in `.claude/prp-batch-progress.md`

### Interrupt Behavior
When interrupted, the batch runner:
1. Logs the interruption to the progress file
2. Displays resume instructions
3. Preserves all progress for later continuation

### Flags
- `--fresh`: Force start from scratch, ignoring previous progress
- `--retry-failed`: Include previously failed PRPs in this run

### Per-PRP Progress Archival
After each PRP completes (success or failure), its progress is archived:
- Format: `.claude/prp-progress-{prp-name}.md`
- Example: `prp-progress-my-feature.md`
- Enables post-batch review of individual PRP execution details
</resume>

<comparison>
## Comparison: Execution Modes

| Aspect | prp-execute-batch (default) | prp-execute-batch --isolated | prp-execute-isolated |
|--------|---------------------------|------------------------------|---------------------|
| **Input** | Multiple PRPs | Multiple PRPs | Single PRP |
| **Context per PRP** | Single session | Fresh per task | Fresh per task |
| **Speed** | Fastest | Slower (process per task) | Slower (process per task) |
| **Use case** | Most PRPs | Very large PRPs (20+) | Single large PRP |
| **Resume** | Auto (PRP-level) | Auto (PRP + task-level) | Auto (task-level) |
| **Retry failed** | `--retry-failed` | `--retry-failed` | Re-run command |
</comparison>

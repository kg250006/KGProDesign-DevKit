---
description: "[KGP] Execute multiple PRPs sequentially with full isolation between each"
argument-hint: "<prp1.md> <prp2.md> ... OR --batch-file PRPs/batch.txt [--iterations N] [--dry-run] [--timeout N]"
allowed-tools: [Bash, Read, Glob]
---

# Execute Multiple PRPs in Batch

Execute multiple PRPs sequentially where each PRP runs in complete isolation. Each PRP completes fully before the next one starts.

<objective>
Launch the batch runner script to execute multiple PRPs from: $ARGUMENTS

This command ensures:
- Each PRP runs in its own process/tmux session
- Complete isolation between PRPs (no context bleed)
- Sequential execution (PRP N finishes before PRP N+1 starts)
- Aggregated results in a batch progress file
</objective>

<when_to_use>
## When to Use This Command

Use `/KGP:prp-execute-batch` when:
- You have multiple related PRPs to execute in order (e.g., release pipeline)
- You need guaranteed isolation between PRPs
- You want to queue up work and let it run unattended
- Previous attempts to chain PRPs manually broke or had context issues

Use `/KGP:prp-execute-isolated` when:
- You only have a single PRP to execute
- You want to monitor a single PRP interactively
</when_to_use>

<process>

## Step 1: Parse Arguments

Extract the PRP files and options from $ARGUMENTS.

Supported formats:
- Direct files: `PRP1.md PRP2.md PRP3.md`
- Batch file: `--batch-file PRPs/release-queue.txt`
- Wildcard (expand first): `PRPs/*.md` needs Glob expansion

Options:
- `--iterations N`: Min successful iterations per task (default: 1)
- `--dry-run`: Simulate execution without running Claude
- `--timeout N`: Timeout per task in seconds (default: 300)
- `--max-retries N`: Max retries per task (default: 3)
- `--no-safety`: Disable safety mode
- `--skip-validation`: Skip acceptance criteria validation

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

**Mode:** Sequential with full isolation
**Script:** [prp-batch-runner.sh or .ps1]

Each PRP will run in its own isolated session.
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
# Execute three PRPs in sequence
/KGP:prp-execute-batch PRPs/step1.md PRPs/step2.md PRPs/step3.md

# Use a batch file for a release
/KGP:prp-execute-batch --batch-file PRPs/release-queue.txt

# Dry run to verify the queue
/KGP:prp-execute-batch PRPs/*.md --dry-run

# With longer timeout for complex PRPs
/KGP:prp-execute-batch PRPs/big1.md PRPs/big2.md --timeout 600

# Full options
/KGP:prp-execute-batch --batch-file PRPs/queue.txt --max-retries 5 --timeout 900

# High quality batch with 3 iterations per task
/KGP:prp-execute-batch --batch-file PRPs/release.txt --iterations 3
```
</example>

<monitoring>
## Monitoring Batch Execution

While the batch runs, you can monitor progress:

```bash
# View batch progress
cat .claude/prp-batch-progress.md

# Watch in real-time
tail -f .claude/prp-batch-progress.md

# On Unix, attach to current PRP's tmux session
tmux list-sessions | grep prp-batch
tmux attach -t <session-name>
```

The batch progress file shows:
- Which PRPs have completed
- Success/failure status per PRP
- Timestamps for each execution
- Final summary with totals
</monitoring>

<architecture>
## How It Works

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
│   execute-      │ │   execute-      │ │   execute-      │
│   isolated"     │ │   isolated"     │ │   isolated"     │
│   ↓             │ │   ↓             │ │   ↓             │
│   orchestrator  │ │   orchestrator  │ │   orchestrator  │
│   ↓             │ │   ↓             │ │   ↓             │
│   task→task→... │ │   task→task→... │ │   task→task→... │
└─────────────────┘ └─────────────────┘ └─────────────────┘
     (wait)              (wait)              (done)
```

**Key Design Decision:**
Each PRP is executed via `claude -p "/KGP:prp-execute-isolated <prp>"` rather than
calling prp-orchestrator.sh directly. This ensures:
- Consistent execution path for all PRPs
- Same command whether run manually or in batch
- Full skill/command context is loaded for each PRP

**Unix (tmux-based):**
- Each PRP runs in a detached tmux session
- Inside session: `claude -p "/KGP:prp-execute-isolated <prp>"`
- Batch runner waits for session completion via tmux wait-for
- Captures output and exit status
- Cleans up session before next PRP

**Windows (process-based):**
- Each PRP runs via `Start-Process -Wait`
- Opens in new console window for visibility
- Blocks until process completes
- Captures exit code
</architecture>

<comparison>
## Comparison: Single vs Batch Execution

| Aspect | prp-execute-isolated | prp-execute-batch |
|--------|---------------------|-------------------|
| **Input** | Single PRP | Multiple PRPs |
| **Isolation** | Per-task | Per-task AND per-PRP |
| **Monitoring** | Single progress file | Batch + individual logs |
| **Use case** | One feature | Release pipeline |
| **Context** | Fresh per task | Fresh per task AND per PRP |
</comparison>

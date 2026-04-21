---
description: "[KGP] Execute a PRP file via three-tier dispatch (marketplace Ralph Loop delegation or single-pass), optionally with --team"
argument-hint: <path-to-prp.md> [--max-iterations N] [--completion-promise 'PHRASE'] [--team[=<recipe>]]
allowed-tools: [Read, Bash, Glob, Grep, Task, Write, Edit]
---

# PRP Execute

Execute a Product Requirement Prompt using a three-tier execution strategy:

1. **Tier 1** — Marketplace plugin `ralph-wiggum@claude-plugins-official` detected → delegate to `/ralph-loop`.
2. **Tier 2** — Plugin not installed → run single-pass with an install recommendation.
3. **Tier 3** — Detection itself unavailable → run single-pass with a neutral note.

<objective>
Load the PRP at the path in $ARGUMENTS, detect execution tier, and either delegate to the marketplace plugin or execute the PRP single-pass in this session.
</objective>

<process>

## Step 0 — Preflight: Marketplace Ralph Loop Detection

Run this detection BEFORE any task execution. Set `RALPH_TIER` to 1, 2, or 3. Detection must NEVER hard-fail.

```bash
RALPH_TIER=""

# Primary: claude plugin list + jq
if command -v jq >/dev/null 2>&1 && command -v claude >/dev/null 2>&1; then
  if claude plugin list --json 2>/dev/null \
     | jq -e '.[]? | select(.name == "ralph-wiggum" and .enabled == true)' >/dev/null 2>&1; then
    RALPH_TIER=1
  fi
fi

# Fallback: parse enabledPlugins in settings files. Match either the bare
# name "ralph-wiggum" or the marketplace form "ralph-wiggum@...".
if [ -z "${RALPH_TIER:-}" ]; then
  for f in "$HOME/.claude/settings.json" ".claude/settings.json" ".claude/settings.local.json"; do
    if [ -f "$f" ] && grep -qE '"ralph-wiggum(@[^"]*)?"' "$f" 2>/dev/null; then
      RALPH_TIER=1
      break
    fi
  done
fi

# Decide between Tier 2 (clean miss) and Tier 3 (detection primitives missing)
if [ -z "${RALPH_TIER:-}" ]; then
  if command -v jq >/dev/null 2>&1 && command -v claude >/dev/null 2>&1; then
    RALPH_TIER=2
  else
    RALPH_TIER=3
  fi
fi

echo "RALPH_TIER=$RALPH_TIER"
```

Tier meanings:
- **Tier 1** — `ralph-wiggum@claude-plugins-official` installed. Step 4 delegates to `/ralph-loop`.
- **Tier 2** — Plugin not installed. Step 4 runs single-pass + prints install recommendation.
- **Tier 3** — Detection primitives missing (no `jq` or no `claude` CLI). Step 4 runs single-pass + prints neutral note.

## Step 0.1 — `--team` Preflight

Parse `--team` from arguments:
- `--team` (bare)       → `TEAM_MODE=auto`
- `--team=<recipe>`     → `TEAM_MODE=explicit`, `TEAM_RECIPE=<recipe>`
- neither               → `TEAM_MODE=off` (skip all team logic; Step 4 proceeds with three-tier dispatch as normal)

If `TEAM_MODE != off`:

1. **Mutex check:** if `--isolated` is also set, print:
   ```
   Error: --team and --isolated are mutually exclusive. Pick one.
   ```
   and exit 1.

2. **Env-flag check:** if `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` != `1`, print:
   ```
   Agent Teams is experimental. Enable in settings.json:

   {
     "env": {
       "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
     }
   }

   Then restart Claude Code.
   ```
   and exit 1.

3. **Explicit-recipe validation:** if `TEAM_MODE=explicit`, validate `TEAM_RECIPE` against the 4 valid names (`implementation`, `review`, `research`, `hypothesis`). Invalid → list them and exit 1.

## Step 0.3 — Recipe Auto-Detection (when `TEAM_MODE=auto`)

Skip if `TEAM_MODE=off` or `TEAM_MODE=explicit`. Otherwise:

1. Extract the PRP's `<goal>` text (and optionally concatenate `<description>` fields from all `<task>` elements for better signal coverage).
2. Apply the same classifier + disambiguation rules as `/KGP:team-invoke` (see `skills/agent-teams/references/playbooks.md`):
   - Lowercase, tokenize on whole words.
   - For each recipe row `[review, hypothesis, research, implementation]`, count matching signals.
   - Apply disambiguation:
     - `hypothesis` wins over `implementation`.
     - `review` wins over `implementation`.
     - `research` is fallback-only (dropped if any other row hits).
   - Signal-count tiebreak; ties fall to earlier rows.
   - If no hits → `research` with `(fallback: no signals matched)`.
3. Set `TEAM_RECIPE`.
4. Print the transparency line:
   ```
   Picked recipe: <TEAM_RECIPE> — matched "<signal1>", "<signal2>".
   ```
   (or `(fallback: no signals matched)` / `(explicit --recipe override)` as appropriate)

## Step 0.5 — Task Partitioning (when `TEAM_MODE != off`)

Skip if `TEAM_MODE=off`. Otherwise:

1. Load the spawn-prompt template for `TEAM_RECIPE` from `skills/agent-teams/references/playbooks.md`.
2. Spawn the team — the lead emits the spawn prompt with project-specific substitutions (e.g., `<target>` for review recipes, hypothesis list for hypothesis recipes).
3. Build task partition:
   - For each `<task>` in the PRP, read its `agent=` attribute.
   - Map `agent` → teammate whose `subagent_type` matches, IF present in the recipe. Else keep the task on the lead.
   - Identify cross-track dependencies via `<handoff><expects>` that reference a task owned by a different teammate. Pull those back to the lead.
4. Distribute partitioned tasks to teammates via team messaging.
5. Serial dependencies run on lead between parallel rounds.
6. Lead retains sole `Write`-tool ownership of `.claude/prp-task-progress.md`. Teammates report results via team messaging; lead aggregates and writes.
7. Progress-file schema is extended with an optional `teammate:` column — see Step 5 for the row format.

Note: when `TEAM_MODE != off`, Step 5's single-pass iteration is replaced by teammate-parallel execution. Step 4's three-tier dispatch still runs first, but Tier 1 delegation to `/ralph-loop` is skipped in team mode (teams are their own iteration mechanism). Tiers 2/3 effectively become "single-session with parallel teammates."

## Step 1 — Load and Parse PRP

Read the PRP file from the path provided in $ARGUMENTS (first non-flag argument).

Extract based on PRP format:

**XML-structured PRPs (with `<prp>` tags):**
- `name` from `<prp name="...">`
- `goal` from `<goal>` element
- `phases` and `tasks` from `<phases>` element
- `validation` from `<validation>` element
- `success-criteria` from `<success-criteria>` element

**Markdown-structured PRPs:**
- `name` from the first `# PRP:` or `#` heading
- `goal` from `## Goal` section
- `tasks` from `## Implementation Blueprint` or `## Tasks` section
- `validation` from `## Validation Loop` or `## Validation` section
- `success-criteria` from `## Success Criteria` section

Count total tasks. Extract agent assignments (`agent="..."`) per task for possible Task-tool delegation in Step 5.

## Step 2 — Parse Command Options

Parse $ARGUMENTS for overrides:
- `--max-iterations N` — override default iteration count (Tier 1 only)
- `--completion-promise 'PHRASE'` — override default completion phrase (Tier 1 only)

Defaults:
```
max_iterations = (task_count * 2) + 5
completion_promise = "PRP COMPLETE"
```

## Step 3 — Display Execution Plan

```
## PRP Execution Plan

**PRP:** [name]
**Path:** [path]
**Tasks:** [task_count]
**Execution Tier:** [1 | 2 | 3]
**Max Iterations (Tier 1 only):** [max_iterations]
**Completion Promise:** "[completion_promise]"
```

## Step 4 — Execution: Three-Tier Dispatch

Branch on `RALPH_TIER`.

### Tier 1 — Delegate to Marketplace Ralph Loop

Build the execution prompt:

```
Execute PRP: [PRP_NAME]

GOAL: [goal from PRP]

PATH: [PRP_PATH]

TASKS:
[Formatted phase/task list from PRP, preserving structure]

VALIDATION (run after each task):
[Validation commands from PRP, or project-detected defaults]

COMPLETION CRITERIA:
When ALL success criteria are met, output <promise>[COMPLETION_PROMISE]</promise>:
[Success criteria from PRP]

AVAILABLE AGENTS (use Task tool with subagent_type to delegate):
- backend-engineer, frontend-engineer, data-engineer, qa-engineer
- devops-engineer, document-specialist, project-coordinator

INSTRUCTIONS:
1. Read the full PRP at [PRP_PATH]
2. For each task, consider delegating to the most appropriate agent
3. Work through tasks in phase order
4. Run validation after each task
5. After each task, update .claude/prp-task-progress.md
6. If validation fails, fix before proceeding
7. After all tasks complete, verify ALL success criteria
8. ONLY output the promise when genuinely complete
```

Emit this invocation for Claude to execute (NOTE: `/ralph-loop` is the marketplace form, NOT `/KGP:ralph-loop`):

```
/ralph-loop "<built prompt>" --max-iterations <N> --completion-promise "<PHRASE>"
```

### Tier 2 — Plugin Not Installed

Print:
```
Note: Install Ralph Loop for iterative execution: /plugin install ralph-wiggum@claude-plugins-official
Proceeding with single-pass execution.
```

Then run **Step 5 — Single-Pass Execution**.

### Tier 3 — Detection Unavailable

Print:
```
Ralph Loop detection unavailable; running single-pass.
```

Then run **Step 5 — Single-Pass Execution**.

## Step 5 — Single-Pass Execution (Tiers 2 and 3)

Execute the PRP end-to-end in the current Claude session. No external loop, no state files.

1. Read the full PRP file at `<PRP_PATH>`.
2. Parse all `<task>` elements in order of `<phase>` → `<tasks>`.
3. For each task:
   a. Read the task description, files, pseudocode, and acceptance-criteria.
   b. If the task has an `agent=` attribute and delegation would help, spawn via the Task tool with matching `subagent_type`. Otherwise implement directly.
   c. Apply the changes.
   d. Run per-task validation commands from `<validation level="syntax" run-after="each-task">`.
   e. Append a row to `.claude/prp-task-progress.md`. Only the lead writes this file (via the `Write` tool); teammates never write directly. Schema:
      ```
      - task-id: <id> | status: <done|blocked> | completed-at: <ISO8601> [| teammate: <subagent_type>]
      ```
      The `teammate:` column is **optional** and backward compatible — absent means the task ran on the lead. Old rows without the column continue to parse.
   f. If validation fails, retry once with corrections. If still failing, mark `blocked` and continue.
4. After each `<phase>` completes, run `<validation level="unit" run-after="phase">`.
5. After all phases complete, run `<validation level="integration" run-after="all">`.
6. Verify `<success-criteria>` are met.
7. Emit the completion signal (default: `PRP COMPLETE`).

**Why this is valid:** modern context windows accommodate a full PRP plus its execution. The iterative-retry safety net of Ralph Loop is a nicety, not a requirement, for most PRPs. Users who want iterative retries install the marketplace plugin and automatically get Tier 1.

</process>

<fallback_handling>

**If PRP path not found:**
- Report: "PRP file not found at: [path]"
- Suggest: `/KGP:prp-create` to create a new PRP.

**If PRP structure unclear:**
- Best effort extraction from any markdown structure.
- Treat each `##` or `###` heading under "Tasks" / "Implementation" as a task.

**If no validation commands found:**
- JS projects (package.json): `npm run lint && npm run typecheck && npm test`
- Python projects (pyproject.toml): `ruff check . && mypy . && pytest`

**If no success criteria found:**
- Default: "All tasks completed successfully" AND "All validation checks pass".

</fallback_handling>

<example_invocation>

Basic:
```bash
/KGP:prp-execute PRPs/PRP-feature.md
```

With overrides (Tier 1 only):
```bash
/KGP:prp-execute PRPs/PRP-feature.md --max-iterations 10 --completion-promise 'FEATURE DONE'
```

</example_invocation>

<success_criteria>
- PRP file successfully loaded and parsed.
- `RALPH_TIER` resolved (1, 2, or 3) without hard-failing.
- Correct branch executed per tier.
- Tier 1 emits `/ralph-loop` (marketplace form), never `/KGP:ralph-loop`.
- Tier 2/3 complete single-pass execution with progress logged to `.claude/prp-task-progress.md`.
</success_criteria>

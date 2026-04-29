---
description: "[KGP] Execute one or more PRPs end-to-end in a single native Claude Code session — no scripts, no iteration loops, no stopping until success criteria are met"
argument-hint: "<path-to-prp.md> [<path-to-prp2.md> ...] [--team[=<recipe>]]"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Task]
---

# PRP Execute (Native)

Execute one or more Product Requirement Prompts end-to-end in this single Claude Code session. No external orchestration, no iteration scripts, no stopping until every task is `done` or `blocked` and all success criteria are met.

<objective>
Read every PRP path provided in $ARGUMENTS, then execute every task across all PRPs in order, in this single Claude Code session. Do NOT pause between tasks, do NOT ask permission to continue, do NOT summarize-and-stop. Halt ONLY if (a) all success criteria for all PRPs are satisfied — emit `<promise>ALL PRPs COMPLETE</promise>` — or (b) a hard blocker (missing file, irreducibly ambiguous spec, repeated validation failure after 3 retries, destructive action requiring human approval per CLAUDE.md) makes progress impossible.
</objective>

<operating_mode>

**Recommended (not required):**

- Run on a Claude Code model with 1M-token context where your plan tier supports it (Opus 4.7, Sonnet 4.6). A 5,000-line PRP fits comfortably with room for execution; multiple PRPs in one invocation also fit.
- Enable Auto mode (`Shift+Tab` to cycle, or `autoMode` block in `settings.json`) for unattended runs. See https://code.claude.com/docs/en/permissions#permission-modes.
- Auto-compaction is on by default and will preserve user requests + key code while summarizing tool noise. See https://code.claude.com/docs/en/how-claude-code-works#the-context-window.

**Trade-off — read this once:**

Anthropic's engineering writing on long-running tasks (https://www.anthropic.com/engineering/harness-design-long-running-apps, https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) notes that some long-running scenarios benefit from full context resets between phases rather than relying on auto-compaction alone. This command intentionally trades that off for simplicity: one session, end-to-end. If a single PRP is so large that auto-compaction starts erroring (Claude Code halts auto-compaction when summaries refill immediately), delegate verbose-output tasks to subagents via the Task tool — that gives you fresh context per subagent without splitting the run.

**Default permission mode also works.** If Auto mode isn't available, the command will pause for user approval at tool boundaries; once approved, execution discipline (below) applies.

</operating_mode>

<execution_discipline>

**Read this before doing anything else. Re-read it if you find yourself wanting to stop.**

You are running a long task. You will be tempted, mid-execution, to:
- Summarize "progress so far" and pause for user input.
- Ask "should I continue?" between tasks.
- Note that context is filling and offer to wrap up.
- Treat a recoverable tool error as a session-ending event.

Do none of those things. The user already approved the entire run by invoking this command. Their intent is unambiguous: execute every task, in every PRP, until the success criteria are met.

**Permitted to halt only for:**

1. **All success criteria met.** Emit `<promise>ALL PRPs COMPLETE</promise>` and stop.
2. **Missing file:** a `<files>` reference in a task points to a path that doesn't exist and the PRP gives no creation guidance. Report and halt.
3. **Irreducibly ambiguous spec:** after re-reading the PRP and `<intent-anchors>`, you genuinely cannot determine what success looks like for the current task. Report which task and what's ambiguous. Halt.
4. **Validation failure after 3 retries:** a task's per-task validation has failed 3 times despite corrections. Mark the task `blocked` with a reason in `.claude/prp-task-progress.md` and CONTINUE to the next task. Do not halt the run.
5. **Destructive action requiring human approval:** per CLAUDE.md "Executing actions with care" guidance — anything that deletes data, force-pushes, drops a database, etc. Pause for explicit approval, then continue.

**Forbidden halt reasons:**

- "Context is getting large." Auto-compaction handles it. If compaction is failing, delegate the next verbose task to a subagent via the Task tool.
- "I should check in with the user." No, you shouldn't. Continue.
- "This is taking a while." Yes. Continue.
- "I've completed phase 1, want to confirm before phase 2?" No, continue to phase 2.
- "I see a pattern that could be refactored." Note it in the task's acceptance-criteria comments if relevant; do not deviate from the PRP to refactor.

**If you delegate to a subagent (Task tool):**

- The subagent's main-context return is a summary, not the full work. That's fine — the work itself happened in the subagent's isolated context.
- Don't delegate every task by default; delegate when a task's output would be verbose (large file reads, exploratory grep, multi-file research) and you want to preserve main-context budget for later tasks.

</execution_discipline>

<process>

## Step 1 — Parse Arguments

From `$ARGUMENTS`:

1. Collect every non-flag token as a PRP path. Order matters — PRPs execute in the order given.
2. Detect `--team` (bare → auto-pick recipe) or `--team=<recipe>` (explicit). No other flags exist; `--isolated`, `--max-iterations`, `--completion-promise` from prior versions are removed.
3. For each PRP path, attempt `Read <path>` with limit 1 (just to confirm existence). If any read fails, halt with:
   ```
   PRP not found: <path>
   Use /KGP:prp-create to author it, or check the spelling.
   ```
4. If zero PRP paths were given, halt with:
   ```
   Usage: /KGP:prp-execute <path-to-prp.md> [<path-to-prp2.md> ...] [--team[=<recipe>]]
   ```

## Step 2 — Load All PRPs

For each PRP path in argument order:

1. `Read <path>` — read the full file. Modern Claude Code context windows handle multi-thousand-line PRPs in a single read; do NOT chunk or use `offset`/`limit` unless the read tool itself errors on size.

2. Extract per PRP:
   - **name** — from `<prp name="...">` (XML) or first `# PRP:` heading (markdown).
   - **goal** — from `<goal>` element or `## Goal` section.
   - **intent-anchors** — if present, treat as authoritative for disambiguating execution decisions. (Per the new prp-create format; older PRPs without this element fall back to `<goal>` for disambiguation.)
   - **decisions** — from `<context><decisions>` if present; these are locked architectural choices the user already approved.
   - **phases / tasks** — in the order they appear in the file.
   - **validation** — `<validation level="syntax|unit|integration" run-after="...">` blocks, or markdown `## Validation` section.
   - **success-criteria** — from `<success-criteria>` element or `## Success Criteria` section.

3. After all PRPs are loaded, you have the complete plan. Do NOT write the plan to a state file. Hold it in this conversation's context.

## Step 3 — Execution Plan Banner

Print this exactly once, before Step 4 starts:

```
## Native PRP Execution Plan

**PRPs queued:** [N]
**Total tasks across all PRPs:** [task_count]
**Operating mode:** [Auto | default-permission]
**Discipline:** Single session, no halt between tasks/PRPs unless success criteria met or hard blocker per <execution_discipline>.

| # | PRP | Tasks | Lines |
|---|-----|-------|-------|
| 1 | <name> | <count> | <lines> |
| ... | ... | ... | ... |

Beginning execution now. The next checkpoint is final completion or a documented hard blocker.
```

## Step 4 — Execute (per PRP, in argument order)

For each PRP in the queue, in order:

### 4.A — Per-task execution

For each `<task>` in the current PRP, in `<phase>` order:

1. **Read the task in full** — description, `<files>`, `<pseudocode>`, `<acceptance-criteria>`, `<handoff>`. If the PRP has `<intent-anchors>`, hold them in mind as the disambiguation source.

2. **Decide direct vs delegated execution:**
   - If the task has `agent="<subagent_type>"` AND its expected output is verbose (large file reads, multi-file exploration, research), spawn a subagent via the Task tool with the matching `subagent_type`. Pass it the task's description, files, pseudocode, and acceptance criteria. The subagent does the work in its isolated context and returns a summary; apply the resulting changes from its summary.
   - Otherwise, implement directly using Read / Write / Edit / Bash / Grep / Glob in the main session.

3. **Apply the changes.** Use Write for new files, Edit for in-place modifications. Match existing code style (tabs vs spaces, comment conventions) by reading the surrounding code first.

4. **Run per-task validation.** Find `<validation level="syntax" run-after="each-task">` (or a per-task validation override if the task specifies one) and execute every command listed via Bash. If any command fails:
   - Read the failure output, diagnose, attempt a fix.
   - Re-run validation. If it passes, continue.
   - If it fails again, attempt a second fix.
   - If validation fails THREE times in a row on the same task, mark the task `blocked` (see step 5), log the third-failure output to `.claude/prp-task-progress.md` as a comment row, and continue to the next task. Do NOT halt the run.

5. **Append a progress row** to `.claude/prp-task-progress.md` (lead-only writer). Schema (back-compatible with prior runs):
   ```
   - task-id: <id> | status: <done|blocked> | completed-at: <ISO8601> [| teammate: <subagent_type>]
   ```
   The `teammate:` column is OPTIONAL — present only when `--team` is in effect AND a teammate other than the lead executed this task. Use the Write tool with append-style semantics (Read-then-Write the full file with the new row added). Do NOT use Edit for append-only operations on this file unless the existing content is small.

6. **Continue to the next task without pausing.** No "Task X.Y complete" status messages between tasks unless a task was blocked.

### 4.B — Per-phase validation

After every task in a `<phase>` has been processed (status = done OR blocked), run `<validation level="unit" run-after="phase">` commands once. Same retry-up-to-3 rule as per-task. If unit validation fails 3 times, log it as a blocker comment in the progress file, then proceed to the next phase. (Phase-level blockers are rare and usually mean a foundational task is broken — but halting the entire PRP because of one phase-level test failure would prevent later phases from running, which is worse.)

### 4.C — Per-PRP integration

After ALL phases of the current PRP complete, run `<validation level="integration" run-after="all">`. If it passes, verify every `<success-criterion>` is met by reading the relevant artifacts. Emit:
```
<promise>PRP <name> COMPLETE</promise>
```
(substituting the actual PRP name).

If integration fails after 3 retries OR a success criterion cannot be verified, emit:
```
<promise>PRP <name> COMPLETE WITH BLOCKERS: [<list>]</promise>
```
and continue to the next PRP. Do not halt.

### 4.D — Move to next PRP

Without pausing, without printing a separator, without asking the user, advance to the next PRP in the queue. Repeat 4.A–4.C.

### 4.E — All PRPs done

After the LAST PRP in the queue has emitted its completion promise, emit:
```
<promise>ALL PRPs COMPLETE</promise>
```
and end the run.

## Step 5 — Optional `--team` Branch

Skip this step entirely if `--team` was not in `$ARGUMENTS`. Otherwise, replace Step 4's lead-only execution with parallel teammate execution.

### 5.A — Mode parse

- `--team` (bare) → `TEAM_MODE=auto`, `TEAM_RECIPE=<auto-pick>`
- `--team=<recipe>` → `TEAM_MODE=explicit`, `TEAM_RECIPE=<recipe>` (validate against `implementation`, `review`, `research`, `hypothesis`; invalid → halt with the valid list)

### 5.B — Env-flag check

If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS != 1`, halt with:
```
Agent Teams is experimental. Enable in settings.json:

{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }

Then restart Claude Code.
```

### 5.C — Recipe auto-detect (when TEAM_MODE=auto)

Use the classifier in `skills/agent-teams/references/playbooks.md`:
- Lowercase + tokenize the first PRP's `<goal>` (and `<description>` of all tasks if signal is sparse).
- For each recipe in `[review, hypothesis, research, implementation]`, count signal matches.
- Disambiguation: `hypothesis` > `implementation`; `review` > `implementation`; `research` is fallback-only.
- On no-hits, default to `research`.
- Print: `Picked recipe: <recipe> — matched "<signal1>", "<signal2>".` (or `(fallback)` / `(explicit)` as applicable)

### 5.D — Spawn team and partition

1. Load the spawn-prompt template for `TEAM_RECIPE` from `skills/agent-teams/references/playbooks.md`.
2. Spawn the team — emit the spawn prompt with project-specific substitutions.
3. Partition tasks across teammates: for each `<task>`, map its `agent=` attribute to a teammate whose `subagent_type` matches. If no match, the task stays on the lead. Cross-track dependencies (`<handoff><expects>` referencing a task owned by a different teammate) pull back to the lead for serial execution between parallel rounds.
4. Distribute partitioned tasks via team messaging.
5. Lead retains sole `Write` ownership of `.claude/prp-task-progress.md`. Teammates report via team messaging; lead writes the row with `teammate: <subagent_type>` populated.

### 5.E — Team-mode discipline

All `<execution_discipline>` rules still apply. Specifically: do not pause between rounds; do not ask the lead to confirm partition decisions mid-run. After the last round, emit the same `<promise>ALL PRPs COMPLETE</promise>` as Step 4.E.

</process>

<fallback_handling>

**PRP path not found:** report `PRP file not found at: <path>` and halt; suggest `/KGP:prp-create` to author it.

**PRP structure unclear:** best-effort extraction. Treat each `##` or `###` heading under "Tasks" / "Implementation" as a task; default to a single phase if no phase markers exist.

**No validation commands found:** detect by project type:
- JS (`package.json` exists): `npm run lint && npm run typecheck && npm test`
- Python (`pyproject.toml`): `ruff check . && mypy . && pytest`
- Other: skip per-task validation, log a one-time note in `.claude/prp-task-progress.md`, proceed.

**No success criteria found:** default to "all tasks completed (status=done)" AND "all available validation gates passing".

</fallback_handling>

<example_invocation>

**Single PRP:**
```
/KGP:prp-execute PRPs/PRP-feature.md
```

**Multiple PRPs in one session:**
```
/KGP:prp-execute PRPs/PRP-foundation.md PRPs/PRP-core.md PRPs/PRP-polish.md
```

**With Agent Teams (experimental):**
```
/KGP:prp-execute PRPs/PRP-feature.md --team
/KGP:prp-execute PRPs/PRP-feature.md --team=review
```

</example_invocation>

<success_criteria>

- All PRP paths in `$ARGUMENTS` were resolved and read fully.
- For every PRP: every task ended in `status=done` or `status=blocked` (with a logged reason).
- `.claude/prp-task-progress.md` contains one row per task, schema-conformant.
- All non-blocked validation gates (per-task syntax, per-phase unit, per-PRP integration) passed.
- For every PRP: a `<promise>PRP <name> COMPLETE</promise>` was emitted (or `... COMPLETE WITH BLOCKERS: [...]` if applicable).
- At end of run: `<promise>ALL PRPs COMPLETE</promise>` emitted.
- No external script was executed.
- No mid-run pause for user confirmation occurred (apart from default-permission-mode tool prompts, which are an expected interactive cost).

</success_criteria>

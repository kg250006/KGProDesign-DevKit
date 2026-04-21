---
description: "[KGP] Spawn an experimental Agent Team (recipe auto-picked from task text)"
argument-hint: "<task>" [--recipe <name>] [--force]
allowed-tools: [Read, Glob, Bash]
---

# /KGP:team-invoke

Spawn an experimental Agent Team to work on `<task>`. The recipe is auto-picked from the task text unless `--recipe` is given explicitly.

<objective>
Preflight the environment, resolve a recipe (auto-classify or explicit), load the matching spawn prompt from the agent-teams skill, and emit the spawn instruction for Claude to execute.
</objective>

<process>

## Step 1 — Preflight: Experimental Flag

```bash
if [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" != "1" ]; then
  cat <<'EOF'
Agent Teams is experimental. Enable in settings.json:

{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}

Then restart Claude Code.
EOF
  exit 1
fi
```

## Step 2 — Argument Parsing

Parse `$ARGUMENTS`:
- First quoted string → `TASK_TEXT`
- `--recipe <name>` → `EXPLICIT_RECIPE` (override)
- `--force` → `FORCE=1` (skip optional confirmations)

If `TASK_TEXT` is empty, print:
```
Usage: /KGP:team-invoke "<task description>" [--recipe <name>] [--force]
```
and exit.

## Step 3 — Recipe Resolution

### 3a — Explicit override

If `EXPLICIT_RECIPE` is set:
1. Validate against the 4 valid recipes: `implementation`, `review`, `research`, `hypothesis`.
2. If invalid, print:
   ```
   Error: Unknown recipe '<value>'. Valid recipes:
     - implementation
     - review
     - research
     - hypothesis
   ```
   and exit 1.
3. Set `CHOSEN_RECIPE = EXPLICIT_RECIPE`. Reasoning line: `"(explicit --recipe override)"`.

### 3b — Auto-classification (when no `--recipe`)

Apply the classifier from `skills/agent-teams/references/playbooks.md`.

Normalize:
- Lowercase `TASK_TEXT`.
- Tokenize on whole-word boundaries.

For each recipe row in order `[review, hypothesis, research, implementation]`, compute:
- `hits[recipe]` = count of distinct signals matched.
- `matched_signals[recipe]` = list of matched signals for the reasoning line.

Apply disambiguation BEFORE picking:
1. If `hits[hypothesis] > 0` AND `hits[implementation] > 0` → drop `implementation`.
2. If `hits[review] > 0` AND `hits[implementation] > 0` → drop `implementation`.
3. `research` is dropped unless all other recipes have 0 hits (fallback-only).

Among remaining recipes with `hits > 0`:
- Pick the one with highest `hits`.
- On tie, pick the one appearing earliest in `[review, hypothesis, research, implementation]`.

If no recipes have `hits > 0`:
- `CHOSEN_RECIPE = research`, reasoning = `"(fallback: no signals matched)"`.

**Implementation-domain bonus:** for `implementation`, also count distinct agent-affinity keyword domains:
- UI/frontend: `UI`, `component`, `style`, `accessibility`, `a11y`, `page`
- API/backend: `API`, `endpoint`, `auth`, `service`, `business logic`
- Data: `schema`, `migration`, `query`, `database`, `table`

If 3+ distinct domains are hit, that counts as an `implementation` signal.

## Step 4 — Transparency Line

Print exactly one line:

```
Picked recipe: <CHOSEN_RECIPE> — <reasoning>.
```

Where `<reasoning>` is one of:
- `matched "<signal1>", "<signal2>"`
- `(explicit --recipe override)`
- `(fallback: no signals matched)`

## Step 5 — Load Spawn Template

Read the matching `### \`<CHOSEN_RECIPE>\`` section from `skills/agent-teams/references/playbooks.md`. Extract the spawn-prompt code block.

Substitute any project-specific context into the template (e.g., replace `<target>` for review recipes, enumerate hypotheses for hypothesis recipes).

## Step 6 — Emit Spawn Instruction

Emit the spawn prompt as an instruction for Claude to execute. Claude will use this natural-language block to create teammates of the correct `subagent_type`.

## Step 7 — Mode Reminder

Print:
```
Reminder: one team per session, no nested teams.
For split-pane monitoring, use tmux or iTerm2.
```

</process>

<success_criteria>
- Missing env flag → snippet printed, command exits.
- Invalid `--recipe <bogus>` → 4 valid recipes listed, command exits.
- Every invocation prints the transparency line with picked recipe + reasoning.
- Spawn prompt loaded from the skill's playbooks, not hardcoded here.
- Mode reminder printed after spawn emission.
</success_criteria>

<example_invocations>

```bash
/KGP:team-invoke "review PR #42 for the auth refactor"
# → Picked recipe: review — matched "review", "PR".

/KGP:team-invoke "why does the app exit after first message?"
# → Picked recipe: hypothesis — matched "why", "why does".

/KGP:team-invoke "should we use OAuth or JWT?"
# → Picked recipe: research — matched "should we".

/KGP:team-invoke "build a user profile page with avatar upload"
# → Picked recipe: implementation — matched "build", UI+API+schema domains.

/KGP:team-invoke "do the thing"
# → Picked recipe: research — (fallback: no signals matched).

/KGP:team-invoke "review PR" --recipe hypothesis
# → Picked recipe: hypothesis — (explicit --recipe override).
```

</example_invocations>

# Agent Teams — Playbooks

Per-recipe spawn templates, classifier table, disambiguation rules, and PRP task-partitioning guidance.

## Recipe classifier

Matching is **case-insensitive, whole-word**. Apply disambiguation rules before picking.

| Recipe | Signals in task text / PRP goal |
|---|---|
| `review` | `review`, `PR`, `pull request`, `audit`, `check`, `inspect`, `pre-merge`, `ship-ready`, `code review`, `security review`, `sign off` |
| `hypothesis` | `debug`, `fix`, `bug`, `crash`, `why`, `why does`, `root cause`, `investigate`, `stumped`, `broken`, `intermittent`, `flaky`, `regression`, `not working`, `failing` |
| `research` | `research`, `explore`, `investigate options`, `discover`, `evaluate`, `compare`, `should we`, `which approach`, `which library`, `options`, `trade-offs`, `tradeoffs`, `design`, `brainstorm`, `spike` |
| `implementation` | `build`, `implement`, `add`, `create`, `scaffold`, `feature`, `new endpoint`, `new component`, `ship`, `develop`, OR 3+ distinct agent-affinity keyword domains (UI *and* API *and* schema) |
| *(fallback)* | No signals matched → `research` (generalists, read-only by nature; safest default) |

### Disambiguation rules

1. `hypothesis` wins over `implementation` — "fix the auth bug" is debugging.
2. `review` wins over `implementation` — "review and refactor" is review work.
3. `research` loses to any other match — it's the fallback only.
4. Signal-count tiebreak; ties fall to earlier rows: `review` > `hypothesis` > `research` > `implementation`.

### Examples

| User types | Matched signals | Picked recipe |
|---|---|---|
| `"review PR #42 for the auth refactor"` | `review`, `PR` | `review` |
| `"fix the bug where login fails on Safari"` | `fix`, `bug`, `fails` | `hypothesis` |
| `"debug why the app crashes on startup"` | `debug`, `why`, `crash` | `hypothesis` |
| `"research OAuth vs JWT for our SaaS"` | `research`, `compare` | `research` |
| `"should we migrate from Postgres to Mongo?"` | `should we` | `research` |
| `"build a user profile page with avatar upload and save to DB"` | `build`, UI+API+schema | `implementation` |
| `"add a new billing endpoint"` | `add`, `new endpoint` | `implementation` |
| `"review and refactor the cache layer"` | `review`, `refactor` | `review` (rule 2) |
| `"do the thing"` | *(none)* | `research` (fallback) |

**Transparency:** every invocation prints one line showing the picked recipe and the triggering signals.

---

## Recipes

### `implementation`

**Teammates:** `frontend-engineer`, `backend-engineer`, `data-engineer`.

**Composition rationale:** full-stack features partition cleanly along UI / API / schema boundaries. Three teammates, parallel tracks, lead coordinates cross-boundary touches.

**Spawn prompt** (lead emits this after `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set):

```
Spawn a team of 3 teammates:
  - One frontend-engineer: handle UI components and client-side state.
  - One backend-engineer: handle API endpoints and business logic.
  - One data-engineer: handle schema, migrations, and queries.
I (the lead) will distribute tasks by agent affinity and coordinate cross-track touches. Each teammate reports progress via team messaging; I will write to .claude/prp-task-progress.md.
```

---

### `review`

**Teammates:** `qa-engineer`, `backend-engineer`, `frontend-engineer`.

**Composition rationale:** three lenses on the same change. QA catches test-coverage and security gaps; backend reviewer catches logic/perf; frontend reviewer catches UX/a11y.

**Spawn prompt:**

```
Spawn a team of 3 teammates to review <target>:
  - One qa-engineer: security, test coverage, edge cases.
  - One backend-engineer: logic, performance, data correctness.
  - One frontend-engineer: UX, accessibility, state management.
Each teammate independently reviews and reports findings. I will consolidate into a single review summary.
```

---

### `research`

**Teammates:** 3 generalists with UX / architecture / devil's-advocate prompts.

**Composition rationale:** early discovery benefits from diversity of thought. One teammate advocates for user experience, one evaluates architecture, one plays devil's advocate.

**Spawn prompt:**

```
Spawn a team of 3 generalist teammates:
  - Teammate A: advocate for the user-experience-first approach.
  - Teammate B: evaluate architecture trade-offs and long-term maintenance.
  - Teammate C: devil's advocate — argue for the opposite of the default approach.
Each produces a one-page brief. I will synthesize.
```

---

### `hypothesis`

**Teammates:** 3–5, one per hypothesis.

**Composition rationale:** hard bugs with unknown root cause benefit from parallel investigation. Each teammate owns one hypothesis end-to-end.

**Spawn prompt:**

```
Spawn a team of N teammates (one per hypothesis). Hypotheses:
  - H1: <hypothesis 1>
  - H2: <hypothesis 2>
  - H3: <hypothesis 3>
Each teammate investigates their hypothesis only — gather evidence, run reproductions, report confirmation or refutation. I will consolidate findings.
```

---

## PRP `--team` task partitioning

When `--team` is set on `/KGP:prp-execute`, the lead groups independent tasks by agent affinity (see `commands/prp-execute.md` Step 0 agent discovery, and the standard agent-affinity keyword table: UI/component/style/a11y → frontend; API/endpoint/auth/service → backend; schema/migration/query/database → data; test/security/review → qa).

Partitioning rules:
- Each `<task>` with an `agent=` attribute maps to the matching teammate if the recipe includes that subagent type.
- Cross-track dependencies (via `<handoff><expects>` pointing to a task owned by a different teammate) stay on the lead for serial execution between parallel rounds.
- Lead retains sole Write-tool ownership of `.claude/prp-task-progress.md`. Teammates report via team messaging; lead aggregates and writes.
- The progress schema gains an optional `teammate:` column — backward compatible (absent = "lead").

---

## External references

- Agent Teams overview: https://code.claude.com/docs/en/agent-teams
- Subagents: https://code.claude.com/docs/en/sub-agents
- Cost model: linear in teammate count. 3–5 sweet spot.
- Related: marketplace Ralph Loop — `ralph-wiggum@claude-plugins-official` (install via `/plugin install ralph-wiggum@claude-plugins-official`).

---
description: "[KGP] Generate a comprehensive Product Requirement Prompt from feature requirements with research and context"
argument-hint: <feature description or requirements file>
allowed-tools: [Read, Write, Glob, Grep, Bash, WebSearch, WebFetch, AskUserQuestion, Task]
---

<agent_discovery>
## Step 0: Discover Available Agents

Before generating the PRP, scan for available specialized agents to enable intelligent task assignments:

```
Glob: agents/*.md
```

**Build agent registry from discovered agents:**
For each agent file found, extract the name and core competencies. Standard agents include:

| Agent | Specialization | Task Keywords |
|-------|---------------|---------------|
| backend-engineer | Server-side development | API, endpoint, service, auth, business logic |
| frontend-engineer | UI development | UI, component, page, style, accessibility |
| data-engineer | Data layer | schema, migration, query, database |
| qa-engineer | Quality assurance | test, security, review, QA |
| devops-engineer | Infrastructure | CI/CD, deploy, Docker, infrastructure |
| document-specialist | Documentation | docs, README, technical writing |
| project-coordinator | Project management | planning, sprint, coordination |

**Use this agent registry when assigning agents to PRP tasks (step_5_assign_agents).**
</agent_discovery>

<objective>
Generate a complete PRP (Product Requirement Prompt) for: $ARGUMENTS

A PRP provides ALL context needed for `/KGP:prp-execute` (native single-session execution) to implement the feature autonomously. The goal is comprehensive XML-structured micro-tasks that executor Claude can implement without ambiguity.

This command detects whether input needs expansion and routes through the appropriate workflow.
</objective>

<process>

<step_1_evaluate_input>
**Evaluate Input Detail Level**

Analyze $ARGUMENTS to classify as SHORT (needs expansion) or DETAILED (ready for PRP).

<short_criteria>
Input is SHORT if ANY of these are true:
- Under 50 words total
- No mention of specific user flows or acceptance criteria
- Generic terms without specifics ("add feature", "implement X", "create Y", "build Z")
- Missing technical context (no framework, database, API, or integration mentions)
- Single sentence or phrase without elaboration
- Imperative command style without requirements ("add user auth", "fix login")
</short_criteria>

<detailed_criteria>
Input is DETAILED if MOST of these are true:
- 50+ words with specifics
- Mentions user stories, flows, or use cases
- Includes technical constraints, patterns, or architecture decisions
- References existing code, integrations, or dependencies
- Contains acceptance criteria or success metrics
- Describes edge cases or error handling requirements
</detailed_criteria>

<classification_output>
After analysis, state your classification:

```
INPUT CLASSIFICATION: [SHORT | DETAILED]
Word count: [N]
Missing elements: [list what's missing for SHORT, or "N/A" for DETAILED]
```

Then proceed to the appropriate step:
- If SHORT: Go to step_2_expand
- If DETAILED: Go to step_3_sizing_assessment
</classification_output>
</step_1_evaluate_input>

<step_2_expand>
**Expand Short Input (Skip if DETAILED)**

When input is classified as SHORT, use the Task tool to spawn a sub-agent that will expand the requirements through structured questioning.

<expansion_task>
Use the Task tool with these parameters:

```
Task tool invocation:
- description: "Expand vague feature requirements into detailed specification"
- prompt: |
    You are helping expand a short feature request into detailed requirements.

    Original request: "$ARGUMENTS"

    Your goal is to gather enough detail for a comprehensive PRP. Ask clarifying questions to understand:

    1. **User Stories**: Who uses this? What are their goals?
    2. **Functional Requirements**: What specific behaviors are needed?
    3. **Technical Context**: What frameworks, databases, APIs are involved?
    4. **Acceptance Criteria**: How do we know when it's done?
    5. **Edge Cases**: What could go wrong? How should errors be handled?
    6. **Integration Points**: What existing code does this touch?

    Use AskUserQuestion tool to gather information through structured questions.

    **Hard limit: 5 questions total (3 mandatory + up to 2 optional follow-ups).**

    **Mandatory (always ask):**
    1. Who is the primary user / role for this feature, and what triggers them to use it?
    2. What is the single most important success signal — the one observation that proves the feature works?
    3. What's explicitly OUT of scope for this version?

    **Optional (only ask if a mandatory answer was vague):**
    4. [If technical context is missing] What framework / database / external service is involved?
    5. [If acceptance criteria are vague] What's an example input and expected output?

    Do NOT ask more than 5 questions. If the user's answers are still insufficient after 5, surface that to the parent command — don't keep probing.

    After gathering sufficient context, output an expanded feature description in this format:

    <expanded_requirements>
    ## Feature: [Name]

    ### User Stories
    - As a [role], I want [goal] so that [benefit]

    ### Functional Requirements
    - [Specific behavior 1]
    - [Specific behavior 2]

    ### Technical Context
    - Framework/Stack: [details]
    - Database: [details]
    - APIs: [details]

    ### Acceptance Criteria
    - [ ] [Measurable criterion 1]
    - [ ] [Measurable criterion 2]

    ### Edge Cases
    - [Case 1]: [How to handle]

    ### Integration Points
    - [Existing file/system]: [How it connects]
    </expanded_requirements>

    The expanded requirements should be detailed enough that no further clarification is needed for PRP generation.
```

After the Task completes, capture the expanded requirements output.
</expansion_task>

<post_expansion>
After receiving expanded requirements from the sub-agent:

1. Confirm the expansion is sufficient (50+ words, has acceptance criteria)
2. If still insufficient, ask ONE direct follow-up question using AskUserQuestion
3. Proceed to step_2.5_intent_lock with the expanded requirements (or directly from step_1 if input was DETAILED)
</post_expansion>
</step_2_expand>

<step_2.5_intent_lock>
**Intent Lock (B1) — confirm interpretation before generating**

After expansion (or directly after a DETAILED classification), restate the feature using exactly these 5 anchors and ask the user to confirm. This catches scope drift BEFORE the long architect workflow runs.

<restate>
Print:
```
## Intent Restatement

**What** (the deliverable, in one sentence): [...]
**Who** (the user / role): [...]
**Why** (the motivating outcome): [...]
**Out of scope** (explicitly NOT in this PRP):
  - [...]
  - [...]
**Success signal** (the one observation that proves it works): [...]
```
</restate>

<confirm>
Use AskUserQuestion with question: "Does this restatement match your intent?"
Options:
  1. "Matches — proceed to sizing." (Recommended)
  2. "Close, but adjust [free text]." → apply user's adjustment text and re-print restatement; max 2 adjustment rounds.
  3. "Significantly off — let me restart with more detail." → loop back to step_2_expand.
</confirm>

<output>
Persist the locked anchors in conversation context. They will be written verbatim into the generated PRP's `<intent-anchors>` element (see step_4 / B5).
</output>
</step_2.5_intent_lock>

<step_2.7_decision_log>
**Decision Log (B2) — surface architectural choices before encoding**

During codebase analysis (step_2_analyze_codebase) and research (step_2b_research_existing_solutions), identify every "decision point" — a place where you're choosing between alternatives that the user hasn't explicitly specified. Examples:
- Library X vs library Y for some capability
- File location: `src/feature/` vs `src/lib/feature/`
- Reuse existing component vs write a new one
- REST vs GraphQL for a new endpoint
- Sync vs async API style
- Database column vs separate table for a relationship

<surface_decisions>
Print:
```
## Architectural Decisions Identified

The PRP will encode the following choices unless you override:

| # | Decision | Recommended | Alternative(s) | Rationale |
|---|----------|-------------|----------------|-----------|
| 1 | [name]   | [choice]    | [alts]         | [why]     |
| 2 | ...      | ...         | ...            | ...       |
```
</surface_decisions>

<confirm>
Use AskUserQuestion with multiSelect=true:
  Question: "Override any of these decisions? (Select to override; leave unchecked to accept recommendation.)"
  Options: one per decision, label = "Override #N: <decision name>", description = "Currently: <recommended>. Selecting opens free-text for your alternative."

For each option the user selects, prompt with AskUserQuestion (free-text via 'Other') for the user's preferred alternative.
</confirm>

<output>
Persist the final decision set (recommended + user-overridden) in conversation context. They will be written into the generated PRP's `<context><decisions>` sub-element so executor Claude knows the path was chosen, not assumed.

**Skip this step entirely if zero non-trivial decisions exist** (a purely mechanical PRP — e.g., "rename function X to Y everywhere" — has no architectural decisions to log).
</output>
</step_2.7_decision_log>

<step_3_sizing_assessment>
**PRP Sizing Assessment (automatic — splitting is a recommendation, not a requirement)**

Before generating any PRP files, perform a sizing assessment. The assessment recommends whether to split the feature across multiple PRPs based on the recommended envelope. The recommendation is informational — if the user has explicitly directed a single PRP regardless of size, honor that directive.

<prp_constraints>
**Recommended Sizing Envelope (soft — honor explicit user override):**

| Constraint | Recommended Limit |
|------------|-------------------|
| Tasks (all small effort) | up to 40 |
| Tasks (all medium effort) | up to 30 |
| Tasks (mixed small + medium) | 30–40 (scaled toward complexity) |
| Lines per PRP file | up to 5,000 |
| Allowed task effort sizes | Small (S) and Medium (M) only |

**Why these are recommendations, not hard caps:**
Modern Claude Code (1M context Opus 4.7 / Sonnet 4.6) ingests a 5,000-line PRP in one Read with ~98% of the window free for execution. The binding constraint is now human reviewability, which is preference-driven. If the user explicitly says "one PRP, even if big", honor it.

**Key Rules (still apply):**
- L and XL effort tasks must be decomposed into S or M before counting.
- Each PRP should contain only S or M effort tasks.
- Verbose pseudocode pushes line count faster than task count — sanity-check both numbers before recommending a split.
</prp_constraints>

<assessment_process>
**Step 3a: Decompose into Full Task List**

Analyze the feature requirements (expanded or original) and identify ALL implementation tasks needed:
1. List every discrete implementation task
2. Include setup, core logic, integration, testing, and documentation tasks
3. Do NOT skip tasks to fit constraints — list the real scope

**Step 3b: Classify Each Task**

For each task, classify effort as Small (S) or Medium (M):
- **S (Small):** < 15 min, single file, clear pattern exists
- **M (Medium):** 15-30 min, 2-3 files, some decisions needed
- If a task is L or XL, decompose it into multiple S/M tasks

**Step 3c: Calculate PRP Count**

Apply these rules to determine how many PRPs are needed:

```
total_tasks = count of all S + M tasks
small_count = count of S tasks
medium_count = count of M tasks

# Task count check (new envelope)
if medium_count == 0:
    max_tasks_per_prp = 40        # was 20
elif small_count == 0:
    max_tasks_per_prp = 30        # was 15
else:
    medium_ratio = medium_count / total_tasks
    max_tasks_per_prp = round(40 - (10 * medium_ratio))   # scales 30–40 by ratio

prps_needed_by_count = ceil(total_tasks / max_tasks_per_prp)

# Line count check (per-task estimates unchanged; budget doubled)
estimated_lines = (small_count * 80) + (medium_count * 120) + 200
prps_needed_by_lines = ceil(estimated_lines / 5000)        # was 2400

prps_needed = max(prps_needed_by_count, prps_needed_by_lines)
```

**Step 3d: Report Assessment**

Output the sizing assessment summary BEFORE proceeding:

```
## PRP Sizing Assessment

**Total tasks identified:** [N]
**Effort breakdown:** [X] small, [Y] medium
**Estimated total lines:** [N]
**PRPs required:** [N]

| PRP | Tasks | Effort Mix | Est. Lines |
|-----|-------|------------|------------|
| PRP-{name}-part-1 | 1–[N] | [X]S / [Y]M | ~[N] |
| PRP-{name}-part-2 | [N+1]–[M] | [X]S / [Y]M | ~[N] |
| ... | ... | ... | ... |

**Grouping strategy:** [How tasks are grouped — by phase, by domain, by dependency chain]
```

If only 1 PRP is needed, state: "Feature fits within a single PRP — no splitting required."
</assessment_process>

<splitting_strategy>
When multiple PRPs are needed, group tasks by:

1. **Phase boundaries** (preferred) — Foundation tasks in PRP-1, Core in PRP-2, etc.
2. **Domain boundaries** — Backend tasks in one PRP, frontend in another
3. **Dependency chains** — Tasks that depend on each other stay in the same PRP

**Naming convention for multi-PRP features:**
- `PRPs/PRP-{feature-name}-part-1.md`
- `PRPs/PRP-{feature-name}-part-2.md`
- etc.

**Each PRP must be independently executable** — it should not require another PRP to be running simultaneously. Sequential execution (PRP-1 before PRP-2) is fine.
</splitting_strategy>
</step_3_sizing_assessment>

<step_4_invoke_software_architect>
**Invoke Software Architect Skill**

Now generate the PRP(s) using the software-architect skill's workflow. If the sizing assessment determined multiple PRPs are needed, generate each one following the same workflow.

<load_skill>
Invoke the software-architect skill for PRP creation guidance:

```
Invoke: /$PLUGIN_NAME:software-architect
```

The skill provides:
- PRP creation workflow
- PRP template structure
- Best practices for PRPs
</load_skill>

<execute_workflow>
Follow the create-prp.md workflow EXACTLY with these inputs:

**Feature Requirements:**
- If expanded: Use the expanded_requirements from step_2
- If original was detailed: Use $ARGUMENTS directly
- Apply the sizing assessment from step_3 to scope each PRP

**Workflow Steps to Execute:**
1. Clarify Requirements (step_1_clarify) - may skip if already expanded
2. Analyze Codebase (step_2_analyze_codebase) - REQUIRED, always do this
3. **Research Existing Solutions (step_2b_research_existing_solutions)** - REQUIRED, don't reinvent the wheel
   - Search for proven libraries, patterns, and best practices
   - Check official documentation for frameworks/services involved
   - Document recommended libraries with rationale
   - Note common pitfalls to avoid
4. Design Phases (step_3_design_phases) - break into Foundation, Core, Integration, Validation
5. Create Tasks (step_4_create_tasks) - micro-tasks with XML structure, respecting PRP sizing constraints
6. Assign Agents (step_5_assign_agents) - backend-engineer, frontend-engineer, etc.
7. Rank Tasks (step_6_rank_tasks) - effort (S/M only) and value (H/M/L)
8. Add Validation (step_7_add_validation) - project-specific commands
9. Write Document (step_8_write_document) - full XML PRP structure with research-findings
10. Save and Verify (step_9_save_and_verify) - including line count verification

**For multi-PRP features:** Repeat steps 4-10 for each PRP, using the task groupings from the sizing assessment.
</execute_workflow>

<critique_pass>
**Devil's-Advocate Critique (B3) — internal QA before save**

After the architect skill produces the task list, run this critique pass IN THE SAME CONTEXT (no extra user prompt). For each of the four checks below, flag any task / phase that fails. After the pass, surface flagged items to the user via AskUserQuestion before save.

**Check 1 — Verifiability:** For each task, is the acceptance criterion executable? (Could you write a Bash one-liner that returns 0 on success and non-zero on failure?) "Works correctly", "looks good", "is clean" → flag.

**Check 2 — Phase boundaries:** For each phase boundary, could the next phase actually start before this phase finishes? If yes, the phase boundary is artificial — note it; the user may want to merge phases or reorder.

**Check 3 — Agent fit:** For each agent assignment, does the agent have the tools listed in its agents/<name>.md frontmatter to actually perform this task? Or is the agent assigned for "shape" only? Flag obvious mismatches (e.g., `data-engineer` assigned a UI styling task).

**Check 4 — Handoff integrity:** For each `<handoff><expects>X</expects>`, does some upstream `<handoff><produces>X</produces>` actually exist? Flag dangling expectations.

<flag_format>
Print, after the critique pass, a single block:
```
## Critique Pass Results

| Check | Task / Phase | Issue |
|-------|--------------|-------|
| Verifiability | task 2.3 | Acceptance criterion is "works correctly" — replace with executable check |
| Phase boundary | phase 2 → 3 | Tasks 2.4 and 3.1 have no dependency; consider merging |
| ... | ... | ... |
```

If all checks pass on all tasks, print: `Critique pass: clean. Proceeding to save.`
</flag_format>

<user_confirm_if_flagged>
If any flags exist, use AskUserQuestion:
  Question: "Critique pass found N issue(s). How to proceed?"
  Options:
    1. "Auto-fix verifiability issues (replace vague criteria with executable checks where possible) and proceed." (Recommended)
    2. "I'll review the PRP after save and fix manually."
    3. "Stop — let me adjust the input and regenerate."
</user_confirm_if_flagged>
</critique_pass>

<xml_structure_requirements>
The generated PRP MUST use the full XML structure from templates/prp-template.md:

```xml
<prp name="[feature-name]" version="1.0">
  <metadata>...</metadata>
  <goal>...</goal>
  <intent-anchors>
    <what>...</what>
    <who>...</who>
    <why>...</why>
    <out-of-scope>
      <item>...</item>
    </out-of-scope>
    <success-signal>...</success-signal>
  </intent-anchors>
  <context>
    <decisions>
      <decision id="D1">
        <topic>...</topic>
        <choice>...</choice>
        <rationale>...</rationale>
      </decision>
    </decisions>
    ...
  </context>
  <codebase-analysis>
    <existing-patterns>...</existing-patterns>
    <affected-files>...</affected-files>
    <dependencies>...</dependencies>
    <gotchas>...</gotchas>
  </codebase-analysis>
  <research-findings>
    <recommended-libraries>
      <library name="..." purpose="...">
        <rationale>Why this over alternatives</rationale>
        <docs-url>Link to docs</docs-url>
        <install>npm install X</install>
      </library>
    </recommended-libraries>
    <patterns-to-follow>...</patterns-to-follow>
    <pitfalls-to-avoid>...</pitfalls-to-avoid>
    <documentation-references>...</documentation-references>
  </research-findings>
  <phases>
    <phase id="N" name="...">
      <tasks>
        <task id="N.N" agent="..." effort="..." value="...">
          <description>...</description>
          <files>...</files>
          <pseudocode>...</pseudocode>
          <acceptance-criteria>...</acceptance-criteria>
          <handoff>...</handoff>
        </task>
      </tasks>
    </phase>
  </phases>
  <validation>
    <level name="syntax" run-after="each-task">...</level>
    <level name="unit" run-after="phase">...</level>
    <level name="integration" run-after="all">...</level>
  </validation>
  <success-criteria>...</success-criteria>
  <anti-patterns>...</anti-patterns>
</prp>
```

Use the full XML structure. Executor Claude (`/KGP:prp-execute`) reads `<intent-anchors>` to disambiguate execution decisions, `<context><decisions>` to honor locked architectural choices, and `<task agent=...>` / `<acceptance-criteria>` / `<handoff>` to drive the per-task loop. Simplified markdown PRPs miss this structure and execute less accurately.
</xml_structure_requirements>
</step_4_invoke_software_architect>

<step_5_save_and_report>
**Save PRP(s) and Report**

<save_location>
**Single PRP:**
Save to: `PRPs/PRP-{feature-name}.md`

**Multiple PRPs:**

Default naming: `PRPs/PRP-{feature-name}-part-1.md`, `-part-2.md`, etc.

**Before saving, offer human-named filenames** via AskUserQuestion:
  Question: "Multiple PRPs are recommended. Use generic `-part-N` filenames or provide your own?"
  Options:
    1. "Use my own names (better for readability)." → for each part, AskUserQuestion (free-text via 'Other') for the suffix. Result: `PRP-{feature-name}-{user-suffix}.md`. (Recommended)
    2. "Use default `-part-N` filenames." → proceed with the defaults above.

Examples of human-named filenames the user might provide:
  - `PRP-auth-foundation.md` + `PRP-auth-oauth.md` (instead of `PRP-auth-part-1.md` + `-part-2.md`)
  - `PRP-payments-stripe-setup.md` + `PRP-payments-checkout-flow.md`

Where {feature-name} is kebab-case derived from the feature (e.g., "user-authentication", "payment-integration").

Create the PRPs directory if it doesn't exist:
```bash
mkdir -p PRPs
```
</save_location>

<verification>
After saving, verify EACH PRP:
- [ ] File exists at correct path
- [ ] XML structure is valid (all tags properly closed)
- [ ] All tasks have agent assignments
- [ ] All tasks have effort/value rankings (S or M effort only)
- [ ] Validation commands are project-specific
- [ ] Task count within recommended envelope (up to 40 all-S, up to 30 all-M, 30–40 mixed)
- [ ] File does NOT exceed 5,000 lines (recommended; honor explicit user override for larger PRPs)
- [ ] No L or XL effort tasks remain (all decomposed to S/M)
</verification>

<report_output>
Provide completion report:

```
## PRP Created

**Sizing Assessment:**
- Total tasks identified: [N]
- Effort breakdown: [X] small, [Y] medium
- PRPs generated: [N]

**Location(s):** `PRPs/PRP-{feature-name}.md`
[or list each PRP-part file for multi-PRP features]

| PRP File | Tasks | Lines | Effort Mix |
|----------|-------|-------|------------|
| PRP-{name}.md | [N] | [N] | [X]S / [Y]M |

**Summary:**
- Input type: [SHORT (expanded) | DETAILED (direct)]
- Phases: [X]
- Tasks: [Y] total ([Z] high-priority)
- Agents: [list of assigned agents]
- Estimated scope: [S|M|L|XL]

**Confidence Rationale:**

| Dimension | Score | Notes |
|-----------|-------|-------|
| Requirement clarity | X/10 | [reason] |
| Codebase fit | X/10 | [reason] |
| Library/dependency choices | X/10 | [reason] |
| Task verifiability | X/10 | [reason — based on critique pass results] |
| Risk of intent drift | X/10 | [reason — was step 2.5 intent-lock a tight match?] |
| **Overall** | **X/10** | (geometric mean of above) |

**Lowest-confidence dimension:** [name] — recommend addressing before execution: [specific actionable suggestion]

**Execute (single PRP):**
```bash
/KGP:prp-execute PRPs/PRP-{feature-name}.md
```

**Execute (multiple related PRPs in one session):**
```bash
/KGP:prp-execute PRPs/PRP-{feature-name}-foundation.md PRPs/PRP-{feature-name}-core.md
```

**Execute with Agent Teams (experimental):**
```bash
/KGP:prp-execute PRPs/PRP-{feature-name}.md --team
```

**Validate first (recommended for new PRP authors):**
```bash
/KGP:prp-validate PRPs/PRP-{feature-name}.md
```
```
</report_output>
</step_5_save_and_report>

</process>

<quality_checklist>
Before saving, verify EACH PRP meets these criteria:

**Sizing Envelope (recommended):**
- [ ] Sizing assessment was performed before PRP generation
- [ ] All tasks are Small (S) or Medium (M) effort — no L or XL tasks
- [ ] Task count within recommended envelope: up to 40 (all S), up to 30 (all M), 30–40 (mixed)
- [ ] File does NOT exceed 5,000 lines (recommended; honor explicit user override)
- [ ] If multiple PRPs are saved, each is independently executable AND has a meaningful filename (per B7)

**Structure:**
- [ ] Uses full XML structure (not simplified markdown)
- [ ] All XML tags properly nested and closed
- [ ] Phases are logically ordered (Foundation -> Core -> Integration -> Validation)

**Tasks:**
- [ ] Each task is micro-sized (15-30 min of focused work)
- [ ] All tasks have agent assignments from valid list
- [ ] All tasks have effort (S/M) and value (H/M/L) rankings
- [ ] Acceptance criteria are specific and verifiable (not "works correctly")
- [ ] Handoff information specifies expects/produces

**Context:**
- [ ] Codebase patterns are specific (actual file paths, not placeholders)
- [ ] Pseudocode matches project style
- [ ] Dependencies list actual package names and versions

**Validation:**
- [ ] Commands are project-specific (detected from package.json, pyproject.toml, etc.)
- [ ] All three levels present (syntax, unit, integration)
- [ ] Commands will actually work in this project
</quality_checklist>

<anti_patterns>
Avoid these common mistakes:

**Input Handling:**
- Don't skip expansion for genuinely vague inputs
- Don't over-expand already-detailed inputs
- Don't make up requirements not mentioned by user

**PRP Generation:**
- Don't skip the sizing assessment — it runs automatically and produces a recommendation
- Don't auto-split unless the feature genuinely benefits from milestone separation; honor explicit single-PRP user requests even at large size
- Don't leave L or XL effort tasks — decompose them into S/M
- Don't use placeholder file paths like "src/feature/index.ts"
- Don't generate vague acceptance criteria like "works correctly"
- Don't skip codebase analysis phase
- Don't skip the intent-lock step — drift is cheaper to catch before generation than after
- Don't forget validation commands

**Agent Assignment:**
- Don't assign all tasks to one agent
- Use only agents discovered in step_0 agent_discovery (typically: backend-engineer, frontend-engineer, data-engineer, qa-engineer, devops-engineer, document-specialist, project-coordinator)
- Don't forget to assign agent to every task
- Match agent to task type based on keywords (see agent_discovery table)
</anti_patterns>

<success_criteria>
- Input evaluated and classified correctly
- Short inputs expanded through sub-agent questioning
- **Sizing assessment performed automatically before PRP generation**
- **All tasks classified as Small (S) or Medium (M) effort only**
- **Task count within recommended envelope (up to 40 S / up to 30 M / 30–40 mixed)**
- **No single PRP exceeds 5,000 lines (recommended)**
- **Multi-PRP splitting applied when it improves human reviewability or aligns with logical milestones**
- **Intent-lock confirmed with user before generation (B1)**
- **Architectural decisions logged in `<context><decisions>` (B2)**
- **Devil's-advocate critique pass run before save (B3)**
- Software-architect workflow executed completely
- PRP uses full XML structure with micro-tasks
- All tasks have agent assignments and effort/value rankings
- Validation commands are project-specific and executable
- PRP(s) saved to correct location
- User provided clear next steps for execution
</success_criteria>

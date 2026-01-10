---
description: "[KGP] Execute a PRP file through Ralph Loop for iterative task completion"
argument-hint: <path-to-prp.md> [--max-iterations N] [--completion-promise 'PHRASE']
allowed-tools: [Read, Bash, Glob, Grep, Task]
---

# PRP Execute via Ralph Loop

Execute a Product Requirement Prompt through the Ralph Loop iterative system for reliable task completion.

<objective>
Load the PRP at: $ARGUMENTS
Parse its structure and construct a Ralph Loop invocation that will execute the PRP iteratively until all tasks are complete.
</objective>

<process>

<step_0_agent_discovery>
## Step 0: Discover Available Agents

Before execution, scan for specialized agents that can handle specific task types more effectively.

**Scan agent directory:**
```
Glob: agents/*.md
```

**Build agent capability map from discovered agents:**
For each agent file found, extract:
- `name` from frontmatter
- `description` for capability matching
- Core competencies from the agent's content

**Standard agent-to-task mapping (if agents found):**
| Task Keywords | Recommended Agent |
|--------------|-------------------|
| API, endpoint, service, auth, backend, business logic | backend-engineer |
| UI, component, page, style, frontend, accessibility | frontend-engineer |
| schema, migration, query, database, data model | data-engineer |
| test, security, review, QA, coverage | qa-engineer |
| CI/CD, deploy, Docker, infrastructure, monitoring | devops-engineer |
| documentation, README, docs, technical writing | document-specialist |
| planning, sprint, task breakdown, coordination | project-coordinator |

**Agent delegation strategy:**
When executing tasks via Ralph Loop, include agent recommendations in the prompt so Claude can delegate appropriately using the Task tool with the matched `subagent_type`.
</step_0_agent_discovery>

<step_1_load_prp>
## Step 1: Load and Parse PRP

Read the PRP file from the path provided in $ARGUMENTS (first non-flag argument).

Extract these elements based on the PRP format:

**For XML-structured PRPs (with `<prp>` tags):**
- `name` from `<prp name="...">`
- `goal` from `<goal>` element
- `phases` and `tasks` from `<phases>` element
- `validation` from `<validation>` element
- `success-criteria` from `<success-criteria>` element

**For Markdown-structured PRPs:**
- `name` from the first `# PRP:` or `#` heading
- `goal` from `## Goal` section
- `tasks` from `## Implementation Blueprint` or `## Tasks` section
- `validation` from `## Validation Loop` or `## Validation` section
- `success-criteria` from `## Success Criteria` or the checklist items in `## What` section

Count the total number of tasks found.
</step_1_load_prp>

<step_2_parse_options>
## Step 2: Parse Command Options

Parse $ARGUMENTS for optional overrides:

- `--max-iterations N` - Override default iteration count
- `--completion-promise 'PHRASE'` - Override default completion phrase

Calculate defaults if not provided:
```
max_iterations = (task_count * 2) + 5
completion_promise = "PRP COMPLETE"
```

Example: A PRP with 7 tasks would default to (7 * 2) + 5 = 19 max iterations.
</step_2_parse_options>

<step_3_construct_prompt>
## Step 3: Construct Ralph Loop Prompt

Build the execution prompt using this template:

```
Execute PRP: [PRP-NAME]

GOAL: [Goal extracted from PRP]

TASKS:
[Formatted list of phases/tasks from PRP, preserving structure]
- Phase 1: [phase name]
  - Task 1.1: [task description]
  - Task 1.2: [task description]
- Phase 2: [phase name]
  - Task 2.1: [task description]
  ...

VALIDATION (run after each task):
[Validation commands from PRP, or these defaults if none specified:]
- Run linting: npm run lint || ruff check .
- Run type checking: npm run typecheck || mypy .
- Run tests: npm test || pytest

COMPLETION CRITERIA:
When ALL of these are true, output <promise>[COMPLETION_PROMISE]</promise>:
[List of success criteria from PRP]
- [ ] Criterion 1
- [ ] Criterion 2
...

AVAILABLE AGENTS (use Task tool with subagent_type to delegate):
[List agents discovered in step_0, with their specializations]
- backend-engineer: APIs, auth, services, business logic
- frontend-engineer: UI, components, accessibility, performance
- data-engineer: Schema, migrations, queries, data modeling
- qa-engineer: Testing, security, code review
- devops-engineer: CI/CD, Docker, infrastructure
- document-specialist: Documentation, PRDs, technical writing

INSTRUCTIONS:
1. Read the full PRP at [PRP_PATH]
2. For each task, consider delegating to the most appropriate agent using Task tool
3. Work through tasks in phase order
4. Run validation after completing each task
5. If validation fails, fix before proceeding
6. After all tasks complete, verify ALL success criteria
7. ONLY output the promise when genuinely complete
8. You can see your previous work in files and git history
```
</step_3_construct_prompt>

<step_4_invoke_ralph_loop>
## Step 4: Invoke Ralph Loop

Display the execution plan to the user:

```
## PRP Execution Plan

**PRP:** [name]
**Path:** [path]
**Tasks:** [task_count]
**Max Iterations:** [max_iterations]
**Completion Promise:** "[completion_promise]"

Starting Ralph Loop execution...
```

Then invoke the Ralph Loop using the Skill tool:

```
/ralph-loop "[constructed prompt]" --max-iterations [N] --completion-promise '[PHRASE]'
```

The Ralph Loop will:
1. Feed the prompt to Claude
2. On each iteration exit, feed the SAME prompt back
3. Claude sees previous work in files/git
4. Continue until completion promise is output or max iterations reached
</step_4_invoke_ralph_loop>

</process>

<fallback_handling>
## Handling Edge Cases

**If PRP path not found:**
- Report error: "PRP file not found at: [path]"
- Suggest using `/prp-create` to create a new PRP

**If PRP structure unclear:**
- Make best effort to extract goal and tasks from any markdown structure
- Default to treating each `##` or `###` heading under "Tasks" or "Implementation" as a task

**If no validation commands found:**
- Use default validation: `npm run lint && npm run typecheck && npm test` (for JS projects)
- Or: `ruff check . && mypy . && pytest` (for Python projects)
- Detect project type from package.json or pyproject.toml presence

**If no success criteria found:**
- Default criteria: "All tasks completed successfully" and "All validation checks pass"
</fallback_handling>

<example_invocation>
## Example

Given a PRP at `PRPs/active/auth-feature/prp.md` with 5 tasks:

```bash
/prp-execute PRPs/active/auth-feature/prp.md
```

This will:
1. Parse the PRP and find 5 tasks
2. Calculate max_iterations = (5 * 2) + 5 = 15
3. Use default completion_promise = "PRP COMPLETE"
4. Construct the execution prompt
5. Invoke: `/ralph-loop "[prompt]" --max-iterations 15 --completion-promise 'PRP COMPLETE'`

With overrides:
```bash
/prp-execute PRPs/active/auth-feature/prp.md --max-iterations 10 --completion-promise 'AUTH FEATURE DONE'
```
</example_invocation>

<success_criteria>
- PRP file successfully loaded and parsed
- Key elements (goal, tasks, validation, success criteria) extracted
- Sensible max iterations calculated based on task count
- Ralph Loop invoked with well-formed prompt
- User informed of execution plan before loop starts
</success_criteria>

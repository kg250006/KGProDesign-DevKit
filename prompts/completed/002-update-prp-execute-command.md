<objective>
Update the `/prp-execute` command at `commands/dev/prp-execute.md` to execute PRPs through the Ralph Loop system.

Ralph Loop is an iterative self-referential development loop that:
1. Takes a prompt and feeds it back to Claude on each iteration
2. Continues until a completion promise is fulfilled or max iterations reached
3. Allows Claude to see previous work in files/git, enabling iterative refinement

The updated command should feed the PRP into Ralph Loop, letting it process micro-tasks iteratively until the entire PRP is complete.
</objective>

<context>
Read and understand these files:
- @commands/dev/prp-execute.md (current implementation to update)
- @commands/ralph-loop.md (Ralph Loop command structure)
- @scripts/setup-ralph-loop.sh (how Ralph Loop initializes)
- @skills/software-architect/templates/prp-template.md (PRP structure Ralph Loop will consume)
- @skills/software-architect/references/prp-best-practices.md (Ralph Loop integration guidelines)

**How Ralph Loop works:**
1. `/ralph-loop PROMPT --completion-promise 'PHRASE' --max-iterations N`
2. Creates `.claude/ralph-loop.local.md` with state
3. Stop hook prevents exit and feeds SAME PROMPT back
4. Claude sees previous work in files, iteratively improving
5. Exits when completion promise is TRUE or max iterations reached
6. To complete, Claude outputs: `<promise>PHRASE</promise>`

**PRP structure for Ralph Loop consumption:**
- PRPs have `<phases>` with `<phase>` containing `<tasks>`
- Each `<task>` has id, agent, effort, value, acceptance-criteria
- PRPs have `<validation>` commands at syntax, unit, integration levels
- PRPs have `<success-criteria>` for overall completion
</context>

<requirements>

<ralph_loop_integration>
The command should:

1. **Load and parse the PRP** from $ARGUMENTS path
2. **Extract key elements** for Ralph Loop prompt:
   - Goal statement
   - List of phases and tasks
   - Validation commands
   - Success criteria
3. **Construct a Ralph Loop prompt** that instructs Claude to:
   - Work through tasks in order by phase
   - Mark tasks complete in the PRP file or tracking file
   - Run validation after each task/phase
   - Only output the completion promise when ALL success criteria are met
4. **Invoke Ralph Loop** with appropriate settings:
   - Completion promise: Derived from PRP success criteria
   - Max iterations: Based on task count (estimate ~2 iterations per task)
</ralph_loop_integration>

<prompt_construction>
The Ralph Loop prompt should be structured as:

```
Execute PRP: [PRP-name]

GOAL: [Goal from PRP]

TASKS:
[Formatted list of phases and tasks from PRP]

VALIDATION (run after each task):
[Validation commands from PRP]

COMPLETION CRITERIA:
When ALL of these are true, output <promise>PRP COMPLETE</promise>:
[List of success criteria from PRP]

INSTRUCTIONS:
1. Read the full PRP at [path]
2. Work through tasks in phase order
3. Update task status as you complete each one
4. Run validation after completing each task
5. If validation fails, fix before proceeding
6. After all tasks complete, verify ALL success criteria
7. ONLY output the promise when genuinely complete
```
</prompt_construction>

<iteration_settings>
Calculate reasonable defaults:

- **Max iterations**: `(number_of_tasks * 2) + 5` (buffer for validation/fixes)
- **Completion promise**: "PRP COMPLETE" (standard phrase)

Allow overrides via command arguments:
- `--max-iterations N` to override calculated default
- `--completion-promise 'PHRASE'` to use custom phrase
</iteration_settings>

<progress_tracking>
During execution, Ralph Loop will:
- Work in current session (not background)
- See previous file changes on each iteration
- Can mark tasks as complete in the PRP file itself or a separate tracking file
- Continue until promise is output or max iterations reached
</progress_tracking>

</requirements>

<implementation>

**Command frontmatter to update:**
```yaml
---
description: "[KGP] Execute a PRP file through Ralph Loop for iterative task completion"
argument-hint: <path-to-prp.md> [--max-iterations N] [--completion-promise 'PHRASE']
allowed-tools: [Read, Bash, Glob, Grep]
---
```

**Logic structure:**
```xml
<process>
<step_1_load_prp>
Read PRP file from $ARGUMENTS (first non-flag argument)
Parse XML structure to extract:
- prp name from <prp name="...">
- goal from <goal>
- phases and tasks from <phases>
- validation from <validation>
- success-criteria from <success-criteria>
</step_1_load_prp>

<step_2_parse_options>
Parse remaining $ARGUMENTS for:
- --max-iterations N (optional override)
- --completion-promise 'PHRASE' (optional override)

Calculate defaults if not provided:
- max_iterations = (task_count * 2) + 5
- completion_promise = "PRP COMPLETE"
</step_2_parse_options>

<step_3_construct_prompt>
Build the Ralph Loop prompt string containing:
- Clear goal statement
- Formatted task list with IDs
- Validation commands
- Success criteria
- Instructions for iterative completion
</step_3_construct_prompt>

<step_4_invoke_ralph_loop>
Execute: /ralph-loop [prompt] --max-iterations [N] --completion-promise '[PHRASE]'

This starts the iterative loop in the current session.
</step_4_invoke_ralph_loop>
</process>
```

**Key behavior:**
- Command transforms PRP into Ralph Loop execution
- User watches iteration progress in real-time
- Each iteration shows Claude working on next task
- Loop exits when complete or max iterations reached
</implementation>

<output>
Save the updated command to: `./commands/dev/prp-execute.md`

The file should completely replace the existing content with the Ralph Loop integration.
</output>

<verification>
After updating, verify:
1. Command file exists at commands/dev/prp-execute.md
2. Command parses PRP file path from arguments
3. Command extracts tasks, validation, success criteria from PRP XML
4. Command calculates reasonable default iterations
5. Command constructs proper Ralph Loop prompt
6. Command invokes /ralph-loop with correct arguments
7. Completion promise is derived from PRP success criteria
</verification>

<success_criteria>
- Updated command loads and parses PRP XML structure
- Constructs coherent Ralph Loop prompt from PRP contents
- Calculates sensible default max iterations
- Invokes Ralph Loop correctly
- Provides clear feedback about loop start and expected completion
- Handles both XML-structured PRPs and markdown-format PRPs gracefully
</success_criteria>

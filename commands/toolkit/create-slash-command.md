---
description: "[KGP] Create Claude Code slash commands with YAML frontmatter and proper structure"
argument-hint: [command name and purpose]
allowed-tools: [Read, Write, Glob, AskUserQuestion]
---

<objective>
Create a new slash command for: $ARGUMENTS

Slash commands are invoked with `/command-name` and provide guided workflows.
</objective>

<process>

<step_1_clarify>
**Clarify Command Requirements**

Gather:
- What should the command do?
- Does it need arguments?
- What tools does it require?
- What category does it belong to? (core, workflow, analysis, etc.)
</step_1_clarify>

<step_2_design>
**Design Command**

Determine:
- **Name:** Short, descriptive (kebab-case)
- **Description:** Action-oriented, starts with verb
- **Arguments:** What inputs it accepts
- **Tools:** What tools it needs access to
- **Category:** For directory organization
</step_2_design>

<step_3_generate>
**Generate Command**

Structure:

```markdown
---
description: [Action-oriented description]
argument-hint: [<required> [optional]]
allowed-tools: [Tool1, Tool2, Tool3]
---

<objective>
[What this command accomplishes]
[Use $ARGUMENTS or $1, $2 for argument substitution]
</objective>

<context>
[Dynamic context to load]
@[file references]
![bash commands for context]
</context>

<process>

<step_1>
**Step Title**

[What to do in this step]
</step_1>

<step_2>
**Step Title**

[What to do in this step]
</step_2>

</process>

<output_format>
[How to structure the output]
</output_format>

<success_criteria>
[What defines success]
</success_criteria>
```
</step_3_generate>

<step_4_save>
**Save Command**

Save to: `.claude/commands/[category]/[name].md`

Categories:
- core/ - Essential commands
- workflow/ - Git, PR, commit
- prp/ - PRP-related
- analysis/ - Analysis and review
- toolkit/ - Meta/creation commands
- utility/ - Helper commands
</step_4_save>

<step_5_test>
**Test Command**

Invoke: `/[command-name] [test arguments]`

Verify:
- Arguments are parsed correctly
- Steps execute as expected
- Output matches format
</step_5_test>

</process>

<output_format>
## Slash Command Created

**File:** `.claude/commands/[category]/[name].md`
**Invoke:** `/[name] [arguments]`

**Test with:**
```
/[name] [example arguments]
```
</output_format>

<success_criteria>
- Valid YAML frontmatter
- Clear objective
- Structured process steps
- Output format defined
- Saved in correct category
</success_criteria>

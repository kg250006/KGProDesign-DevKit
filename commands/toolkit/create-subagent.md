---
description: "[KGP] Create specialized Claude Code subagents with role definition, tools, and prompt structure"
argument-hint: [agent name and purpose]
allowed-tools: [Read, Write, Glob, AskUserQuestion, WebSearch]
---

<objective>
Create a specialized subagent for: $ARGUMENTS

Subagents are launched via the Task tool and handle specific types of work autonomously.
</objective>

<process>

<step_1_clarify>
**Clarify Agent Purpose**

Gather:
- What specific domain/task will this agent handle?
- What tools does it need access to?
- What outputs should it produce?
- Any specific constraints or guidelines?
</step_1_clarify>

<step_2_design>
**Design Agent**

Determine:
- **Name:** Descriptive, action-oriented
- **Tools:** Minimum necessary for the task
- **Model:** sonnet (default) or haiku (for simple tasks)
- **Color:** For visual identification

Common tool sets:
- Read-only: `Read, Grep, Glob`
- Development: `Read, Write, Edit, Grep, Glob, Bash`
- Full: `Read, Write, Edit, MultiEdit, Grep, Glob, Bash, WebSearch, WebFetch, Task`
</step_2_design>

<step_3_generate>
**Generate Agent Configuration**

Follow this structure:

```markdown
---
name: [agent-name]
description: [Action-oriented description starting with verb]
tools: [Comma-separated list]
color: [Color name]
model: [sonnet|haiku] (optional)
---

## Principle 0: Radical Candor—Truth Above All

[Truthfulness mandate - include for production agents]

---

# Purpose

[Clear role definition - what this agent does and excels at]

## Core Competencies

- [Competency 1]
- [Competency 2]
- [Competency 3]

## Instructions

When invoked, follow these steps:

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Technical Standards

[Domain-specific guidelines and patterns]

## Output Format

[How results should be structured]

## Success Criteria

[What defines successful completion]
```
</step_3_generate>

<step_4_save>
**Save Agent**

Save to: `.claude/agents/[agent-name].md`
</step_4_save>

<step_5_test>
**Test Agent**

Provide test invocation:
```
Use Task tool with:
- subagent_type: "[agent-name]"
- prompt: "Test task description"
```
</step_5_test>

</process>

<output_format>
## Subagent Created

**File:** `.claude/agents/[name].md`
**Purpose:** [Brief description]
**Tools:** [List]

**Invoke with:**
```
Task tool:
- subagent_type: "[name]"
- prompt: "Your task description"
```
</output_format>

<success_criteria>
- Valid frontmatter (name, description, tools)
- Clear purpose and competencies
- Step-by-step instructions
- Output format defined
- Success criteria specified
</success_criteria>

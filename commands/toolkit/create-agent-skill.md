---
description: "[KGP] Create Claude Code skills with SKILL.md router pattern and progressive disclosure structure"
argument-hint: [skill name and purpose]
allowed-tools: [Read, Write, Glob, AskUserQuestion, WebSearch]
---

<objective>
Create a Claude Code skill for: $ARGUMENTS

Skills provide reusable expertise that Claude can invoke for specific domains.
</objective>

<process>

<step_1_clarify>
**Clarify Skill Requirements**

Gather:
- What domain/expertise does this skill cover?
- What workflows should it support?
- What reference materials are needed?
- What outputs should it produce?
</step_1_clarify>

<step_2_design>
**Design Skill Structure**

For simple skills (< 500 lines):
```
.claude/skills/[skill-name]/
  SKILL.md
```

For complex skills (router pattern):
```
.claude/skills/[skill-name]/
  SKILL.md          # Router - asks what you need
  references/       # Reference materials
  workflows/        # Step-by-step workflows
  templates/        # Output templates
```
</step_2_design>

<step_3_generate>
**Generate SKILL.md**

Use pure XML structure (no markdown headings in body):

```markdown
---
description: [Skill description for discovery]
---

<skill>

<purpose>
[What this skill helps with]
</purpose>

<capabilities>
<capability>[Capability 1]</capability>
<capability>[Capability 2]</capability>
<capability>[Capability 3]</capability>
</capabilities>

<router>
<question>What do you need help with?</question>
<option name="workflow-1">
  <description>[What this does]</description>
  <action>Load @references/workflow-1.md</action>
</option>
<option name="workflow-2">
  <description>[What this does]</description>
  <action>Load @references/workflow-2.md</action>
</option>
</router>

<quick_reference>
[Brief reference that can be used without loading workflows]
</quick_reference>

</skill>
```
</step_3_generate>

<step_4_workflows>
**Create Workflows (if complex)**

For each workflow in references/:
```markdown
# Workflow: [Name]

<objective>
[What this workflow accomplishes]
</objective>

<process>
<step>[Step 1]</step>
<step>[Step 2]</step>
</process>

<examples>
[Working examples]
</examples>
```
</step_4_workflows>

<step_5_save>
**Save Skill**

Save to: `.claude/skills/[skill-name]/SKILL.md`
Plus any references/, workflows/, templates/
</step_5_save>

</process>

<output_format>
## Skill Created

**Directory:** `.claude/skills/[name]/`
**Files:**
- SKILL.md (router)
- references/ (if needed)
- workflows/ (if needed)

**Invoke with:**
Reference the skill in conversation or CLAUDE.md
</output_format>

<success_criteria>
- Valid frontmatter
- Pure XML structure (no markdown headings)
- Router pattern for complex skills
- Progressive disclosure implemented
- Examples provided
</success_criteria>

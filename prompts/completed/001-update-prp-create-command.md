<objective>
Update the `/prp-create` command at `commands/dev/prp-create.md` to integrate with the software-architect skill and provide intelligent input expansion.

The updated command should:
1. Detect if the input argument is "short/vague" (under ~50 words, missing specifics, or lacks context)
2. If vague: First delegate to `/create-prompt` via a sub-agent to expand the requirement into a detailed feature description
3. Then invoke the software-architect skill's `workflows/create-prp.md` workflow to generate the actual PRP
4. Produce PRPs that are optimized for Ralph Loop execution (XML-structured with micro-tasks)

This matters because PRPs need sufficient detail for Ralph Loop to execute them autonomously. Short inputs like "add user auth" need expansion before PRP generation.
</objective>

<context>
Read and understand these files:
- @commands/dev/prp-create.md (current implementation to update)
- @skills/software-architect/SKILL.md (skill router for PRP creation)
- @skills/software-architect/workflows/create-prp.md (actual PRP generation workflow)
- @skills/software-architect/templates/prp-template.md (target PRP XML structure)
- @commands/dev/create-prompt.md (prompt expansion tool)
- @commands/ralph-loop.md (consumer of the PRPs)

The software-architect skill produces XML-structured PRPs with:
- `<phases>` containing `<phase>` elements
- `<task>` elements with agent assignments, effort/value rankings
- `<validation>` commands for each level
- `<acceptance-criteria>` for each task
</context>

<requirements>

<input_detection>
Determine if $ARGUMENTS is "short/vague":

**Short criteria (any of these):**
- Under 50 words total
- No mention of specific user flows or acceptance criteria
- Generic terms without specifics ("add feature", "implement X", "create Y")
- Missing technical context (no framework, database, or API mentions)

**Sufficiently detailed criteria (needs most of these):**
- 50+ words with specifics
- Mentions user stories or flows
- Includes technical constraints or patterns
- References existing code or integrations
</input_detection>

<workflow_for_short_input>
When input is detected as short/vague:

1. Use Task tool with subagent_type="general-purpose" to run `/create-prompt` with the short input
2. The create-prompt sub-agent will expand requirements through its questioning flow
3. Capture the expanded description from the generated prompt
4. Pass the expanded description to the software-architect skill workflow
</workflow_for_short_input>

<workflow_for_detailed_input>
When input is sufficiently detailed:

1. Skip the expansion step
2. Directly invoke the software-architect skill's create-prp workflow
3. The workflow will still ask clarifying questions if needed
</workflow_for_detailed_input>

<software_architect_integration>
After obtaining detailed requirements (either expanded or original):

1. Read @skills/software-architect/SKILL.md to load the skill
2. Signal intent: "1" or "PRP" to trigger workflows/create-prp.md
3. Pass the feature description/requirements
4. Follow the workflow's steps exactly:
   - Clarify requirements (step 1)
   - Analyze codebase (step 2)
   - Design phases (step 3)
   - Create micro-tasks (step 4)
   - Assign agents (step 5)
   - Rank effort/value (step 6)
   - Add validation (step 7)
   - Write document (step 8)
   - Save and verify (step 9)
</software_architect_integration>

<output_requirements>
- PRPs saved to `PRPs/PRP-{feature-name}.md`
- Use XML structure from templates/prp-template.md
- Include micro-tasks suitable for Ralph Loop
- Each task has: id, agent, effort, value, description, files, pseudocode, acceptance-criteria, handoff
- Include project-specific validation commands
</output_requirements>

</requirements>

<implementation>

**Command frontmatter to update:**
```yaml
---
description: "[KGP] Generate a comprehensive Product Requirement Prompt from feature requirements with research and context"
argument-hint: <feature description or requirements file>
allowed-tools: [Read, Write, Glob, Grep, Bash, WebSearch, WebFetch, AskUserQuestion, Task]
---
```

**Logic structure:**
```xml
<process>
<step_1_evaluate_input>
Evaluate $ARGUMENTS for detail level.
Classify as: SHORT (needs expansion) or DETAILED (ready for PRP)
</step_1_evaluate_input>

<step_2_expand_if_needed>
IF SHORT:
  Use Task tool to spawn sub-agent with /create-prompt command
  Capture expanded requirements
  Continue with expanded input
ELSE:
  Continue with original $ARGUMENTS
</step_2_expand_if_needed>

<step_3_invoke_software_architect>
Load skills/software-architect/SKILL.md
Follow workflows/create-prp.md exactly
Generate PRP with full XML structure
</step_3_invoke_software_architect>

<step_4_save_and_report>
Save PRP to PRPs/PRP-{feature-name}.md
Report location and next steps
</step_4_save_and_report>
</process>
```

**Pattern to avoid:**
- Don't use simplified markdown PRP format - use full XML structure
- Don't skip codebase research phase
- Don't generate tasks without agent assignments
- Don't forget validation commands specific to the project
</implementation>

<output>
Save the updated command to: `./commands/dev/prp-create.md`

The file should completely replace the existing content with the new integrated workflow.
</output>

<verification>
After updating, verify:
1. The command file exists at commands/dev/prp-create.md
2. Frontmatter includes Task tool in allowed-tools
3. Logic includes input evaluation for short vs detailed
4. Software-architect skill is properly referenced
5. Output format matches XML PRP template structure
6. Command references /ralph-loop for execution instructions
</verification>

<success_criteria>
- Updated command detects short inputs and expands them
- Software-architect skill workflow is invoked correctly
- Generated PRPs use full XML structure with micro-tasks
- PRPs include agent assignments, effort/value rankings
- PRPs include validation commands for Ralph Loop
- Command provides clear next steps for /prp-execute or /ralph-loop
</success_criteria>

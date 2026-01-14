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

A PRP provides ALL context needed for Ralph Loop to execute implementation autonomously. The goal is comprehensive XML-structured micro-tasks that an agent can implement without ambiguity.

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
- If DETAILED: Go to step_3_invoke_software_architect
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
    Limit to 3-5 focused questions (you can ask follow-ups based on answers).

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
3. Proceed to step_3_invoke_software_architect with the expanded requirements
</post_expansion>
</step_2_expand>

<step_3_invoke_software_architect>
**Invoke Software Architect Skill**

Now generate the PRP using the software-architect skill's workflow.

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

**Workflow Steps to Execute:**
1. Clarify Requirements (step_1_clarify) - may skip if already expanded
2. Analyze Codebase (step_2_analyze_codebase) - REQUIRED, always do this
3. Design Phases (step_3_design_phases) - break into Foundation, Core, Integration, Validation
4. Create Tasks (step_4_create_tasks) - micro-tasks with XML structure
5. Assign Agents (step_5_assign_agents) - backend-engineer, frontend-engineer, etc.
6. Rank Tasks (step_6_rank_tasks) - effort (S/M/L/XL) and value (H/M/L)
7. Add Validation (step_7_add_validation) - project-specific commands
8. Write Document (step_8_write_document) - full XML PRP structure
9. Save and Verify (step_9_save_and_verify)
</execute_workflow>

<xml_structure_requirements>
The generated PRP MUST use the full XML structure from templates/prp-template.md:

```xml
<prp name="[feature-name]" version="1.0">
  <metadata>...</metadata>
  <goal>...</goal>
  <context>...</context>
  <codebase-analysis>
    <existing-patterns>...</existing-patterns>
    <affected-files>...</affected-files>
    <dependencies>...</dependencies>
    <gotchas>...</gotchas>
  </codebase-analysis>
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

DO NOT use simplified markdown PRP format. Use full XML structure for Ralph Loop compatibility.
</xml_structure_requirements>
</step_3_invoke_software_architect>

<step_4_save_and_report>
**Save PRP and Report**

<save_location>
Save the PRP to: `PRPs/PRP-{feature-name}.md`

Where {feature-name} is kebab-case derived from the feature (e.g., "user-authentication", "payment-integration").

Create the PRPs directory if it doesn't exist:
```bash
mkdir -p PRPs
```
</save_location>

<verification>
After saving, verify:
- [ ] File exists at correct path
- [ ] XML structure is valid (all tags properly closed)
- [ ] All tasks have agent assignments
- [ ] All tasks have effort/value rankings
- [ ] Validation commands are project-specific
- [ ] Task count is appropriate (5-30 for typical feature)
</verification>

<report_output>
Provide completion report:

```
## PRP Created

**Location:** `PRPs/PRP-{feature-name}.md`

**Summary:**
- Input type: [SHORT (expanded) | DETAILED (direct)]
- Phases: [X]
- Tasks: [Y] total ([Z] high-priority)
- Agents: [list of assigned agents]
- Estimated scope: [S|M|L|XL]

**Confidence Score:** [X]/10
[Explanation: Why this score? What might need clarification?]

**Execute with task isolation (recommended):**
```bash
/KGP:prp-execute-isolated PRPs/PRP-{feature-name}.md
```

**Execute with Ralph Loop :**
```bash
/KGP:ralph-loop PRPs/PRP-{feature-name}.md
```

**Or execute directly:**
```bash
/KGP:prp-execute PRPs/PRP-{feature-name}.md
```

**Or validate first:**
```bash
/KGP:prp-validate PRPs/PRP-{feature-name}.md
```
```
</report_output>
</step_4_save_and_report>

</process>

<quality_checklist>
Before saving, verify the PRP meets these criteria:

**Structure:**
- [ ] Uses full XML structure (not simplified markdown)
- [ ] All XML tags properly nested and closed
- [ ] Phases are logically ordered (Foundation -> Core -> Integration -> Validation)

**Tasks:**
- [ ] Each task is micro-sized (15-30 min of focused work)
- [ ] All tasks have agent assignments from valid list
- [ ] All tasks have effort (S/M/L/XL) and value (H/M/L) rankings
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
- Don't use simplified markdown format - use full XML
- Don't use placeholder file paths like "src/feature/index.ts"
- Don't generate vague acceptance criteria like "works correctly"
- Don't skip codebase analysis phase
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
- Software-architect workflow executed completely
- PRP uses full XML structure with micro-tasks
- All tasks have agent assignments and effort/value rankings
- Validation commands are project-specific and executable
- PRP saved to correct location
- User provided clear next steps for execution
</success_criteria>

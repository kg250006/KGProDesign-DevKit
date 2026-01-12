---
name: software-architect
description: Expert guidance for creating PRPs (Product Requirement Prompts) and PRDs (Product Requirement Documents). PRPs are codebase-specific implementation plans with micro-tasks for Ralph Loop execution. PRDs are codebase-agnostic specifications portable to any project or team.
---

<essential_principles>
## How This Skill Works

This skill creates two types of documents that serve different purposes in the development lifecycle:

### 1. PRPs - Product Requirement Prompts (Codebase-Specific)

PRPs are **implementation blueprints** tailored to your specific codebase. They contain:
- Pseudo-code and snippets matching existing patterns
- File structure changes with specific paths
- Micro-task breakdowns with acceptance criteria
- Agent assignments (which expert handles each task)
- Effort vs. value rankings for prioritization
- Validation commands using your project's toolchain

**Purpose:** Feed directly into `/$PLUGIN_NAME:ralph-loop` for iterative autonomous implementation.

### 2. PRDs - Product Requirement Documents (Codebase-Agnostic)

PRDs are **portable specifications** that describe what to build without how:
- Functional requirements and user stories
- Technical constraints and dependencies
- Success metrics and acceptance criteria
- API contracts and data models (conceptual)
- Edge cases and error scenarios

**Purpose:** Share with any team, use across codebases, or hand to an engineer who will determine implementation.

### Core Principles

**1. XML Structure for Machine Parsing**
All tasks, features, and requirements use XML tags for reliable parsing by Ralph Loop and other tools.

**2. Progressive Disclosure**
Start with overview, then drill into details. Phases before tasks, tasks before subtasks.

**3. Research Before Writing**
Always analyze the codebase (PRPs) or gather requirements (PRDs) before generating documents.

**4. Validation Built-In**
Every PRP includes executable validation commands. Every PRD includes measurable acceptance criteria.

**5. Right-Sized Documents**
- Default: Single document with phases if needed
- Split into multiple documents only for gargantuan features (10+ major components)
</essential_principles>

<intake>
What would you like to create?

1. **PRP** - Implementation plan for THIS codebase (feeds Ralph Loop)
2. **PRD** - Portable specification (codebase-agnostic)
3. **PRP from PRD** - Convert existing PRD to codebase-specific PRP
4. **Guidance** - Help deciding which document type to create

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Next Action | Workflow |
|----------|-------------|----------|
| 1, "PRP", "implementation", "ralph" | Ask: "What feature/requirement?" | workflows/create-prp.md |
| 2, "PRD", "specification", "document" | Ask: "What feature/requirement?" | workflows/create-prd.md |
| 3, "convert", "from PRD" | Ask: "Path to PRD file?" | workflows/prp-from-prd.md |
| 4, "guidance", "help", "which" | Guide decision | workflows/guidance.md |

**Intent-based routing:**
- "create PRP for user auth" → workflows/create-prp.md (with context)
- "write a PRD for payment system" → workflows/create-prd.md (with context)
- "convert PRDs/PRD-auth.md to PRP" → workflows/prp-from-prd.md (with path)
- "should I use PRP or PRD?" → workflows/guidance.md

**After reading the workflow, follow it exactly.**
</routing>

<quick_reference>
## Document Structure Quick Reference

**PRP Structure (Implementation-Focused):**
```xml
<prp name="feature-name" version="1.0">
  <metadata>
    <created>YYYY-MM-DD</created>
    <target-branch>main</target-branch>
    <estimated-effort>S|M|L|XL</estimated-effort>
  </metadata>

  <goal>What needs to exist when done</goal>
  <context>Why this matters, business value</context>

  <codebase-analysis>
    <existing-patterns>Patterns to follow</existing-patterns>
    <affected-files>Files to modify/create</affected-files>
    <dependencies>Required packages/services</dependencies>
  </codebase-analysis>

  <phases>
    <phase id="1" name="Foundation">
      <tasks>
        <task id="1.1" agent="backend-engineer" effort="M" value="H">
          <description>What to do</description>
          <files>
            <file action="modify">src/path/file.ts</file>
          </files>
          <pseudocode>Implementation hints</pseudocode>
          <acceptance-criteria>
            <criterion>Verifiable outcome</criterion>
          </acceptance-criteria>
        </task>
      </tasks>
    </phase>
  </phases>

  <validation>
    <level name="syntax">npm run lint && npm run typecheck</level>
    <level name="unit">npm test</level>
    <level name="integration">npm run test:e2e</level>
  </validation>
</prp>
```

**PRD Structure (Specification-Focused):**
```xml
<prd name="feature-name" version="1.0">
  <metadata>
    <created>YYYY-MM-DD</created>
    <status>draft|review|approved</status>
    <stakeholders>Roles involved</stakeholders>
  </metadata>

  <executive-summary>
    <problem>What problem this solves</problem>
    <solution>High-level approach</solution>
    <success-metrics>How we measure success</success-metrics>
  </executive-summary>

  <requirements>
    <functional>
      <requirement id="F1" priority="P0|P1|P2">
        <description>What the system must do</description>
        <user-story>As a..., I want..., so that...</user-story>
        <acceptance-criteria>
          <criterion>Testable outcome</criterion>
        </acceptance-criteria>
      </requirement>
    </functional>
    <non-functional>
      <requirement id="NF1" category="performance|security|scale">
        <description>Quality attribute</description>
        <metric>Measurable target</metric>
      </requirement>
    </non-functional>
  </requirements>

  <technical-design>
    <data-model>Entity relationships</data-model>
    <api-contracts>Endpoint definitions</api-contracts>
    <integrations>External dependencies</integrations>
  </technical-design>

  <edge-cases>
    <case id="E1">
      <scenario>What could go wrong</scenario>
      <handling>How to handle it</handling>
    </case>
  </edge-cases>
</prd>
```

## Output Locations

- PRPs: `PRPs/PRP-{feature-name}.md`
- PRDs: `PRDs/PRD-{feature-name}.md`

Directories are created automatically if they don't exist.
</quick_reference>

<agent_mapping>
## Expert Agent Assignments

When creating PRPs, assign tasks to appropriate agents:

| Agent | Task Types |
|-------|------------|
| backend-engineer | API endpoints, business logic, services, auth |
| frontend-engineer | UI components, state management, styling |
| data-engineer | Schema design, migrations, queries |
| qa-engineer | Test strategy, test implementation, security review |
| devops-engineer | CI/CD, Docker, infrastructure |
| document-specialist | Documentation, README, API docs |

## Effort vs Value Matrix

Prioritize tasks using this matrix:

| Effort\Value | High Value | Medium Value | Low Value |
|--------------|------------|--------------|-----------|
| Low Effort | **Do First** | Do Soon | Nice to Have |
| Medium Effort | Do Soon | Evaluate | Skip |
| High Effort | Evaluate | Defer | Skip |

Use labels: effort="S|M|L|XL" value="H|M|L"
</agent_mapping>

<workflows_index>
## Workflows

All in `workflows/`:

| Workflow | Purpose |
|----------|---------|
| create-prp.md | Generate codebase-specific PRP |
| create-prd.md | Generate portable PRD specification |
| prp-from-prd.md | Convert PRD to codebase-specific PRP |
| guidance.md | Help choose between PRP and PRD |
</workflows_index>

<references_index>
## References

All in `references/`:

| Reference | Content |
|-----------|---------|
| prp-best-practices.md | PRP structure, micro-task design, ralph-loop integration |
| prd-best-practices.md | PRD structure, requirements writing, stakeholder communication |
| effort-estimation.md | T-shirt sizing, complexity factors, scope management |
| xml-structure-guide.md | XML tag conventions for machine-readable documents |
</references_index>

<templates_index>
## Templates

All in `templates/`:

| Template | Purpose |
|----------|---------|
| prp-template.md | Full PRP document structure |
| prd-template.md | Full PRD document structure |
| phase-template.md | Single phase with tasks |
| task-template.md | Individual task definition |
</templates_index>

<success_criteria>
A well-crafted PRP:
- Has all tasks assigned to appropriate agents
- Includes effort/value rankings for prioritization
- Contains executable validation commands
- References specific files and patterns from the codebase
- Can be executed by Ralph Loop without clarification

A well-crafted PRD:
- Is understandable without codebase access
- Has measurable acceptance criteria
- Covers edge cases and error scenarios
- Includes data models and API contracts (conceptual)
- Can be handed to any qualified engineer for implementation
</success_criteria>

# Workflow: Create PRP (Product Requirement Prompt)

<objective>
Generate a codebase-specific Product Requirement Prompt (PRP) that can be executed by Ralph Loop or other implementation agents. The PRP will contain micro-tasks with acceptance criteria, agent assignments, and validation commands tailored to the existing codebase.
</objective>

<required_reading>
Before generating, read these references:
- @references/prp-best-practices.md
- @references/effort-estimation.md
- @references/xml-structure-guide.md
</required_reading>

<process>

<step_1_clarify>
**Clarify Requirements**

If the feature description is vague, use AskUserQuestion to gather:
- What specific functionality is needed?
- Who will use this feature?
- What are the must-have vs nice-to-have requirements?
- Are there any constraints (timeline, tech, security)?
- Are there existing designs or mockups?

Document the answers in the PRP context section.
</step_1_clarify>

<step_2_analyze_codebase>
**Analyze Codebase**

Research the existing codebase thoroughly:

```
Glob: Find similar features/implementations
Grep: Search for related code patterns
Read: Examine key files that will be affected
```

Document findings:
- **Existing patterns to follow** (auth, validation, error handling)
- **Files that will be modified** (with specific paths)
- **Files that will be created** (proposed paths following conventions)
- **Dependencies required** (packages, services, env vars)
- **Gotchas and quirks** (library issues, legacy patterns to avoid)

Run `tree` or equivalent to understand project structure:
```bash
find . -type f -name "*.ts" -o -name "*.tsx" -o -name "*.py" | head -50
```
</step_2_analyze_codebase>

<step_3_design_phases>
**Design Implementation Phases**

Break down the feature into logical phases:

1. **Foundation Phase** - Setup, dependencies, schemas
2. **Core Implementation Phase** - Main functionality
3. **Integration Phase** - Connect components, wire up
4. **Validation Phase** - Tests, edge cases, documentation

Each phase should be independently valuable (could be merged if feature is small).

For gargantuan features (10+ major components across 20+ files):
- Consider splitting into multiple PRP documents
- Each PRP should be completable in a focused session
- Create a parent PRP that references child PRPs
</step_3_design_phases>

<step_4_create_tasks>
**Create Micro-Tasks**

For each phase, create granular tasks following this structure:

```xml
<task id="1.1" agent="backend-engineer" effort="M" value="H">
  <description>Clear, actionable description of what to do</description>
  <files>
    <file action="create">src/services/feature-service.ts</file>
    <file action="modify">src/api/routes.ts</file>
  </files>
  <pseudocode>
// Follow pattern from src/services/existing-service.ts
export class FeatureService {
  async create(input: CreateFeatureInput): Promise<Feature> {
    // Validate input (use existing validator pattern)
    // Call repository
    // Return formatted response
  }
}
  </pseudocode>
  <acceptance-criteria>
    <criterion>Service class exists with create, read, update, delete methods</criterion>
    <criterion>All methods have proper TypeScript types</criterion>
    <criterion>Error handling follows project patterns</criterion>
  </acceptance-criteria>
  <handoff>
    <expects>Database schema from task 1.0</expects>
    <produces>Service layer for API integration in task 1.2</produces>
  </handoff>
</task>
```

**Task Guidelines:**
- Each task should be completable in 15-30 minutes of focused work
- Include specific file paths (not placeholders)
- Pseudocode should reference actual patterns from the codebase
- Acceptance criteria must be verifiable (not "works correctly")
- Specify what the task expects and produces for handoff
</step_4_create_tasks>

<step_5_assign_agents>
**Assign Expert Agents**

Match each task to the appropriate agent:

| Agent | Assign When |
|-------|-------------|
| backend-engineer | API endpoints, services, business logic, auth |
| frontend-engineer | Components, hooks, state, styling |
| data-engineer | Schema, migrations, queries, data modeling |
| qa-engineer | Test files, security review, code review |
| devops-engineer | CI/CD, Docker, infrastructure config |
| document-specialist | README, API docs, guides |

If a task spans multiple domains, assign to the primary domain and note collaboration needs.
</step_5_assign_agents>

<step_6_rank_tasks>
**Rank Effort vs Value**

Apply t-shirt sizing:

**Effort:**
- S (Small): < 15 min, single file, clear pattern exists
- M (Medium): 15-30 min, 2-3 files, some decisions needed
- L (Large): 30-60 min, multiple files, new patterns needed
- XL (Extra Large): 1+ hours, significant complexity

**Value:**
- H (High): Core functionality, blocking other work, user-facing
- M (Medium): Important but not blocking, enhances experience
- L (Low): Nice to have, polish, optimization

Priority order: H/S > H/M > M/S > H/L > M/M > L/S > ...
</step_6_rank_tasks>

<step_7_add_validation>
**Add Validation Commands**

Include project-specific validation at multiple levels:

```xml
<validation>
  <level name="syntax" run-after="each-task">
    <command>npm run lint -- --fix</command>
    <command>npm run typecheck</command>
  </level>
  <level name="unit" run-after="phase">
    <command>npm test -- --coverage --passWithNoTests</command>
  </level>
  <level name="integration" run-after="all">
    <command>npm run test:e2e</command>
    <command>npm run build</command>
  </level>
</validation>
```

Adapt commands to the project's actual toolchain (detected in step 2).
</step_7_add_validation>

<step_8_write_document>
**Write PRP Document**

Generate the complete PRP using @templates/prp-template.md structure.

Ensure:
- All sections are filled (no TODOs or placeholders)
- File paths are real and verified
- Pseudocode matches project style
- Validation commands work
- Dependencies are listed with versions
</step_8_write_document>

<step_9_save_and_verify>
**Save and Verify**

```bash
# Create directory if needed
mkdir -p PRPs

# Save document
Write: PRPs/PRP-{feature-name}.md
```

Run a quick verification:
- Count tasks: Should be 5-30 for typical feature
- Check file paths: All referenced files should exist or have clear creation paths
- Validate XML: Structure should parse correctly

Report completion with confidence score.
</step_9_save_and_verify>

</process>

<output_format>
## PRP Created

**Location:** `PRPs/PRP-{feature-name}.md`

**Summary:**
- Phases: X
- Tasks: Y total (Z high-priority)
- Agents: [list of assigned agents]
- Estimated scope: S|M|L|XL

**Confidence Score:** X/10
[Explanation: Why this score? What might need clarification?]

**Execute with:**
```bash
/ralph-loop PRPs/PRP-{feature-name}.md
```

**Or validate first:**
```bash
/prp-validate PRPs/PRP-{feature-name}.md
```
</output_format>

<success_criteria>
- All tasks have agent assignments
- All tasks have effort/value rankings
- All tasks have verifiable acceptance criteria
- Pseudocode references actual codebase patterns
- File paths are specific and accurate
- Validation commands use project's actual tools
- Document can be executed by Ralph Loop without clarification
- Single document (unless feature requires 10+ major components)
</success_criteria>

<anti_patterns>
Avoid these common mistakes:
- Generic pseudocode that doesn't match project style
- Placeholder file paths like "src/feature/index.ts"
- Vague acceptance criteria like "works correctly"
- Missing handoff information between tasks
- Skipping codebase research
- Over-scoping (try to split if >30 tasks)
- Under-scoping (tasks should be atomic, not combined)
</anti_patterns>

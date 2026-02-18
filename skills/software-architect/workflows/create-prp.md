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

<step_2b_research_existing_solutions>
**Research Existing Solutions (Don't Reinvent the Wheel)**

Before designing implementation, search for proven solutions, libraries, and best practices.

<research_triggers>
ALWAYS research when the feature involves:
- **Authentication/Authorization** - OAuth, JWT, session management, RBAC
- **User Management** - registration, profiles, password reset, multi-tenancy
- **Payment Processing** - Stripe, PayPal, billing, subscriptions
- **File Upload/Storage** - S3, Azure Blob, image processing, CDN
- **Email/Notifications** - SMTP, SendGrid, push notifications, webhooks
- **Data Validation** - form validation, schema validation, sanitization
- **API Design** - REST patterns, GraphQL, rate limiting, versioning
- **State Management** - complex UI state, caching, real-time sync
- **Infrastructure** - Azure, AWS, GCP, Docker, Kubernetes
- **Security** - encryption, CSRF, XSS prevention, input sanitization
- **Complex Algorithms** - search, sorting, scheduling, optimization
</research_triggers>

<research_process>
Use WebSearch to find:

1. **Established Libraries** - Don't build what exists
   ```
   WebSearch: "[feature] [framework] library 2025"
   WebSearch: "best [feature] package npm/pypi/nuget"
   ```

2. **Implementation Patterns** - How others solved this
   ```
   WebSearch: "[feature] implementation [framework] tutorial"
   WebSearch: "[feature] best practices [language]"
   ```

3. **Framework-Specific Guidance** - Official docs and recommendations
   ```
   WebSearch: "[framework] official [feature] documentation"
   WebSearch: "[framework] recommended [feature] approach"
   ```

4. **Common Pitfalls** - Learn from others' mistakes
   ```
   WebSearch: "[feature] gotchas [framework]"
   WebSearch: "[library] issues problems"
   ```
</research_process>

<library_evaluation>
When evaluating libraries, check:

| Criteria | What to Look For |
|----------|------------------|
| **Maintenance** | Last commit < 6 months, active issues resolved |
| **Popularity** | NPM weekly downloads, GitHub stars (relative to age) |
| **Documentation** | Clear setup guides, API reference, examples |
| **Type Support** | TypeScript definitions (@types or built-in) |
| **Bundle Size** | Reasonable for the functionality (check bundlephobia) |
| **Security** | No critical vulnerabilities, security-focused if relevant |
| **Compatibility** | Works with project's framework/runtime versions |

Use WebFetch on library documentation when more detail needed:
```
WebFetch: "https://docs.library.io/getting-started" - Extract setup requirements
```
</library_evaluation>

<document_findings>
Document research in the PRP's `<research-findings>` section:

```xml
<research-findings>
  <recommended-libraries>
    <library name="[package-name]" purpose="[what it solves]">
      <rationale>[Why this over alternatives]</rationale>
      <docs-url>[Link to documentation]</docs-url>
      <install>[npm install / pip install command]</install>
    </library>
  </recommended-libraries>

  <patterns-to-follow>
    <pattern source="[URL or reference]">
      <description>[What the pattern solves]</description>
      <applicability>[How it applies to our feature]</applicability>
    </pattern>
  </patterns-to-follow>

  <pitfalls-to-avoid>
    <pitfall source="[URL or reference]">
      <issue>[Common mistake]</issue>
      <mitigation>[How to avoid it]</mitigation>
    </pitfall>
  </pitfalls-to-avoid>

  <documentation-references>
    <reference url="[URL]" topic="[Topic]">
      <key-points>
        <point>[Important detail to remember]</point>
      </key-points>
    </reference>
  </documentation-references>
</research-findings>
```
</document_findings>

<research_examples>
**Example 1: Feature requires authentication**
```
WebSearch: "nextjs 15 authentication library 2025"
→ Find: NextAuth.js (Auth.js), Clerk, Lucia Auth
→ Evaluate: Documentation quality, setup complexity, feature set
→ Recommend: Auth.js for self-hosted, Clerk for managed
```

**Example 2: Feature requires Azure Blob storage**
```
WebSearch: "azure blob storage nodejs sdk best practices"
WebFetch: "https://learn.microsoft.com/azure/storage/blobs/storage-quickstart-blobs-nodejs"
→ Extract: @azure/storage-blob SDK patterns
→ Document: Connection string handling, container creation, SAS tokens
```

**Example 3: Feature requires complex form validation**
```
WebSearch: "react form validation library comparison 2025"
→ Find: React Hook Form, Formik, Zod
→ Evaluate: Bundle size, TypeScript support, learning curve
→ Recommend: React Hook Form + Zod for type-safe validation
```
</research_examples>

<skip_research_when>
Skip extensive research if:
- Feature is purely codebase-specific (refactoring, internal reorganization)
- The project already uses established patterns for this type of feature
- Simple CRUD operations following existing conventions
- Documentation or comment updates

Even then, a quick search (1-2 queries) can surface useful patterns.
</skip_research_when>
</step_2b_research_existing_solutions>

<step_3_design_phases>
**Design Implementation Phases**

Break down the feature into logical phases:

1. **Foundation Phase** - Setup, dependencies, schemas
2. **Core Implementation Phase** - Main functionality
3. **Integration Phase** - Connect components, wire up
4. **Validation Phase** - Tests, edge cases, documentation

Each phase should be independently valuable (could be merged if feature is small).

<prp_sizing_constraints>
**PRP Sizing Constraints (ENFORCED)**

Every PRP must comply with these hard limits:

| Constraint | Limit |
|------------|-------|
| Max tasks (all small effort) | 20 |
| Max tasks (all medium effort) | 15 |
| Max tasks (mixed small + medium) | 15–20 |
| Max lines per PRP file | 2,400 |
| Allowed task effort sizes | S and M only |

**Before writing any PRP, assess the total scope:**
1. Count all tasks needed for the full feature
2. Classify each as S or M (decompose any L/XL into multiple S/M)
3. Estimate line count (~80 lines per S task, ~120 per M task, +200 for metadata)
4. Determine if splitting into multiple PRPs is needed

**If the feature exceeds constraints, split into multiple PRPs:**
- Group by phase boundaries (preferred) or domain boundaries
- Name as `PRP-{feature}-part-1.md`, `PRP-{feature}-part-2.md`, etc.
- Each PRP must be independently executable in sequence
- Earlier PRPs' outputs become later PRPs' prerequisites
</prp_sizing_constraints>
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
- **Task effort MUST be Small (S) or Medium (M) only — L and XL are NOT allowed**
- If a task feels like L or XL, decompose it into 2-3 smaller S/M tasks
- Include specific file paths (not placeholders)
- Pseudocode should reference actual patterns from the codebase
- Acceptance criteria must be verifiable (not "works correctly")
- Specify what the task expects and produces for handoff

**Test Task Special Rules:**
- Any task running tests MUST have `timeout="extended"` attribute
- If project has 50+ test files, split test execution into multiple tasks by module/directory
- Never create a single task that says "run all tests" for large codebases
- E2E and integration tests should always be separate tasks from unit tests

Example test task breakdown:
```xml
<!-- Bad: Single monolithic test task -->
<task id="4.1" agent="qa-engineer" effort="XL" value="H">
  <description>Run all frontend tests</description>
</task>

<!-- Good: Split by test type/module -->
<task id="4.1" agent="qa-engineer" effort="M" value="H" timeout="extended">
  <description>Run unit tests for components (src/components/__tests__)</description>
</task>
<task id="4.2" agent="qa-engineer" effort="M" value="H" timeout="extended">
  <description>Run unit tests for hooks and utilities (src/hooks/__tests__, src/utils/__tests__)</description>
</task>
<task id="4.3" agent="qa-engineer" effort="L" value="H" timeout="extended">
  <description>Run E2E tests (e2e/)</description>
</task>
```
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

**Effort (S and M ONLY in PRPs):**
- S (Small): < 15 min, single file, clear pattern exists
- M (Medium): 15-30 min, 2-3 files, some decisions needed

**L and XL are NOT permitted in PRPs.** If a task estimates as L or XL:
- Decompose into 2-3 S/M subtasks
- If it cannot be decomposed, it may need its own PRP

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
# (or PRP-{feature-name}-part-N.md for multi-PRP features)
```

Run verification for EACH PRP:
- **Task count:** Within limits (max 20 for all-S, max 15 for all-M, 15-20 mixed)
- **Task effort:** All tasks are S or M only — no L or XL
- **Line count:** File does NOT exceed 2,400 lines
- **File paths:** All referenced files should exist or have clear creation paths
- **XML structure:** All tags properly nested and closed

If line count exceeds 2,400, split the PRP into multiple parts.

Report completion with confidence score and sizing summary.
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
/$PLUGIN_NAME:ralph-loop PRPs/PRP-{feature-name}.md
```

**Or validate first:**
```bash
/$PLUGIN_NAME:prp-validate PRPs/PRP-{feature-name}.md
```
</output_format>

<success_criteria>
- **All tasks are S or M effort only — no L or XL tasks in any PRP**
- **Task count within limits per PRP (20 S / 15 M / 15-20 mixed)**
- **No PRP exceeds 2,400 lines**
- **Sizing assessment was performed before generation**
- All tasks have agent assignments
- All tasks have effort/value rankings
- All tasks have verifiable acceptance criteria
- Pseudocode references actual codebase patterns
- File paths are specific and accurate
- Validation commands use project's actual tools
- Document can be executed by Ralph Loop without clarification
- Multi-PRP features have sequential execution order documented
</success_criteria>

<anti_patterns>
Avoid these common mistakes:
- **Cramming too many tasks into a single PRP** — respect the 20/15/15-20 limits
- **Leaving L or XL tasks** — always decompose to S/M
- **Exceeding 2,400 lines** — split into multiple PRPs
- **Skipping the sizing assessment** — it must happen automatically before generation
- Generic pseudocode that doesn't match project style
- Placeholder file paths like "src/feature/index.ts"
- Vague acceptance criteria like "works correctly"
- Missing handoff information between tasks
- Skipping codebase research
- Under-scoping (tasks should be atomic, not combined)
</anti_patterns>

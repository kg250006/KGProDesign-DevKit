# Effort Estimation Guide

<purpose>
Consistent effort estimation for PRP tasks using t-shirt sizing and complexity factors.
</purpose>

<prp_level_constraints>

## PRP-Level Sizing Constraints

Individual task sizing (below) feeds into PRP-level constraints. Every PRP must comply with these hard limits:

| Constraint | Limit | Rationale |
|------------|-------|-----------|
| Max tasks (all S) | 20 | Keeps PRP focused and executable in one session |
| Max tasks (all M) | 15 | Medium tasks need more context per task |
| Max tasks (mixed S+M) | 15–20 | Weighted by complexity ratio |
| Max lines per PRP | 2,400 | Prevents context overload for executing agents |
| Allowed effort sizes | S and M only | L/XL must be decomposed |

### How This Affects Task Design

When creating tasks for a PRP:
1. **Only S and M effort tasks are permitted** — L and XL must be split
2. If a feature requires more tasks than limits allow, create multiple PRPs
3. Account for line count: verbose pseudocode and detailed specs consume lines
4. Estimate ~80 lines per S task, ~120 lines per M task, +200 for PRP metadata

### Multi-PRP Splitting

When a feature exceeds single-PRP constraints:
- Split by phase boundaries (Foundation, Core, Integration, Validation)
- Or split by domain (backend tasks, frontend tasks)
- Name parts sequentially: `PRP-{feature}-part-1.md`, `PRP-{feature}-part-2.md`
- Each PRP must be independently executable in order

</prp_level_constraints>

<sizing_definitions>

## T-Shirt Sizes

### Small (S) - Under 15 minutes

**Characteristics:**
- Single file modification
- Clear pattern exists in codebase
- No architectural decisions
- Minimal testing needed

**Examples:**
- Add a field to an existing type
- Create a simple utility function
- Add a test case to existing test file
- Update configuration value
- Fix a typo or formatting issue

**Validation:**
- Can you describe the change in one sentence?
- Is there existing code to copy from?
- Will it require only one code review comment at most?

### Medium (M) - 15-30 minutes

**Characteristics:**
- 2-3 files affected
- Some decisions within defined constraints
- New tests needed but pattern exists
- May require brief documentation review

**Examples:**
- New API endpoint following existing pattern
- New React component with props
- New database query with existing connection
- Adding validation to existing form
- New test file for a module

**Validation:**
- Can you list all files that need changes?
- Do you understand the pattern to follow?
- Is the scope well-defined?

### Large (L) - 30-60 minutes

**Characteristics:**
- Multiple files across directories
- New patterns or abstractions needed
- Significant testing requirements
- May need to read documentation

**Examples:**
- New service with multiple methods
- Complex UI component with state management
- Database migration with data transformation
- Integration with new external API
- Refactoring shared module

**Validation:**
- Can you break this into smaller tasks?
- What decisions need to be made?
- What could go wrong?

**CRITICAL RULE:** L tasks are a RED FLAG. Before accepting an L task, ask:
1. Can this be split into 2-3 Medium tasks?
2. Is there a simpler approach that would reduce complexity?

Only keep L size if splitting genuinely makes the work harder (e.g., tight coupling requires single-session context).

### Extra Large (XL) - Over 1 hour

**Characteristics:**
- Significant complexity or uncertainty
- Architectural decisions required
- Major impact on existing code
- Extensive testing and validation

**Examples:**
- New subsystem or major feature
- Performance optimization requiring profiling
- Security hardening across application
- Major refactoring effort
- New infrastructure component

**Validation:**
- Should this be multiple PRPs?
- Are requirements fully understood?
- Is stakeholder alignment needed?

**CRITICAL RULE:** XL tasks are NOT ALLOWED in PRPs. You MUST split them.

If a task seems XL, either:
1. Split into multiple L or M tasks
2. Split into a separate PRP (sub-PRP)
3. Re-scope to reduce complexity

Extended timeouts are a LAST RESORT, not a solution for poor task decomposition.

</sizing_definitions>

<complexity_factors>

## Complexity Multipliers

Adjust base estimates based on these factors:

### Increases Complexity (+)

| Factor | Impact | Example |
|--------|--------|---------|
| Unfamiliar codebase | +1 size | New contributor to project |
| No existing pattern | +1 size | First GraphQL endpoint |
| External API integration | +1 size | Third-party payment provider |
| Concurrency concerns | +1 size | Race conditions possible |
| Security-sensitive | +1 size | Auth, PII handling |
| Data migration | +1 size | Live data transformation |
| Cross-team dependency | +1 size | Waiting on other team |

### Decreases Complexity (-)

| Factor | Impact | Example |
|--------|--------|---------|
| Copy-paste from similar | -1 size | Very similar endpoint exists |
| AI-assisted (Claude) | -1 size | Well-specified task |
| Excellent documentation | -1 size | Step-by-step guide exists |
| Hot path (familiar) | -1 size | Daily work area |

### Example Calculation

Base task: "Add new API endpoint" = M (Medium)

Factors:
- Unfamiliar codebase: +1 → L
- Very similar endpoint exists: -1 → M (back to medium)
- External API integration: +1 → L

Final estimate: L (Large)

</complexity_factors>

<value_framework>

## Value Assessment

### High Value (H)

**Criteria:**
- Directly enables core functionality
- Blocks other high-value work
- Addresses critical user pain point
- Fixes security vulnerability
- Prevents data loss or corruption

**Questions to ask:**
- Would users notice if this was missing?
- Does this block the release?
- Is there a workaround without it?

### Medium Value (M)

**Criteria:**
- Improves user experience noticeably
- Enables efficiency gains
- Reduces technical debt meaningfully
- Non-critical bug fixes
- Performance improvements

**Questions to ask:**
- Would users appreciate this?
- Does this make other work easier?
- Is this technical hygiene?

### Low Value (L)

**Criteria:**
- Polish and refinement
- Nice-to-have features
- Minimal user impact
- Code style improvements
- Documentation for obvious code

**Questions to ask:**
- Would anyone miss this?
- Is this over-engineering?
- Can we defer without consequence?

</value_framework>

<prioritization_matrix>

## Priority Matrix

| Effort \ Value | High (H) | Medium (M) | Low (L) |
|----------------|----------|------------|---------|
| **Small (S)** | **DO FIRST** | Do Soon | If Time |
| **Medium (M)** | Do Soon | Evaluate | Defer |
| **Large (L)** | Evaluate | Maybe | Skip |
| **XL** | Split First | Defer | Skip |

### Priority Levels

1. **DO FIRST** (H/S): Quick wins with high impact
2. **Do Soon** (H/M, M/S): Important, schedule soon
3. **Evaluate** (H/L, M/M): Assess ROI carefully
4. **If Time** (L/S): Low-hanging fruit when available
5. **Maybe** (M/L): Nice to have, no commitment
6. **Defer** (XL): Break down or delay
7. **Skip** (L/L, L/M): Don't invest effort

</prioritization_matrix>

<estimation_tips>

## Estimation Best Practices

### 1. Estimate in Batches
Estimate similar tasks together for consistency.

### 2. Include Buffer for Integration
Task estimates are for implementation. Integration/debugging adds time.

### 3. Be Honest About XL
If it's XL, admit it and split. Don't pretend.

### 4. Re-estimate When Stuck
If a Medium task hits 30 minutes without progress, reassess.

### 5. Track Actuals
Compare estimates to actuals to calibrate over time.

### 6. Consider Context Switching
Multiple S tasks may take longer than one M task due to context switches.

</estimation_tips>

<anti_patterns>

## Estimation Anti-Patterns

### 1. Optimism Bias
"This should be easy" → It rarely is.

### 2. Anchor on First Guess
Re-evaluate after learning more about the task.

### 3. Ignoring Dependencies
Task A depends on Task B → estimate A conservatively.

### 4. Planning Fallacy
"It worked fast in another project" → contexts differ.

### 5. Hero Estimates
"I can do this in 10 minutes" → can anyone maintain it?

</anti_patterns>

<test_task_guidance>

## Test Task Special Handling

Test execution tasks require special consideration because they:
- Run external processes (test runners) with variable duration
- Often time out at default 300s timeout
- Scale with codebase size (more tests = longer runtime)

### Rule: Always Use Extended Timeout for Test Tasks

Any task that runs tests should have `timeout="extended"`:

```xml
<task id="4.1" agent="qa-engineer" effort="L" value="H" timeout="extended">
  <description>Run full frontend test suite</description>
  ...
</task>
```

### Rule: Break Down Large Test Suites

If a project has 50+ test files, split into multiple tasks:

**Bad (single task that will timeout):**
```xml
<task id="4.1" agent="qa-engineer" effort="XL" value="H">
  <description>Run all tests for the application</description>
</task>
```

**Good (split by domain/directory):**
```xml
<task id="4.1" agent="qa-engineer" effort="M" value="H" timeout="extended">
  <description>Run authentication module tests (src/auth/__tests__)</description>
</task>
<task id="4.2" agent="qa-engineer" effort="M" value="H" timeout="extended">
  <description>Run user management tests (src/users/__tests__)</description>
</task>
<task id="4.3" agent="qa-engineer" effort="M" value="H" timeout="extended">
  <description>Run API endpoint tests (src/api/__tests__)</description>
</task>
```

### Test Task Splitting Guidelines

| Test Count | Strategy | Tasks |
|------------|----------|-------|
| < 20 tests | Single task | 1 task with extended timeout |
| 20-50 tests | Split by type | Unit tests, Integration tests |
| 50-100 tests | Split by module | Auth, Users, API, etc. |
| 100+ tests | Split by directory | Each major directory gets a task |

### Keywords That Indicate Extended Timeout Needed

When a task description contains these keywords, it needs `timeout="extended"`:

- "run tests", "execute tests", "test suite"
- "npm test", "pytest", "jest", "vitest", "playwright", "cypress"
- "E2E", "end-to-end", "integration test"
- "npm run build", "cargo build", "gradle build"
- "database migration", "seed database"
- "full validation", "complete test run"

</test_task_guidance>

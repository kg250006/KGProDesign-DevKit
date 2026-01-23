# PRP Best Practices

<purpose>
Guidelines for creating high-quality PRPs that execute successfully in Ralph Loop and minimize implementation friction.
</purpose>

<core_principles>

## 1. Context is King

PRPs fail when they assume shared knowledge. Include everything needed:

**Always Include:**
- Exact file paths (not placeholders)
- Pseudocode matching project style
- References to existing patterns ("follow src/services/auth-service.ts")
- Known gotchas and workarounds
- Dependency versions

**Never Assume:**
- How the project is structured
- Which libraries are available
- Coding conventions
- Environment configuration

## 2. Tasks Must Be Atomic

Each task should be:
- Completable in 15-30 minutes
- Independently verifiable
- Single-responsibility

**Good Task:**
```xml
<task id="1.1">
  <description>Create user validation schema</description>
  <files>
    <file action="create">src/schemas/user-schema.ts</file>
  </files>
  <acceptance-criteria>
    <criterion>Schema validates email format</criterion>
    <criterion>Schema enforces password length >= 8</criterion>
    <criterion>TypeScript compiles without errors</criterion>
  </acceptance-criteria>
</task>
```

**Bad Task:**
```xml
<task id="1.1">
  <description>Implement user authentication</description>
  <!-- Too broad, combines multiple concerns -->
</task>
```

## 3. Acceptance Criteria Are Tests

Write criteria as if they're test assertions:

**Good:**
- "UserService.create() returns User object with id populated"
- "Invalid email throws ValidationError with message 'Invalid email format'"
- "npm run typecheck exits with code 0"

**Bad:**
- "Works correctly"
- "Handles errors"
- "Is performant"

## 4. Pseudocode Follows Project Style

Match the existing codebase patterns exactly:

```typescript
// If project uses class-based services:
export class FeatureService {
  constructor(private repo: FeatureRepository) {}
  async create(input: CreateFeatureInput): Promise<Feature> {
    // Match existing validation pattern
    await this.validateInput(input);
    return this.repo.create(input);
  }
}

// If project uses functional style:
export const createFeature = async (
  repo: FeatureRepository,
  input: CreateFeatureInput
): Promise<Feature> => {
  await validateInput(input);
  return repo.create(input);
};
```

## 5. Handoffs Are Explicit

Every task should document what it needs and what it produces:

```xml
<handoff>
  <expects>Database schema from task 1.0</expects>
  <expects>User type from task 1.1</expects>
  <produces>UserService for API integration in task 2.1</produces>
</handoff>
```

This prevents:
- Tasks running out of order
- Missing dependencies
- Integration failures

</core_principles>

<ralph_loop_integration>

## Ralph Loop Compatibility

PRPs are designed for Ralph Loop execution. Ensure:

### 1. XML Structure for Parsing

Ralph Loop parses XML to extract tasks. Use consistent structure:
- `<phases>` contains `<phase>` elements
- `<phase>` contains `<tasks>`
- `<task>` has predictable attributes and children

### 2. Agent Assignments

Each task needs an agent assignment for routing:
```xml
<task id="1.1" agent="backend-engineer">
```

### 3. Validation Commands

Include project-specific commands that Ralph Loop can execute:
```xml
<validation>
  <level name="syntax" run-after="each-task">
    <command>npm run lint</command>
  </level>
</validation>
```

### 4. Completion Signals

Tasks should have clear completion indicators:
- Acceptance criteria that can be verified
- Validation commands that exit cleanly
- File existence checks

</ralph_loop_integration>

<effort_estimation>

## Effort Estimation Guide

### Small (S) - Under 15 minutes
- Single file change
- Clear existing pattern to follow
- No decisions required
- Examples: Add a field, fix a typo, add a test case

### Medium (M) - 15-30 minutes
- 2-3 files affected
- Some decisions within constraints
- Existing similar code to reference
- Examples: New endpoint, new component, new test file

### Large (L) - 30-60 minutes
- Multiple files, possibly new directories
- New patterns or approaches needed
- Some uncertainty in implementation
- Examples: New service with tests, refactor existing module

**WARNING:** L tasks are a red flag. Always ask: "Can I split this into 2-3 Medium tasks?"

### Extra Large (XL) - Over 1 hour
- Significant complexity or scope
- Major new functionality
- **MUST BE SPLIT** - XL tasks are not allowed in PRPs
- Examples: New subsystem, major integration

**CRITICAL RULE:** XL tasks break execution. Split them or create sub-PRPs.

Extended timeouts are a LAST RESORT for unavoidable long-running tasks (like test suites), NOT a workaround for poor task decomposition.

</effort_estimation>

<value_assessment>

## Value Assessment Guide

### High (H)
- Core user-facing functionality
- Blocks other high-value work
- Fixes critical bugs
- Addresses security issues

### Medium (M)
- Improves user experience
- Enables future features
- Non-critical bug fixes
- Performance improvements

### Low (L)
- Polish and refinement
- Nice-to-have features
- Code cleanup (unless blocking)
- Documentation (unless required)

**Prioritization Matrix:**
1. H effort-S value-H → Do first
2. H effort-M value-H → Do soon
3. M effort-S value-M → Do soon
4. L effort-L value-H → Evaluate ROI
5. Others → Defer or skip

</value_assessment>

<common_mistakes>

## Common Mistakes to Avoid

### 1. Vague File Paths
```xml
<!-- Bad -->
<file action="create">src/components/Feature.tsx</file>

<!-- Good -->
<file action="create">src/components/features/UserProfile/UserProfile.tsx</file>
```

### 2. Missing Validation
```xml
<!-- Bad: No way to verify -->
<acceptance-criteria>
  <criterion>Feature works</criterion>
</acceptance-criteria>

<!-- Good: Verifiable -->
<acceptance-criteria>
  <criterion>npm test -- --grep "UserService" passes</criterion>
  <criterion>GET /api/users/123 returns 200 with user object</criterion>
</acceptance-criteria>
```

### 3. Skipping Codebase Research
Always analyze before writing:
- Search for existing patterns
- Read similar implementations
- Note dependencies and imports

### 4. Over-Combining Tasks
If you use "and" in the description, split it:
```xml
<!-- Bad -->
<description>Create service and add tests and update documentation</description>

<!-- Good -->
<task id="1.1"><description>Create user service</description></task>
<task id="1.2"><description>Add unit tests for user service</description></task>
<task id="1.3"><description>Update API documentation</description></task>
```

### 5. Ignoring Handoffs
Every task exists in a chain. Document the dependencies.

### 6. Monolithic Test Tasks

Test execution tasks are the #1 cause of timeout failures. Never create:
```xml
<!-- Bad: Will timeout on any project with 50+ tests -->
<task id="4.1">
  <description>Run all frontend tests</description>
</task>
```

Instead, split by module/type:
```xml
<task id="4.1" timeout="extended">
  <description>Run unit tests for components (src/components/__tests__)</description>
</task>
<task id="4.2" timeout="extended">
  <description>Run unit tests for hooks (src/hooks/__tests__)</description>
</task>
<task id="4.3" timeout="extended">
  <description>Run E2E tests (e2e/)</description>
</task>
```

**Test Task Rules:**
1. Always use `timeout="extended"` for test execution tasks
2. Split by module when project has 50+ test files
3. Keep unit, integration, and E2E tests as separate tasks
4. Each test task should target a specific directory or test pattern

</common_mistakes>

<test_task_guidance>

## Test Task Best Practices

Test execution tasks require special handling because external test runners have unpredictable duration.

### When to Use Extended Timeout

Add `timeout="extended"` attribute to any task that:
- Runs test suites (`npm test`, `pytest`, `jest`)
- Runs E2E tests (`playwright`, `cypress`)
- Runs builds (`npm run build`, `cargo build`)
- Runs database migrations on large datasets
- Executes multiple validation commands

### How to Split Test Tasks

| Project Test Count | Strategy |
|-------------------|----------|
| < 20 tests | Single task with extended timeout |
| 20-50 tests | Split by test type (unit vs integration) |
| 50-100 tests | Split by major module |
| 100+ tests | Split by directory, one task per test directory |

### Example: Large Frontend Project

```xml
<phase id="4" name="Validation">
  <tasks>
    <task id="4.1" agent="qa-engineer" effort="M" value="H" timeout="extended">
      <description>Run component unit tests (src/components/__tests__)</description>
      <acceptance-criteria>
        <criterion>All tests in src/components/__tests__ pass</criterion>
      </acceptance-criteria>
    </task>

    <task id="4.2" agent="qa-engineer" effort="M" value="H" timeout="extended">
      <description>Run hook and utility tests (src/hooks/__tests__, src/utils/__tests__)</description>
      <acceptance-criteria>
        <criterion>All tests in hooks and utils directories pass</criterion>
      </acceptance-criteria>
    </task>

    <task id="4.3" agent="qa-engineer" effort="M" value="H" timeout="extended">
      <description>Run API integration tests (src/api/__tests__)</description>
      <acceptance-criteria>
        <criterion>All API tests pass</criterion>
      </acceptance-criteria>
    </task>

    <task id="4.4" agent="qa-engineer" effort="L" value="H" timeout="extended">
      <description>Run E2E tests (e2e/)</description>
      <acceptance-criteria>
        <criterion>All E2E scenarios pass</criterion>
      </acceptance-criteria>
    </task>
  </tasks>
</phase>
```

</test_task_guidance>

# Fix and Retry Workflow

<overview>
Debug and fix failing tests using the debug-like-expert skill.
Categorize failures, apply fixes, and retry until all pass or marked as blocked.
</overview>

<required_reading>
Before starting, read these references:
1. `references/progress-tracking.md` - Failure logging format
</required_reading>

<failure_categories>
## Failure Categories

| Category | Description | Who Fixes | Retry Limit |
|----------|-------------|-----------|-------------|
| `test-bug` | Test assertion is wrong | Claude/qa-engineer | 3 |
| `frontend-bug` | UI doesn't match expected | Claude/frontend-engineer | 3 |
| `backend-bug` | API/logic error | Claude/backend-engineer | 3 |
| `flaky-test` | Race condition, timing issue | Claude/qa-engineer | 5 |
| `env-issue` | Missing config, env var | Claude/devops-engineer | 2 |
| `data-issue` | Test data problem | Claude/data-engineer | 2 |
| `external-dep` | Third-party service issue | SKIP | 1 |

### Category Detection Heuristics

| Error Pattern | Likely Category |
|---------------|-----------------|
| `Expected X but got Y` | test-bug or frontend-bug |
| `Element not found` | frontend-bug or test-bug |
| `Timeout exceeded` | flaky-test |
| `Connection refused` | env-issue |
| `Cannot find module` | env-issue |
| `401 Unauthorized` | backend-bug or env-issue |
| `500 Internal Server Error` | backend-bug |
| `Snapshot mismatch` | test-bug (intentional change) |
</failure_categories>

<phase_1_parse>
## Phase 1: Parse Failures

### Read Failures from Progress
```bash
# Get failures section
grep -A 100 "## Failures to Fix" .claude/regression-progress.md | grep -E "^\d+\. \*\*"
```

### Parse Each Failure
For each failure line:
```
1. **src/components/Login.test.tsx:45** - Button visibility [frontend-bug]
```

Extract:
- File: `src/components/Login.test.tsx`
- Line: `45`
- Error: `Button visibility`
- Category: `frontend-bug`
- Retry count: Check history

### Create Fix Queue
```markdown
## Fix Queue

| # | File | Line | Error | Category | Retries |
|---|------|------|-------|----------|---------|
| 1 | Login.test.tsx | 45 | Button visibility | frontend-bug | 0 |
| 2 | Auth.test.tsx | 78 | Timeout | flaky-test | 0 |
| 3 | api/users.test.ts | 23 | 401 response | backend-bug | 0 |
```
</phase_1_parse>

<phase_2_investigate>
## Phase 2: Investigate Each Failure

### Read Failing Test
```bash
# Get context around failure line
sed -n '40,60p' src/components/Login.test.tsx
```

### Read Source File
```bash
# Get the component/service being tested
cat src/components/Login.tsx
```

### Invoke debug-like-expert
```
Task: Investigate test failure

**Test File:** src/components/Login.test.tsx:45
**Error:** Expected button to be visible
**Category:** frontend-bug

**Test Code:**
[paste test code]

**Source Code:**
[paste relevant source]

**Question:** Why is this test failing and how do we fix it?
```

### Debug Analysis Output
The debug-like-expert skill will provide:
1. Root cause hypothesis
2. Evidence supporting hypothesis
3. Recommended fix
4. Confidence level
</phase_2_investigate>

<phase_3_fix>
## Phase 3: Apply Fix

### Fix Patterns by Category

**test-bug - Test assertion wrong:**
```typescript
// BEFORE: Wrong expectation
expect(button).toBeVisible();

// AFTER: Correct expectation based on actual behavior
expect(button).toBeInTheDocument();
await waitFor(() => expect(button).toBeVisible());
```

**frontend-bug - Component issue:**
```typescript
// BEFORE: Button missing visibility class
<button className="btn">Submit</button>

// AFTER: Add visibility class
<button className="btn visible">Submit</button>
```

**backend-bug - API logic error:**
```typescript
// BEFORE: Wrong status code
return res.status(200).json({ error: 'Invalid' });

// AFTER: Correct status code
return res.status(400).json({ error: 'Invalid' });
```

**flaky-test - Race condition:**
```typescript
// BEFORE: No wait
const button = screen.getByRole('button');
fireEvent.click(button);
expect(result).toBe('clicked');

// AFTER: Proper async handling
const button = await screen.findByRole('button');
await userEvent.click(button);
await waitFor(() => expect(result).toBe('clicked'));
```

**env-issue - Missing config:**
```bash
# BEFORE: Missing env var
# Tests fail with "DATABASE_URL undefined"

# AFTER: Add to test setup
echo 'DATABASE_URL=postgresql://test:test@localhost:5432/test' >> .env.test
```

**data-issue - Test data problem:**
```typescript
// BEFORE: Hardcoded ID that doesn't exist
const user = await getUser('nonexistent-id');

// AFTER: Create test data first
const testUser = await createTestUser();
const user = await getUser(testUser.id);
```
</phase_3_fix>

<phase_4_retry>
## Phase 4: Retry Test

### Run Specific Test
```bash
# Node/Jest
npm test -- --testPathPattern="Login.test.tsx" --testNamePattern="button visibility"

# Node/Vitest
npx vitest run src/components/Login.test.tsx

# Python
pytest tests/test_login.py::test_button_visibility -v
```

### Evaluate Result

**If PASSES:**
1. Mark as fixed in progress
2. Move to next failure
3. Log action

```bash
# Update progress
echo "- $(date +%H:%M) - FIXED: Login.test.tsx:45 (frontend-bug)" >> .claude/regression-progress.md
```

**If STILL FAILS:**
1. Increment retry count
2. Re-investigate with new hypothesis
3. If retries >= limit: Mark as BLOCKED

```bash
# Update retry count
sed -i '' 's/\[frontend-bug\] (0 retries)/[frontend-bug] (1 retries)/' .claude/regression-progress.md
```
</phase_4_retry>

<phase_5_blocked>
## Phase 5: Handle Blocked Failures

### When to Block
- Retry limit reached
- External dependency issue
- Requires human decision
- Architectural change needed

### Mark as Blocked
```bash
cat >> .claude/regression-progress.md << EOF

## Blocked Failures

1. **src/api/external.test.ts:23**
   - Category: external-dep
   - Reason: Third-party API rate limited
   - Action Required: Mock external API or skip in CI
   - Retries: 1/1

EOF
```

### Blocked Failure Actions
| Category | Recommended Action |
|----------|-------------------|
| external-dep | Add mock, skip in CI |
| env-issue (complex) | Create setup script |
| flaky-test (complex) | Refactor test entirely |
| arch-change | Create follow-up task |
</phase_5_blocked>

<loop_structure>
## Fix Loop Structure

```
For each failure in queue:
    1. Parse failure details
    2. Read test and source files
    3. Invoke debug-like-expert
    4. Apply recommended fix
    5. Retry test
    6. If passes:
         Mark fixed, continue
    7. If fails:
         Increment retry
         If retries >= limit:
             Mark blocked, continue
         Else:
             Re-investigate with new hypothesis
```

### Progress Updates Per Iteration
```bash
# After each attempt
echo "- $(date +%H:%M) - Attempt #$RETRY on $FILE: $RESULT" >> .claude/regression-progress.md
```
</loop_structure>

<final_report>
## Final Fix Report

### Summary
```markdown
## Fix Phase Summary

**Total Failures:** 5
**Fixed:** 3
**Blocked:** 2
**Time Spent:** 15 minutes

### Fixed
1. ✅ Login.test.tsx:45 - Fixed async wait (1 retry)
2. ✅ Auth.test.tsx:78 - Added timeout increase (2 retries)
3. ✅ api/users.test.ts:23 - Fixed mock setup (1 retry)

### Blocked
1. ❌ external.test.ts:23 - External API issue (1/1 retries)
   - Recommendation: Mock external API
2. ❌ integration.test.ts:156 - Architecture issue (3/3 retries)
   - Recommendation: Refactor data layer
```

### Update Progress File
```bash
sed -i '' "s/\[ \] Fix Failures/[x] Fix Failures ($FIXED fixed, $BLOCKED blocked)/" .claude/regression-progress.md
```
</final_report>

<success_criteria>
## Success Criteria

Fix phase is complete when:

1. **All fixable failures fixed** (retries < limit)
2. **Blocked failures documented** with recommended actions
3. **No infinite loops** (retry limits enforced)
4. **Progress file updated** with fix history
5. **All fixes verified** with passing tests

### Exit Conditions
| Condition | Action |
|-----------|--------|
| All fixed | Proceed to report |
| Some blocked | Proceed with blocked documented |
| All blocked | Stop, escalate to user |
</success_criteria>

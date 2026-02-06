# Progress Tracking for Context Recovery

<overview>
Track regression test progress in `.claude/regression-progress.md` to enable:
1. **Context recovery** - Resume after context window resets
2. **Phase tracking** - Know what's done, what's next
3. **Failure logging** - Preserve failure details for fix phase
4. **Action history** - Audit trail of what was done
</overview>

<progress_file_location>
## File Location

**Path:** `.claude/regression-progress.md`

This file lives in the project's `.claude/` directory alongside other Claude state files.

```bash
# Create directory if needed
mkdir -p .claude

# Check for existing progress
cat .claude/regression-progress.md 2>/dev/null || echo "No progress file found"
```
</progress_file_location>

<progress_file_format>
## Progress File Format

```markdown
# Regression Test Progress

## Session Info
- Started: 2025-01-15T10:30:00Z
- Project: my-app
- Mode: full-regression
- Arguments: --frontend --backend
- Platform: node
- Test Runner: vitest
- E2E Runner: playwright

## Completed Phases
- [x] Project Detection
- [x] Coverage Assessment (78%)
- [x] Unit Tests - Backend (32/32 passed)
- [ ] Unit Tests - Frontend
- [ ] Integration Tests
- [ ] E2E Tests
- [ ] Fix Failures
- [ ] Generate Report

## Current Phase
Unit Tests - Frontend

## Last Checkpoint
- Phase: unit-tests
- Area: src/components
- Status: in-progress
- Tests Run: 45/120
- Passed: 43
- Failed: 2
- Timestamp: 2025-01-15T10:50:00Z

## Test Results So Far
| Area | Passed | Failed | Skipped | Time |
|------|--------|--------|---------|------|
| backend/services | 18 | 0 | 0 | 4.2s |
| backend/api | 14 | 0 | 1 | 3.1s |
| frontend/hooks | 12 | 0 | 0 | 2.1s |
| frontend/components | 31 | 2 | 0 | 5.3s |

## Failures to Fix
1. **src/components/Login.test.tsx:45**
   - Error: Expected button to be visible
   - Stack: `at Object.<anonymous> (Login.test.tsx:45:10)`
   - Category: frontend-bug
   - Retries: 0

2. **src/components/Auth.test.tsx:78**
   - Error: Timeout waiting for redirect
   - Stack: `at waitFor (Auth.test.tsx:78:5)`
   - Category: flaky-test
   - Retries: 0

## Actions Log
- 10:30 - Started regression: full mode
- 10:31 - Detected: vitest + playwright setup
- 10:32 - Coverage: 78% (above threshold)
- 10:35 - Backend unit tests: 32/32 passed (4.2s)
- 10:40 - Frontend hooks: 12/12 passed (2.1s)
- 10:45 - Frontend components: started
- 10:50 - Frontend components: 2 failures detected

## Coverage Summary
- Lines: 78.3%
- Branches: 72.1%
- Functions: 81.5%
- Statements: 77.9%

## Environment
- Node: v20.11.0
- npm: 10.2.4
- OS: darwin
```
</progress_file_format>

<recovery_process>
## Context Recovery Process

When context resets (compaction, new session, etc.):

### Step 1: Check for Progress File
```bash
if [ -f ".claude/regression-progress.md" ]; then
    echo "Progress file found - checking for resume point"
    cat .claude/regression-progress.md
else
    echo "No progress file - starting fresh"
fi
```

### Step 2: Parse Resume Point
```bash
# Get current phase
grep "^## Current Phase" .claude/regression-progress.md -A 1 | tail -1

# Get completed phases
grep "^\- \[x\]" .claude/regression-progress.md

# Get pending failures
grep -A 100 "^## Failures to Fix" .claude/regression-progress.md | head -50
```

### Step 3: Resume from Checkpoint
1. Read "Current Phase" to know where we are
2. Read "Completed Phases" to skip finished work
3. Read "Failures to Fix" to know what needs fixing
4. Continue from checkpoint, don't repeat completed work

### Step 4: Update Progress After Each Action
```bash
# After completing a phase, mark it done
sed -i 's/\[ \] Unit Tests - Frontend/[x] Unit Tests - Frontend (45\/45 passed)/g' .claude/regression-progress.md
```
</recovery_process>

<writing_progress>
## Writing Progress Updates

### Initialize New Session
```markdown
# Append to start of session
echo "## Session Info
- Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Project: $(basename $(pwd))
- Mode: $MODE
- Arguments: $ARGUMENTS" > .claude/regression-progress.md
```

### Mark Phase Complete
```bash
# Replace [ ] with [x] and add results
# Example: Mark backend unit tests complete
sed -i 's/\[ \] Unit Tests - Backend/[x] Unit Tests - Backend (50\/50 passed)/g' .claude/regression-progress.md
```

### Log Test Results
```bash
# Append to results table
echo "| $AREA | $PASSED | $FAILED | $SKIPPED | ${TIME}s |" >> .claude/regression-progress.md
```

### Log Failure
```bash
# Append to failures section
cat >> .claude/regression-progress.md << EOF

$INDEX. **$FILE:$LINE**
   - Error: $ERROR_MESSAGE
   - Category: $CATEGORY
   - Retries: 0
EOF
```

### Log Action
```bash
# Append to actions log
echo "- $(date +%H:%M) - $ACTION" >> .claude/regression-progress.md
```
</writing_progress>

<critical_rules>
## Critical Rules for Progress Tracking

### 1. ALWAYS Read Progress First
On every skill invocation, check for existing progress:
```bash
[ -f ".claude/regression-progress.md" ] && cat .claude/regression-progress.md
```

### 2. NEVER Repeat Completed Phases
Phases marked `[x]` are DONE. Skip them:
```bash
# Check if phase is done
grep -q "\[x\] Unit Tests - Backend" .claude/regression-progress.md && echo "SKIP: Already done"
```

### 3. UPDATE After Every Major Operation
Don't batch updates. Write progress immediately after:
- Completing a test suite
- Finding a failure
- Fixing a test
- Any significant action

### 4. PRESERVE Failure Details
Failures need full context for fix phase:
- Exact file and line
- Full error message
- Stack trace if available
- Failure category (test bug, code bug, flaky, env)

### 5. VERIFY Before Marking Complete
A phase is only complete when:
- All tests in that phase have run
- Results are logged
- Failures are categorized
- Progress file is updated
</critical_rules>

<failure_categories>
## Failure Categories

When logging failures, categorize them for the fix phase:

| Category | Description | Who Fixes |
|----------|-------------|-----------|
| `test-bug` | Test assertion is wrong | qa-engineer |
| `frontend-bug` | UI doesn't match expected | frontend-engineer |
| `backend-bug` | API/logic error | backend-engineer |
| `flaky-test` | Race condition, timing | qa-engineer |
| `env-issue` | Missing config, env var | devops-engineer |
| `data-issue` | Test data problem | data-engineer |

Example:
```markdown
1. **src/api/auth.test.ts:42**
   - Error: Expected 200, got 401
   - Category: backend-bug
   - Notes: Auth middleware rejecting valid token
```
</failure_categories>

<progress_file_examples>
## Progress File Examples

### Fresh Start
```markdown
# Regression Test Progress

## Session Info
- Started: 2025-01-15T10:30:00Z
- Project: my-app
- Mode: full-regression

## Completed Phases
- [ ] Project Detection
- [ ] Coverage Assessment
- [ ] Unit Tests - Backend
- [ ] Unit Tests - Frontend
- [ ] Integration Tests
- [ ] E2E Tests

## Current Phase
Project Detection
```

### Mid-Run (Resumable)
```markdown
## Completed Phases
- [x] Project Detection
- [x] Coverage Assessment (78%)
- [x] Unit Tests - Backend (50/50)
- [ ] Unit Tests - Frontend
- [ ] Integration Tests
- [ ] E2E Tests

## Current Phase
Unit Tests - Frontend

## Last Checkpoint
- Area: src/components
- Tests Run: 30/80
- Status: in-progress
```

### With Failures
```markdown
## Completed Phases
- [x] Project Detection
- [x] Coverage Assessment (78%)
- [x] Unit Tests - Backend (50/50)
- [x] Unit Tests - Frontend (78/80 - 2 FAILED)
- [x] Integration Tests (20/20)
- [ ] E2E Tests
- [ ] Fix Failures

## Failures to Fix
1. **Login.test.tsx:45** - Button visibility [frontend-bug]
2. **Auth.test.tsx:78** - Timeout [flaky-test]
```

### Completed Run
```markdown
## Completed Phases
- [x] Project Detection
- [x] Coverage Assessment (78%)
- [x] Unit Tests - Backend (50/50)
- [x] Unit Tests - Frontend (80/80)
- [x] Integration Tests (20/20)
- [x] E2E Tests (10/10)
- [x] Fix Failures (2 fixed)
- [x] Generate Report

## Final Status: PASSED

## Report Location
.claude/regression-report-2025-01-15.md
```
</progress_file_examples>

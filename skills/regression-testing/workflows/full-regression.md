# Full Regression Workflow

<overview>
Complete regression testing across all project areas: backend, frontend, integration, and E2E.
Designed for headless execution with progress tracking for context recovery.
</overview>

<required_reading>
Before starting, read these references:
1. `references/project-detection.md` - Detect project type
2. `references/test-frameworks.md` - Framework-specific commands
3. `references/progress-tracking.md` - Progress file format
</required_reading>

<pre_flight>
## Pre-Flight Checks

### 1. Check for Existing Progress
```bash
if [ -f ".claude/regression-progress.md" ]; then
    echo "EXISTING_PROGRESS: true"
    cat .claude/regression-progress.md
else
    echo "EXISTING_PROGRESS: false"
fi
```

If progress exists and user didn't specify `--resume`:
- Ask: "Found existing progress. Resume from checkpoint or start fresh?"
- Resume: Skip completed phases
- Fresh: Archive old progress, start new

### 2. Run Project Detection
```bash
bash scripts/detect-project.sh
```

Store detection results for later phases.

### 3. Check Coverage Threshold
If coverage < 60%:
- WARN: "Coverage is X%. Recommend running --coverage first."
- If below 30%: BLOCK until coverage improved

### 4. Initialize Progress File
```bash
mkdir -p .claude
cat > .claude/regression-progress.md << 'EOF'
# Regression Test Progress

## Session Info
- Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Project: $(basename $(pwd))
- Mode: full-regression
- Platform: [detected]
- Test Runner: [detected]
- E2E Runner: [detected]

## Completed Phases
- [ ] Project Detection
- [ ] Coverage Assessment
- [ ] Unit Tests - Backend
- [ ] Unit Tests - Frontend
- [ ] Integration Tests
- [ ] E2E Tests
- [ ] Fix Failures
- [ ] Generate Report

## Current Phase
Project Detection

## Failures to Fix
(none yet)

## Actions Log
- [timestamp] - Started full regression
EOF
```
</pre_flight>

<phase_1_detection>
## Phase 1: Project Detection

**Objective:** Identify project type, test infrastructure, and current state.

### Steps

1. **Run detection script**
   ```bash
   bash scripts/detect-project.sh > .claude/detection-output.txt
   cat .claude/detection-output.txt
   ```

2. **Parse detection results**
   Extract:
   - PLATFORM (node, python, rust, go, java)
   - TEST_RUNNER (jest, vitest, pytest, cargo, go_test)
   - E2E_RUNNER (playwright, cypress, none)
   - PACKAGE_MANAGER (npm, pnpm, yarn, pip, poetry)

3. **Validate test infrastructure exists**
   - If TEST_RUNNER is `none_detected`: WARN and ask to set up tests first
   - If no test files found: BLOCK, cannot run regression

4. **Update progress**
   ```bash
   sed -i '' 's/\[ \] Project Detection/[x] Project Detection/' .claude/regression-progress.md
   echo "- $(date +%H:%M) - Detection complete: [platform] + [runner]" >> .claude/regression-progress.md
   ```

### Decision Points
| Detection Result | Action |
|------------------|--------|
| No package.json/pyproject.toml | BLOCK: Unknown project type |
| Test runner found | CONTINUE to Phase 2 |
| No test files | WARN: Setup tests first |
</phase_1_detection>

<phase_2_coverage>
## Phase 2: Coverage Assessment

**Objective:** Measure current coverage to decide if enhancement needed.

### Steps

1. **Run coverage command** (framework-specific)

   **Node/Jest:**
   ```bash
   npm test -- --coverage --coverageReporters=json-summary --passWithNoTests
   ```

   **Node/Vitest:**
   ```bash
   npx vitest run --coverage --coverage.reporter=json-summary
   ```

   **Python/pytest:**
   ```bash
   pytest --cov=src --cov-report=json
   ```

2. **Parse coverage percentage**
   ```bash
   # Node
   cat coverage/coverage-summary.json | jq '.total.lines.pct'

   # Python
   cat coverage.json | jq '.totals.percent_covered'
   ```

3. **Evaluate against thresholds**
   | Coverage | Action |
   |----------|--------|
   | < 30% | CRITICAL: Only test critical paths |
   | 30-60% | WARN: Recommend --coverage enhancement |
   | 60-80% | ACCEPTABLE: Proceed normally |
   | > 80% | GOOD: Full regression |

4. **Update progress**
   ```bash
   sed -i '' "s/\[ \] Coverage Assessment/[x] Coverage Assessment ($COVERAGE%)/" .claude/regression-progress.md
   ```

### Coverage Details to Record
```markdown
## Coverage Summary
- Lines: X%
- Branches: Y%
- Functions: Z%
- Statements: W%
```
</phase_2_coverage>

<phase_3_unit_tests>
## Phase 3: Unit Tests

**Objective:** Run all unit tests, categorized by area.

### Backend Tests

1. **Identify backend test files**
   ```bash
   # Node
   find . -path "*/server/*" -name "*.test.ts" -o -path "*/api/*" -name "*.test.ts" -o -path "*/services/*" -name "*.test.ts"

   # Python
   find . -path "*/api/*" -name "test_*.py" -o -path "*/services/*" -name "test_*.py"
   ```

2. **Run backend tests**
   ```bash
   # Node/Jest
   npm test -- --testPathPattern="(server|api|services)" --passWithNoTests

   # Node/Vitest
   npx vitest run --testNamePattern="(server|api|services)"

   # Python
   pytest tests/api tests/services -v
   ```

3. **Record results**
   - Count passed, failed, skipped
   - Log failures with file:line for fix phase
   - Update progress file

### Frontend Tests

1. **Identify frontend test files**
   ```bash
   find . -path "*/components/*" -name "*.test.tsx" -o -path "*/hooks/*" -name "*.test.ts" -o -path "*/pages/*" -name "*.test.tsx"
   ```

2. **Run frontend tests**
   ```bash
   # Node/Jest
   npm test -- --testPathPattern="(components|hooks|pages|ui)" --passWithNoTests

   # Node/Vitest
   npx vitest run --testNamePattern="(components|hooks|pages|ui)"
   ```

3. **Record results**
   - Same pattern as backend

### Update Progress After Each Area
```bash
# Mark complete with results
sed -i '' "s/\[ \] Unit Tests - Backend/[x] Unit Tests - Backend ($PASSED\/$TOTAL passed)/" .claude/regression-progress.md

# Log action
echo "- $(date +%H:%M) - Backend tests: $PASSED/$TOTAL passed" >> .claude/regression-progress.md

# Log failures
for failure in failures:
    echo "$INDEX. **$FILE:$LINE** - $ERROR [$CATEGORY]" >> .claude/regression-progress.md
```
</phase_3_unit_tests>

<phase_4_integration>
## Phase 4: Integration Tests

**Objective:** Test component interactions and API integrations.

### Steps

1. **Identify integration tests**
   ```bash
   find . -name "*.integration.test.ts" -o -path "*/integration/*" -name "*.test.ts"
   ```

2. **Start required services** (if needed)
   ```bash
   # Check for docker-compose
   if [ -f "docker-compose.yml" ]; then
       docker-compose up -d
       sleep 5  # Wait for services
   fi
   ```

3. **Run integration tests**
   ```bash
   npm test -- --testPathPattern="integration" --passWithNoTests
   ```

4. **Cleanup**
   ```bash
   docker-compose down 2>/dev/null || true
   ```

5. **Update progress**
   ```bash
   sed -i '' "s/\[ \] Integration Tests/[x] Integration Tests ($PASSED\/$TOTAL passed)/" .claude/regression-progress.md
   ```
</phase_4_integration>

<phase_5_e2e>
## Phase 5: E2E Tests

**Objective:** Run end-to-end tests in headless mode.

### Pre-requisites
- E2E runner detected (playwright or cypress)
- Dev server running OR build available

### Steps

1. **Start dev server** (if needed)
   ```bash
   # Start in background
   npm run dev &
   DEV_PID=$!
   sleep 10  # Wait for server
   ```

2. **Run E2E tests**

   **Playwright:**
   ```bash
   npx playwright test --reporter=list
   ```

   **Cypress:**
   ```bash
   npx cypress run --headless
   ```

3. **Capture screenshots on failure**
   - Playwright: Auto-saves to test-results/
   - Cypress: Auto-saves to cypress/screenshots/

4. **Stop dev server**
   ```bash
   kill $DEV_PID 2>/dev/null || true
   ```

5. **Update progress**
   ```bash
   sed -i '' "s/\[ \] E2E Tests/[x] E2E Tests ($PASSED\/$TOTAL passed)/" .claude/regression-progress.md
   ```

### Visual Testing Integration
If UI changes detected or visual tests exist:
```
Invoke skill: ui-visual-testing
Mode: regression-comparison
```
</phase_5_e2e>

<phase_6_fix>
## Phase 6: Fix Failures

**Objective:** Debug and fix test failures using debug-like-expert skill.

### Pre-condition
Only enter this phase if failures exist in progress file.

### Steps

1. **Read failures from progress file**
   ```bash
   grep -A 5 "## Failures to Fix" .claude/regression-progress.md
   ```

2. **For each failure:**
   a. **Categorize the failure**
      | Category | Description | Approach |
      |----------|-------------|----------|
      | test-bug | Test assertion wrong | Fix test |
      | frontend-bug | UI doesn't match | Fix component |
      | backend-bug | API/logic error | Fix service |
      | flaky-test | Race condition | Add wait/retry |
      | env-issue | Missing config | Fix setup |

   b. **Invoke debug-like-expert**
      ```
      Task: Investigate and fix test failure
      File: [failure file]
      Error: [error message]
      ```

   c. **Apply fix**

   d. **Re-run specific test**
      ```bash
      npm test -- --testPathPattern="[specific-file]"
      ```

   e. **If passes, mark fixed in progress**

   f. **If still fails, increment retry count**
      - Max 3 retries per failure
      - After 3: Mark as BLOCKED, continue to next

3. **Update progress**
   ```bash
   sed -i '' "s/\[ \] Fix Failures/[x] Fix Failures ($FIXED fixed, $BLOCKED blocked)/" .claude/regression-progress.md
   ```
</phase_6_fix>

<phase_7_report>
## Phase 7: Generate Report

**Objective:** Create comprehensive regression test report.

### Steps

1. **Read template**
   ```bash
   cat templates/regression-report.md
   ```

2. **Populate with results**
   - Session info from progress file
   - Test results per area
   - Coverage summary
   - Failures fixed/blocked
   - Recommendations

3. **Save report**
   ```bash
   cp populated-report.md .claude/regression-report-$(date +%Y-%m-%d).md
   ```

4. **Final progress update**
   ```bash
   sed -i '' "s/\[ \] Generate Report/[x] Generate Report/" .claude/regression-progress.md
   echo "" >> .claude/regression-progress.md
   echo "## Final Status: COMPLETED" >> .claude/regression-progress.md
   echo "## Report Location" >> .claude/regression-progress.md
   echo ".claude/regression-report-$(date +%Y-%m-%d).md" >> .claude/regression-progress.md
   ```

5. **Output summary to user**
   ```
   ========================================
   REGRESSION TEST COMPLETE
   ========================================
   Total Tests: X
   Passed: Y
   Failed: Z (W fixed, V blocked)
   Coverage: N%

   Report: .claude/regression-report-YYYY-MM-DD.md
   ========================================
   ```
</phase_7_report>

<error_handling>
## Error Handling

### Test Command Fails
```bash
# Capture exit code
npm test -- ... || TEST_EXIT=$?

if [ $TEST_EXIT -ne 0 ]; then
    echo "Tests exited with code $TEST_EXIT"
    # Parse output for failures
    # Continue to fix phase
fi
```

### Server Won't Start
```bash
# Check if port in use
lsof -i :3000 && echo "Port 3000 in use"

# Try alternative port
PORT=3001 npm run dev &
```

### Out of Memory
```bash
# For large test suites
NODE_OPTIONS="--max-old-space-size=4096" npm test
```

### Timeout
```bash
# Increase test timeout
npm test -- --testTimeout=30000
```
</error_handling>

<success_criteria>
## Success Criteria

Full regression is complete when:

1. **All phases executed** (or skipped with reason)
2. **Progress file updated** with final status
3. **Report generated** with actionable items
4. **No blocking failures** (all fixed or documented)
5. **Coverage maintained** or improved

### Exit Codes
| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | Some tests failed (logged) |
| 2 | Blocking issue (cannot continue) |
</success_criteria>

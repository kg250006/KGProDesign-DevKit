---
name: regression-testing
description: Comprehensive regression testing skill for any platform. Detects project type, assesses coverage, runs tests, fixes failures, generates reports. Designed for headless automated execution with progress tracking for context recovery.
---

<essential_principles>
## Automated Testing Philosophy

This skill is designed for **headless, unattended execution**. All decisions are automated - no human intervention required.

### 1. Detect, Don't Assume

Never assume project type or test infrastructure. Run detection first:
- Check package.json, pyproject.toml, Cargo.toml, go.mod
- Identify test runners (Jest, Vitest, pytest, cargo test)
- Find existing test files and patterns

### 2. Coverage Before Testing

If test coverage < 60%, enhance coverage BEFORE running regression:
- Identify untested critical paths
- Generate tests following project patterns
- Verify new tests pass
- Then proceed with regression

### 3. Fix and Retry

When tests fail:
- Don't stop - log failures and continue
- After all tests, route to fix workflow
- Use debug-like-expert for root cause analysis
- Re-run failed tests after fixes
- Max 3 retries per failure before marking BLOCKED

### 4. Progress Tracking

Context windows can reset during long test runs. Track state in `.claude/regression-progress.md`:
- Completed phases marked [x]
- Current phase always known
- Failures logged for fix phase
- Recovery reads progress file first

### 5. Use Existing Skills

Don't reinvent specialized testing:
- **debug-like-expert**: For fixing failing tests
- **ui-visual-testing**: For frontend visual regression
- **qa-engineer agent**: For test strategy guidance

## Testing Priority Order

Execute in this order for fastest feedback:
1. **Unit tests** - Fast, isolated, granular
2. **Integration tests** - Service interactions
3. **E2E tests** - Complete user flows
4. **Visual regression** - UI comparison

## Headless Execution Rules

**CRITICAL**: This skill must work without user interaction.

1. **No AskUserQuestion** - All decisions automated
2. **Reasonable defaults** - When in doubt, test more
3. **Log everything** - Progress file is the record
4. **Fail gracefully** - Record failure, continue testing
5. **Retry limits** - Don't loop forever on failures
</essential_principles>

<context_scan>
**Run on every invocation to detect project type:**

```bash
# Project type detection
echo "=== PROJECT DETECTION ==="

# JavaScript/TypeScript
if [ -f "package.json" ]; then
    echo "PLATFORM: node"

    # Test runner
    [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] && echo "TEST_RUNNER: jest"
    [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] && echo "TEST_RUNNER: vitest"

    # E2E runner
    [ -f "playwright.config.ts" ] && echo "E2E_RUNNER: playwright"
    [ -f "cypress.config.ts" ] && echo "E2E_RUNNER: cypress"

    # Framework
    grep -q '"next"' package.json 2>/dev/null && echo "FRAMEWORK: nextjs"
    grep -q '"react"' package.json 2>/dev/null && echo "FRAMEWORK: react"
fi

# Python
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    echo "PLATFORM: python"

    [ -f "pytest.ini" ] || [ -f "conftest.py" ] && echo "TEST_RUNNER: pytest"

    grep -q "django" pyproject.toml requirements*.txt 2>/dev/null && echo "FRAMEWORK: django"
    grep -q "fastapi" pyproject.toml requirements*.txt 2>/dev/null && echo "FRAMEWORK: fastapi"
fi

# Rust
[ -f "Cargo.toml" ] && echo "PLATFORM: rust" && echo "TEST_RUNNER: cargo"

# Go
[ -f "go.mod" ] && echo "PLATFORM: go" && echo "TEST_RUNNER: go_test"

# Check for existing progress
if [ -f ".claude/regression-progress.md" ]; then
    echo "=== EXISTING PROGRESS FOUND ==="
    echo "Resume from checkpoint available"
fi
```

**Present findings before proceeding.**
</context_scan>

<intake>
**Parse arguments or default to full regression:**

Arguments:
- No args → Full regression (all tests)
- `--frontend` → Frontend tests only
- `--backend` → Backend tests only
- `--coverage` → Coverage assessment and enhancement
- `--fix` → Fix failing tests from previous run
- `--resume` → Resume from progress file
- Keywords → Filter tests matching keywords

**If progress file exists and not `--resume`:**
Ask: "Previous progress found. Resume from checkpoint or start fresh?"

**Otherwise, route based on arguments.**
</intake>

<routing>
## Route to Workflow

| Input | Workflow |
|-------|----------|
| No args, "all", "full" | `workflows/full-regression.md` |
| `--frontend`, "ui", "react", "frontend" | `workflows/frontend-only.md` |
| `--backend`, "api", "backend", "server" | `workflows/backend-only.md` |
| `--coverage`, "enhance", "coverage" | `workflows/coverage-enhancement.md` |
| `--fix`, "repair", "fix" | `workflows/fix-and-retry.md` |
| `--resume` | Read progress file, resume from checkpoint |

**After reading the workflow, follow it exactly.**
</routing>

<progress_file_format>
## Progress File Structure

Location: `.claude/regression-progress.md`

```markdown
# Regression Test Progress

## Session Info
- Started: [timestamp]
- Project: [name]
- Mode: [full|frontend|backend|coverage]
- Arguments: [args]

## Completed Phases
- [x] Project Detection
- [x] Coverage Assessment
- [ ] Unit Tests - Backend
- [ ] Unit Tests - Frontend
- [ ] Integration Tests
- [ ] E2E Tests

## Current Phase
[phase name]

## Test Results
| Area | Passed | Failed | Skipped |
|------|--------|--------|---------|

## Failures to Fix
1. file:line - error message

## Actions Log
- [timestamp] - action taken
```
</progress_file_format>

<quick_reference>
## Test Commands Quick Reference

**JavaScript/TypeScript:**
```bash
# Jest
npm test -- --coverage --passWithNoTests
npm test -- --testPathPattern="auth"

# Vitest
npx vitest run --coverage
npx vitest run src/components

# Playwright
npx playwright test --headed=false
```

**Python:**
```bash
# pytest
pytest --cov=src --cov-report=term-missing
pytest tests/unit/ -v --tb=short
pytest -x  # Stop on first failure

# Django
python manage.py test
coverage run manage.py test && coverage report
```

**Coverage Thresholds:**
| Level | Percentage | Action |
|-------|------------|--------|
| Critical | < 30% | Warn, enhance critical paths |
| Low | 30-60% | Enhance before regression |
| Acceptable | 60-80% | Suggest enhancement after |
| Good | 80-100% | Proceed with regression |
</quick_reference>

<reference_index>
## Domain Knowledge

All in `references/`:

**Detection:** project-detection.md - How to detect project type and test infrastructure
**Frameworks:** test-frameworks.md - Framework-specific test commands and coverage
**Progress:** progress-tracking.md - Context recovery and checkpoint management
</reference_index>

<workflows_index>
## Workflows

All in `workflows/`:

| Workflow | Purpose |
|----------|---------|
| full-regression.md | Complete regression across all test types |
| frontend-only.md | Frontend/UI focused testing |
| backend-only.md | API/service focused testing |
| coverage-enhancement.md | Assess and improve test coverage |
| fix-and-retry.md | Debug and fix failing tests |
</workflows_index>

<templates_index>
## Templates

All in `templates/`:

| Template | Purpose |
|----------|---------|
| regression-report.md | Summary report format |
</templates_index>

<scripts_index>
## Scripts

All in `scripts/`:

| Script | Purpose |
|--------|---------|
| detect-project.sh | Automated project type detection |
</scripts_index>

<skill_integration>
## Skill Integration

This skill integrates with:

### debug-like-expert
- **When**: Fixing failing tests
- **How**: Load for root cause analysis of test failures
- **Purpose**: Methodical investigation, not quick fixes

### ui-visual-testing
- **When**: Frontend visual regression
- **How**: Invoke for screenshot comparison, DOM inspection
- **Purpose**: Catch visual regressions the tests miss

### qa-engineer agent
- **When**: Complex test strategy decisions
- **How**: Task agent for test coverage planning
- **Purpose**: Expert guidance on what to test
</skill_integration>

<success_criteria>
A successful regression run:
- [ ] Project type detected correctly
- [ ] Coverage assessed (if applicable)
- [ ] All test suites executed
- [ ] Failures logged with details
- [ ] Fixes applied (if fix mode)
- [ ] Report generated
- [ ] Progress file updated
- [ ] No unanswered questions (headless mode)
</success_criteria>

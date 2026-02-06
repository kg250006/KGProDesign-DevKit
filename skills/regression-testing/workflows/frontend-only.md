# Frontend-Only Workflow

<overview>
Run frontend-focused regression tests including UI components, hooks, pages, and visual testing.
Skips backend, API, and server-side tests.
</overview>

<required_reading>
Before starting, read these references:
1. `references/project-detection.md` - Detect frontend framework
2. `references/test-frameworks.md` - Jest/Vitest/Playwright commands
3. `references/progress-tracking.md` - Progress file format
</required_reading>

<scope>
## Test Scope

### Included
- `components/**/*.test.{ts,tsx}`
- `hooks/**/*.test.ts`
- `pages/**/*.test.{ts,tsx}`
- `ui/**/*.test.{ts,tsx}`
- `app/**/*.test.{ts,tsx}` (Next.js App Router)
- `e2e/**/*.spec.ts` (UI-focused E2E)
- Visual regression tests

### Excluded
- `server/**/*`
- `api/**/*` (except frontend API clients)
- `services/**/*` (backend services)
- `lib/server/**/*`
- Integration tests with external services
</scope>

<pre_flight>
## Pre-Flight Checks

### 1. Detect Frontend Framework
```bash
# Check package.json for framework
if grep -q '"react"' package.json 2>/dev/null; then
    FRAMEWORK="react"
elif grep -q '"vue"' package.json 2>/dev/null; then
    FRAMEWORK="vue"
elif grep -q '"svelte"' package.json 2>/dev/null; then
    FRAMEWORK="svelte"
elif grep -q '"@angular/core"' package.json 2>/dev/null; then
    FRAMEWORK="angular"
fi

# Check for meta-framework
if grep -q '"next"' package.json 2>/dev/null; then
    FRAMEWORK="nextjs"
fi
```

### 2. Detect Test Runner
```bash
if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
    TEST_RUNNER="jest"
elif [ -f "vitest.config.ts" ]; then
    TEST_RUNNER="vitest"
fi
```

### 3. Initialize Progress
```bash
mkdir -p .claude
cat > .claude/regression-progress.md << 'EOF'
# Regression Test Progress

## Session Info
- Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Project: $(basename $(pwd))
- Mode: frontend-only
- Framework: [FRAMEWORK]
- Test Runner: [TEST_RUNNER]

## Completed Phases
- [ ] Project Detection
- [ ] Coverage Assessment
- [ ] Component Tests
- [ ] Hook Tests
- [ ] Page Tests
- [ ] Visual Tests
- [ ] E2E Tests (UI)
- [ ] Fix Failures
- [ ] Generate Report

## Current Phase
Project Detection

## Failures to Fix
(none yet)

## Actions Log
- [timestamp] - Started frontend regression
EOF
```
</pre_flight>

<phase_1_components>
## Phase 1: Component Tests

**Objective:** Test all UI components in isolation.

### Find Component Tests
```bash
find . -path "*/components/*" -name "*.test.tsx" -o -path "*/ui/*" -name "*.test.tsx" 2>/dev/null | head -50
```

### Run Tests

**Jest:**
```bash
npm test -- --testPathPattern="components|ui" --passWithNoTests --coverage
```

**Vitest:**
```bash
npx vitest run components ui --coverage
```

### Common Component Test Issues

| Issue | Fix |
|-------|-----|
| Missing providers | Wrap with test providers |
| Async state not ready | Use `waitFor` |
| Missing mocks | Mock external dependencies |
| Snapshot mismatch | Review changes, update if intentional |

### Update Progress
```bash
sed -i '' "s/\[ \] Component Tests/[x] Component Tests ($PASSED\/$TOTAL)/" .claude/regression-progress.md
```
</phase_1_components>

<phase_2_hooks>
## Phase 2: Hook Tests

**Objective:** Test custom React/Vue hooks.

### Find Hook Tests
```bash
find . -path "*/hooks/*" -name "*.test.ts" 2>/dev/null
```

### Run Tests

**Jest:**
```bash
npm test -- --testPathPattern="hooks" --passWithNoTests
```

**Vitest:**
```bash
npx vitest run hooks
```

### Hook Testing Patterns

```typescript
// Testing async hooks
import { renderHook, waitFor } from '@testing-library/react';

test('useData fetches correctly', async () => {
  const { result } = renderHook(() => useData());

  await waitFor(() => {
    expect(result.current.data).toBeDefined();
  });
});
```

### Update Progress
```bash
sed -i '' "s/\[ \] Hook Tests/[x] Hook Tests ($PASSED\/$TOTAL)/" .claude/regression-progress.md
```
</phase_2_hooks>

<phase_3_pages>
## Phase 3: Page Tests

**Objective:** Test page-level components and routing.

### Find Page Tests
```bash
# Next.js pages/app router
find . -path "*/pages/*" -name "*.test.tsx" -o -path "*/app/*" -name "*.test.tsx" 2>/dev/null

# React Router pages
find . -path "*/routes/*" -name "*.test.tsx" 2>/dev/null
```

### Run Tests

**Jest:**
```bash
npm test -- --testPathPattern="pages|app|routes" --passWithNoTests
```

**Vitest:**
```bash
npx vitest run pages app routes
```

### Page Test Considerations
- Mock Next.js router: `jest.mock('next/router')`
- Mock navigation: `useRouter` / `useNavigate`
- Test route parameters
- Test loading states
- Test error boundaries

### Update Progress
```bash
sed -i '' "s/\[ \] Page Tests/[x] Page Tests ($PASSED\/$TOTAL)/" .claude/regression-progress.md
```
</phase_3_pages>

<phase_4_visual>
## Phase 4: Visual Tests

**Objective:** Detect unintended visual changes using ui-visual-testing skill.

### Invoke Visual Testing Skill
```
Invoke skill: ui-visual-testing
Mode: regression-comparison
Focus: component-library
```

### Visual Testing Scope
1. **Component screenshots** - Compare against baseline
2. **Responsive layouts** - Test multiple viewports
3. **Theme variations** - Light/dark mode
4. **State variations** - Loading, error, empty states

### Screenshot Comparison
```bash
# If using Playwright components
npx playwright test --grep @visual

# If using Storybook
npm run storybook:test
```

### Record Visual Results
```markdown
## Visual Test Results
- Screenshots compared: X
- Matched: Y
- Changed: Z
- New (no baseline): W
```

### Update Progress
```bash
sed -i '' "s/\[ \] Visual Tests/[x] Visual Tests ($MATCHED\/$TOTAL matched)/" .claude/regression-progress.md
```
</phase_4_visual>

<phase_5_e2e>
## Phase 5: E2E Tests (UI Flows)

**Objective:** Test critical user flows in browser.

### Scope for Frontend-Only
Focus on UI flows that don't require real backend:
- Navigation flows
- Form interactions
- Modal/dialog flows
- Client-side validation
- UI state management

### Start Dev Server
```bash
# Use mock API or MSW
npm run dev:mock &
DEV_PID=$!
sleep 10
```

### Run UI E2E

**Playwright:**
```bash
npx playwright test --grep "@ui|@frontend" --reporter=list
```

**Cypress:**
```bash
npx cypress run --spec "cypress/e2e/ui/**/*.cy.ts" --headless
```

### Mock API Responses
```typescript
// Using MSW (Mock Service Worker)
import { setupServer } from 'msw/node';
import { handlers } from './mocks/handlers';

const server = setupServer(...handlers);
beforeAll(() => server.listen());
afterAll(() => server.close());
```

### Cleanup
```bash
kill $DEV_PID 2>/dev/null || true
```

### Update Progress
```bash
sed -i '' "s/\[ \] E2E Tests (UI)/[x] E2E Tests (UI) ($PASSED\/$TOTAL)/" .claude/regression-progress.md
```
</phase_5_e2e>

<phase_6_fix>
## Phase 6: Fix Failures

**Objective:** Debug and fix frontend-specific failures.

### Common Frontend Failure Categories

| Category | Symptoms | Fix Approach |
|----------|----------|--------------|
| `snapshot-drift` | Snapshot doesn't match | Review diff, update if intentional |
| `async-timing` | Flaky with async ops | Add proper waits |
| `mock-missing` | API calls not mocked | Add MSW handler |
| `provider-missing` | Context undefined | Wrap with providers |
| `dom-query-fail` | Element not found | Check selectors |
| `visual-diff` | Screenshot mismatch | Review visual change |

### For Each Failure

1. **Categorize**
   - Is it a test bug or a real bug?
   - Is the change intentional?

2. **Debug with debug-like-expert**
   ```
   Task: Investigate frontend test failure
   File: [component/hook file]
   Error: [error message]
   ```

3. **Apply fix**

4. **Re-run specific test**
   ```bash
   npm test -- --testPathPattern="[specific-file]" --watch=false
   ```

5. **Update snapshot if needed**
   ```bash
   npm test -- -u --testPathPattern="[specific-file]"
   ```

### Update Progress
```bash
sed -i '' "s/\[ \] Fix Failures/[x] Fix Failures ($FIXED fixed)/" .claude/regression-progress.md
```
</phase_6_fix>

<phase_7_report>
## Phase 7: Generate Report

**Objective:** Create frontend-focused regression report.

### Report Sections

1. **Summary**
   - Total tests run
   - Pass/fail/skip counts
   - Coverage metrics

2. **Component Coverage**
   - Components tested vs total
   - Coverage gaps

3. **Visual Regression**
   - Screenshots compared
   - Changes detected
   - Baseline updates needed

4. **E2E Results**
   - User flows tested
   - Timing metrics

5. **Recommendations**
   - Tests to add
   - Flaky tests to stabilize
   - Coverage improvements

### Save Report
```bash
cp populated-report.md .claude/regression-report-frontend-$(date +%Y-%m-%d).md
```

### Final Output
```
========================================
FRONTEND REGRESSION COMPLETE
========================================
Components: X/Y passed
Hooks: X/Y passed
Pages: X/Y passed
Visual: X/Y matched
E2E (UI): X/Y passed

Coverage: N%
Report: .claude/regression-report-frontend-YYYY-MM-DD.md
========================================
```
</phase_7_report>

<success_criteria>
## Success Criteria

Frontend regression is complete when:

1. All component tests pass or failures documented
2. All hook tests pass or failures documented
3. All page tests pass or failures documented
4. Visual tests compared against baseline
5. UI E2E flows verified
6. Report generated with recommendations
7. Coverage maintained or improved

### Quality Gates
- Component coverage > 80%
- No visual regressions (unless approved)
- All critical user flows passing
</success_criteria>

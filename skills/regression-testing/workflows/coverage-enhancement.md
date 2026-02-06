# Coverage Enhancement Workflow

<overview>
Assess current test coverage and enhance it to reach target threshold.
If coverage < 60%, this workflow blocks regression until improved.
Target: 100% coverage if starting below 60%.
</overview>

<required_reading>
Before starting, read these references:
1. `references/test-frameworks.md` - Coverage commands per framework
2. `references/project-detection.md` - Detect test runner
</required_reading>

<coverage_thresholds>
## Coverage Decision Matrix

| Current Coverage | Action | Target |
|------------------|--------|--------|
| < 30% | **CRITICAL** - Focus on critical paths only | 60% |
| 30-60% | **ENHANCE** - Must improve before regression | 80% |
| 60-80% | **ACCEPTABLE** - Suggest enhancement after tests | 90% |
| > 80% | **GOOD** - Minor enhancement optional | 95%+ |

### Priority by Code Area

| Area | Minimum | Target | Priority |
|------|---------|--------|----------|
| Auth/Security | 90% | 100% | P0 |
| API Endpoints | 80% | 95% | P0 |
| Business Logic | 80% | 90% | P1 |
| Data Access | 75% | 85% | P1 |
| Utilities | 60% | 80% | P2 |
| UI Components | 70% | 85% | P2 |
</coverage_thresholds>

<phase_1_assess>
## Phase 1: Assess Current Coverage

### Run Coverage Report

**Node/Jest:**
```bash
npm test -- --coverage --coverageReporters=json-summary,text --passWithNoTests
```

**Node/Vitest:**
```bash
npx vitest run --coverage --coverage.reporter=json-summary,text
```

**Python/pytest:**
```bash
pytest --cov=src --cov-report=json --cov-report=term-missing
```

### Parse Overall Coverage
```bash
# Node
LINES=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
BRANCHES=$(cat coverage/coverage-summary.json | jq '.total.branches.pct')
FUNCTIONS=$(cat coverage/coverage-summary.json | jq '.total.functions.pct')

# Python
COVERAGE=$(cat coverage.json | jq '.totals.percent_covered')
```

### Identify Gaps

**Find files with low coverage:**
```bash
# Node - files below 50%
cat coverage/coverage-summary.json | jq -r 'to_entries[] | select(.value.lines.pct < 50 and .key != "total") | "\(.key): \(.value.lines.pct)%"'

# Python
cat coverage.json | jq -r '.files | to_entries[] | select(.value.summary.percent_covered < 50) | "\(.key): \(.value.summary.percent_covered)%"'
```

**Find untested files:**
```bash
# Compare source files to test files
find src -name "*.ts" | while read f; do
    TEST_FILE=$(echo $f | sed 's/\.ts$/.test.ts/')
    [ ! -f "$TEST_FILE" ] && echo "UNTESTED: $f"
done
```

### Record Gaps in Progress
```markdown
## Coverage Gaps

### Critical (0% coverage)
- src/services/AuthService.ts
- src/api/payment/route.ts

### Low Coverage (<50%)
- src/services/UserService.ts: 35%
- src/lib/validation.ts: 42%

### Missing Tests
- src/hooks/useAuth.ts
- src/components/PaymentForm.tsx
```
</phase_1_assess>

<phase_2_prioritize>
## Phase 2: Prioritize Enhancement

### Categorize by Impact

**P0 - Security/Money:**
- Authentication/authorization
- Payment processing
- Data encryption
- Input validation (security)

**P1 - Core Business:**
- Main business logic
- API endpoints
- Data persistence

**P2 - User Experience:**
- UI components
- Error handling
- Loading states

### Create Enhancement Queue
```markdown
## Enhancement Queue

1. [P0] src/services/AuthService.ts (0% → 90%)
2. [P0] src/api/payment/route.ts (0% → 95%)
3. [P1] src/services/UserService.ts (35% → 80%)
4. [P1] src/lib/validation.ts (42% → 85%)
5. [P2] src/hooks/useAuth.ts (0% → 70%)
```

### Time Budget per Priority
| Priority | Time Budget | Target Coverage |
|----------|-------------|-----------------|
| P0 | 40% of time | 90%+ |
| P1 | 40% of time | 80%+ |
| P2 | 20% of time | 70%+ |
</phase_2_prioritize>

<phase_3_enhance>
## Phase 3: Write Tests

### Test Generation Strategy

**For each untested/low-coverage file:**

1. **Analyze the file**
   - What does it do?
   - What are the inputs/outputs?
   - What are the edge cases?
   - What dependencies need mocking?

2. **Generate test structure**
   ```typescript
   describe('ServiceName', () => {
     describe('methodName', () => {
       it('handles valid input', () => {});
       it('handles invalid input', () => {});
       it('handles edge case X', () => {});
       it('handles error condition', () => {});
     });
   });
   ```

3. **Write tests using qa-engineer agent**
   ```
   Task: Write comprehensive tests for [file]
   Current coverage: X%
   Target coverage: Y%
   Focus: [critical paths, edge cases, error handling]
   ```

### Test Writing Patterns

**Service Tests:**
```typescript
import { UserService } from './UserService';

jest.mock('../db/client');

describe('UserService', () => {
  describe('create', () => {
    it('creates user with valid data', async () => {
      const result = await UserService.create({ email: 'test@example.com' });
      expect(result).toHaveProperty('id');
    });

    it('throws on duplicate email', async () => {
      await expect(UserService.create({ email: 'existing@example.com' }))
        .rejects.toThrow('Email already exists');
    });

    it('hashes password before saving', async () => {
      const result = await UserService.create({ email: 'test@example.com', password: 'plain' });
      expect(result.password).not.toBe('plain');
    });
  });
});
```

**API Route Tests:**
```typescript
import request from 'supertest';
import app from '../app';

describe('POST /api/users', () => {
  it('returns 201 with valid data', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com' })
      .expect(201);
  });

  it('returns 400 with invalid email', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'invalid' })
      .expect(400);
  });

  it('returns 409 on duplicate email', async () => {
    await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com' })
      .expect(409);
  });
});
```

**Component Tests:**
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { PaymentForm } from './PaymentForm';

describe('PaymentForm', () => {
  it('renders all required fields', () => {
    render(<PaymentForm />);
    expect(screen.getByLabelText('Card Number')).toBeInTheDocument();
    expect(screen.getByLabelText('Expiry')).toBeInTheDocument();
    expect(screen.getByLabelText('CVV')).toBeInTheDocument();
  });

  it('validates card number format', async () => {
    render(<PaymentForm />);
    fireEvent.change(screen.getByLabelText('Card Number'), { target: { value: '1234' }});
    fireEvent.click(screen.getByText('Submit'));
    expect(await screen.findByText('Invalid card number')).toBeInTheDocument();
  });
});
```

### Verify Coverage After Each File
```bash
npm test -- --coverage --testPathPattern="[new-test-file]"
```
</phase_3_enhance>

<phase_4_verify>
## Phase 4: Verify Enhancement

### Run Full Coverage Report
```bash
npm test -- --coverage --coverageReporters=json-summary,text
```

### Compare Before/After
```markdown
## Coverage Improvement

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Lines | 45% | 78% | +33% |
| Branches | 38% | 72% | +34% |
| Functions | 52% | 81% | +29% |
| Statements | 44% | 77% | +33% |
```

### Check Target Met
```bash
CURRENT=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
TARGET=60  # or 80, depending on starting point

if [ $(echo "$CURRENT >= $TARGET" | bc) -eq 1 ]; then
    echo "TARGET MET: $CURRENT% >= $TARGET%"
else
    echo "TARGET NOT MET: $CURRENT% < $TARGET%"
    echo "Continue enhancing..."
fi
```

### Update Progress
```bash
sed -i '' "s/\[ \] Coverage Enhancement/[x] Coverage Enhancement (${BEFORE}% → ${AFTER}%)/" .claude/regression-progress.md
```
</phase_4_verify>

<iteration_loop>
## Enhancement Loop

```
While coverage < target:
    1. Get current coverage
    2. Find lowest-covered P0 file
    3. Write tests for that file
    4. Run coverage for that file
    5. If file meets target, move to next
    6. Repeat until overall target met
```

### Loop Exit Conditions
- Coverage >= target
- All P0 files covered to minimum
- Time budget exhausted (continue in next session)

### Progress Checkpoint
After each file enhanced:
```bash
echo "- $(date +%H:%M) - Enhanced [file]: X% → Y%" >> .claude/regression-progress.md
```
</iteration_loop>

<success_criteria>
## Success Criteria

Coverage enhancement is complete when:

1. **Overall coverage >= 60%** (if started < 30%)
2. **Overall coverage >= 80%** (if started 30-60%)
3. **All P0 files >= 90%** coverage
4. **All P1 files >= 80%** coverage
5. **No untested critical paths**

### Quality Checks
- All new tests pass
- No flaky tests introduced
- Tests are meaningful (not just for coverage)
- Edge cases covered
- Error conditions tested

### Coverage Report Updated
```markdown
## Final Coverage Summary

### By Area
| Area | Coverage | Target | Status |
|------|----------|--------|--------|
| Auth | 92% | 90% | ✓ |
| API | 88% | 80% | ✓ |
| Services | 85% | 80% | ✓ |
| Components | 72% | 70% | ✓ |

### Overall
- Lines: 81%
- Branches: 75%
- Functions: 84%
```
</success_criteria>

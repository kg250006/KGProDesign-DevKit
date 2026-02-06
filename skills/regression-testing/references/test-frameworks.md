# Test Framework Reference

<overview>
Framework-specific test commands, coverage tools, and configuration.
Use headless-compatible commands only (no watch mode).
</overview>

<javascript_jest>
## Jest

### Run Tests
```bash
# All tests with coverage
npm test -- --coverage --passWithNoTests

# Specific pattern
npm test -- --testPathPattern="auth"

# Specific file
npm test -- --testPathPattern="UserService.test.ts"

# Watch mode DISABLED for headless
# npm test -- --watch  # DON'T USE IN HEADLESS

# CI mode (recommended for headless)
npm test -- --ci --coverage
```

### Coverage
```bash
# JSON summary for parsing
npm test -- --coverage --coverageReporters=json-summary

# Parse coverage percentage
cat coverage/coverage-summary.json | jq '.total.lines.pct'

# List files below threshold
cat coverage/coverage-summary.json | jq -r 'to_entries[] | select(.value.lines.pct < 50) | .key'
```

### Configuration (jest.config.js)
```javascript
module.exports = {
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'json-summary', 'lcov'],
  coverageThreshold: {
    global: { lines: 80, branches: 80 }
  }
};
```
</javascript_jest>

<javascript_vitest>
## Vitest

### Run Tests
```bash
# All tests with coverage
npx vitest run --coverage

# Specific pattern
npx vitest run --testNamePattern="auth"

# Specific file
npx vitest run src/services/UserService.test.ts

# CI mode
npx vitest run --reporter=verbose --coverage
```

### Coverage
```bash
# Requires @vitest/coverage-v8 or @vitest/coverage-istanbul

# JSON output for parsing
npx vitest run --coverage --coverage.reporter=json-summary

# Parse coverage
cat coverage/coverage-summary.json | jq '.total.lines.pct'
```

### Configuration (vitest.config.ts)
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json-summary'],
      thresholds: { lines: 80, branches: 80 }
    }
  }
});
```
</javascript_vitest>

<javascript_playwright>
## Playwright (E2E)

### Run Tests
```bash
# All E2E tests (headless)
npx playwright test

# Specific test file
npx playwright test tests/e2e/login.spec.ts

# With browser visible (NOT for headless CI)
# npx playwright test --headed  # DON'T USE IN HEADLESS

# Generate report
npx playwright test --reporter=html

# List tests without running
npx playwright test --list
```

### Configuration (playwright.config.ts)
```typescript
export default defineConfig({
  use: {
    headless: true,  // ALWAYS true for CI
    screenshot: 'only-on-failure',
    video: 'retain-on-failure'
  },
  reporter: [['html', { outputFolder: 'playwright-report' }]]
});
```

### Screenshots for Debugging
```bash
# Capture on failure (configured in config)
# Screenshots saved to test-results/
```
</javascript_playwright>

<javascript_cypress>
## Cypress (E2E)

### Run Tests
```bash
# Headless mode (required for CI)
npx cypress run --headless

# Specific spec
npx cypress run --spec "cypress/e2e/login.cy.ts"

# With browser (NOT for headless CI)
# npx cypress open  # DON'T USE IN HEADLESS
```

### Configuration (cypress.config.ts)
```typescript
export default defineConfig({
  e2e: {
    video: true,
    screenshotOnRunFailure: true
  }
});
```
</javascript_cypress>

<python_pytest>
## pytest

### Run Tests
```bash
# All tests with coverage
pytest --cov=src --cov-report=term-missing

# Verbose output
pytest -v

# Stop on first failure
pytest -x

# Specific file
pytest tests/test_auth.py -v

# Specific test
pytest tests/test_auth.py::test_login -v

# By marker
pytest -m "not slow"

# Parallel execution
pytest -n auto  # Requires pytest-xdist
```

### Coverage
```bash
# Terminal report
pytest --cov=src --cov-report=term-missing

# JSON for parsing
pytest --cov=src --cov-report=json

# Parse coverage
cat coverage.json | jq '.totals.percent_covered'

# HTML report
pytest --cov=src --cov-report=html
```

### Configuration (pyproject.toml)
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
addopts = "-v --cov=src --cov-report=term-missing"

[tool.coverage.run]
source = ["src"]
branch = true

[tool.coverage.report]
fail_under = 80
```
</python_pytest>

<python_django>
## Django Tests

### Run Tests
```bash
# All tests
python manage.py test

# Specific app
python manage.py test myapp

# Specific test class
python manage.py test myapp.tests.TestUserView

# With coverage
coverage run manage.py test
coverage report
coverage html

# Parallel execution
python manage.py test --parallel
```

### Coverage
```bash
# Run with coverage
coverage run manage.py test

# Report
coverage report -m

# JSON for parsing
coverage json
cat coverage.json | jq '.totals.percent_covered'
```

### Configuration (.coveragerc)
```ini
[run]
source = .
omit =
    */migrations/*
    */tests/*
    manage.py

[report]
fail_under = 80
```
</python_django>

<rust_cargo>
## Rust (cargo test)

### Run Tests
```bash
# All tests
cargo test

# Verbose
cargo test -- --nocapture

# Specific test
cargo test test_login

# Integration tests only
cargo test --test integration

# Doc tests only
cargo test --doc
```

### Coverage
```bash
# Requires cargo-tarpaulin
cargo tarpaulin --out Html

# JSON output
cargo tarpaulin --out Json

# Parse coverage
cat tarpaulin-report.json | jq '.files[].covered'
```
</rust_cargo>

<go_test>
## Go (go test)

### Run Tests
```bash
# All tests
go test ./...

# Verbose
go test -v ./...

# Specific package
go test ./pkg/auth/...

# With coverage
go test -cover ./...

# Coverage profile
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### Coverage
```bash
# Generate profile
go test -coverprofile=coverage.out ./...

# Text report
go tool cover -func=coverage.out

# Parse total coverage
go tool cover -func=coverage.out | grep total | awk '{print $3}'
```
</go_test>

<coverage_thresholds>
## Coverage Thresholds

| Level | Percentage | Action |
|-------|------------|--------|
| Critical | < 30% | **WARN**: Only test critical paths first |
| Low | 30-60% | **ENHANCE**: Must improve before regression |
| Acceptable | 60-80% | **SUGGEST**: Recommend enhancement after tests |
| Good | 80-100% | **PROCEED**: Run regression as normal |

### Minimum Thresholds by Area

| Area | Minimum | Target |
|------|---------|--------|
| Auth/Security | 90% | 100% |
| API Endpoints | 80% | 95% |
| Business Logic | 80% | 90% |
| Utilities | 60% | 80% |
| UI Components | 70% | 85% |
</coverage_thresholds>

<ci_commands>
## CI-Optimized Commands

### Node.js
```bash
npm ci  # Clean install
npm test -- --ci --coverage --maxWorkers=2
npx playwright test --reporter=github
```

### Python
```bash
pip install -r requirements.txt
pytest --cov=src --cov-report=xml -n auto
```

### Rust
```bash
cargo test --release
cargo tarpaulin --out Xml
```

### Go
```bash
go test -race -coverprofile=coverage.out ./...
```
</ci_commands>

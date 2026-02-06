# Project Detection Patterns

<overview>
Detect project type and test infrastructure before running regression tests.
Never assume - always detect.
</overview>

<detection_script>
## Quick Detection Script

```bash
#!/bin/bash
# Run this first to understand the project

echo "=== PROJECT DETECTION ==="

# JavaScript/TypeScript
if [ -f "package.json" ]; then
    echo "PLATFORM: node"

    # Detect package manager
    [ -f "pnpm-lock.yaml" ] && echo "PACKAGE_MANAGER: pnpm"
    [ -f "yarn.lock" ] && echo "PACKAGE_MANAGER: yarn"
    [ -f "package-lock.json" ] && echo "PACKAGE_MANAGER: npm"

    # Detect framework
    if grep -q '"next"' package.json 2>/dev/null; then
        echo "FRAMEWORK: nextjs"
    elif grep -q '"react"' package.json 2>/dev/null; then
        echo "FRAMEWORK: react"
    elif grep -q '"vue"' package.json 2>/dev/null; then
        echo "FRAMEWORK: vue"
    elif grep -q '"@angular/core"' package.json 2>/dev/null; then
        echo "FRAMEWORK: angular"
    elif grep -q '"svelte"' package.json 2>/dev/null; then
        echo "FRAMEWORK: svelte"
    fi

    # Detect test runner
    if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || [ -f "jest.config.mjs" ]; then
        echo "TEST_RUNNER: jest"
    elif [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
        echo "TEST_RUNNER: vitest"
    elif grep -q '"mocha"' package.json 2>/dev/null; then
        echo "TEST_RUNNER: mocha"
    fi

    # Detect E2E runner
    if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
        echo "E2E_RUNNER: playwright"
    elif [ -f "cypress.config.ts" ] || [ -f "cypress.config.js" ]; then
        echo "E2E_RUNNER: cypress"
    fi
fi

# Python
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    echo "PLATFORM: python"

    # Detect package manager
    [ -f "pyproject.toml" ] && grep -q 'uv' pyproject.toml 2>/dev/null && echo "PACKAGE_MANAGER: uv"
    [ -f "poetry.lock" ] && echo "PACKAGE_MANAGER: poetry"
    [ -f "Pipfile.lock" ] && echo "PACKAGE_MANAGER: pipenv"

    # Detect framework
    if grep -qE "django" pyproject.toml requirements*.txt 2>/dev/null; then
        echo "FRAMEWORK: django"
    elif grep -qE "fastapi" pyproject.toml requirements*.txt 2>/dev/null; then
        echo "FRAMEWORK: fastapi"
    elif grep -qE "flask" pyproject.toml requirements*.txt 2>/dev/null; then
        echo "FRAMEWORK: flask"
    fi

    # Detect test runner
    if [ -f "pytest.ini" ] || [ -f "conftest.py" ] || [ -f "pyproject.toml" ]; then
        grep -qE "pytest" pyproject.toml requirements*.txt 2>/dev/null && echo "TEST_RUNNER: pytest"
    fi
fi

# Rust
if [ -f "Cargo.toml" ]; then
    echo "PLATFORM: rust"
    echo "TEST_RUNNER: cargo"
fi

# Go
if [ -f "go.mod" ]; then
    echo "PLATFORM: go"
    echo "TEST_RUNNER: go_test"
fi

# Java
if [ -f "pom.xml" ]; then
    echo "PLATFORM: java"
    echo "BUILD_TOOL: maven"
    echo "TEST_RUNNER: junit"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "PLATFORM: java"
    echo "BUILD_TOOL: gradle"
    echo "TEST_RUNNER: junit"
fi

# Static site / Netlify
if [ -f "netlify.toml" ]; then
    echo "DEPLOYMENT: netlify"
fi

# Docker
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo "CONTAINERIZED: true"
fi

echo ""
echo "=== TEST FILES ==="
find . -name "*.test.ts" -o -name "*.spec.ts" -o -name "*.test.tsx" -o -name "*.spec.tsx" \
    -o -name "test_*.py" -o -name "*_test.py" -o -name "*_test.go" 2>/dev/null | head -20
```
</detection_script>

<test_runner_detection>
## Test Runner Detection Table

| Indicator File | Test Runner | Test Command |
|----------------|-------------|--------------|
| `jest.config.js`, `jest.config.ts` | Jest | `npm test` or `npx jest` |
| `vitest.config.ts`, `vitest.config.js` | Vitest | `npm test` or `npx vitest run` |
| `playwright.config.ts` | Playwright | `npx playwright test` |
| `cypress.config.ts` | Cypress | `npx cypress run` |
| `pytest.ini`, `conftest.py` | pytest | `pytest` |
| `Cargo.toml` | cargo test | `cargo test` |
| `*_test.go` files | go test | `go test ./...` |
| `pom.xml` with surefire | JUnit/Maven | `mvn test` |
| `build.gradle` with test task | JUnit/Gradle | `./gradlew test` |
</test_runner_detection>

<package_json_detection>
## Detecting from package.json

```bash
# Check test script
jq -r '.scripts.test // "none"' package.json

# Check devDependencies for test runners
jq -r '.devDependencies | keys[]' package.json 2>/dev/null | grep -E "jest|vitest|mocha|cypress|playwright"

# Check for coverage tools
jq -r '.devDependencies | keys[]' package.json 2>/dev/null | grep -E "istanbul|nyc|c8|@vitest/coverage"
```
</package_json_detection>

<python_detection>
## Detecting Python Test Setup

```bash
# Check pyproject.toml for pytest
grep -A 5 "\[tool.pytest" pyproject.toml 2>/dev/null

# Check for test directories
ls -d tests/ test/ spec/ 2>/dev/null

# Check for Django test settings
grep -l "DJANGO_SETTINGS_MODULE" *.py manage.py 2>/dev/null

# Check for coverage configuration
grep -l "coverage" pyproject.toml setup.cfg tox.ini 2>/dev/null
```
</python_detection>

<test_file_patterns>
## Test File Naming Patterns

| Platform | Unit Tests | Integration Tests | E2E Tests |
|----------|------------|-------------------|-----------|
| JavaScript | `*.test.ts`, `*.spec.ts` | `*.integration.test.ts` | `*.e2e.ts`, `e2e/*.ts` |
| Python | `test_*.py`, `*_test.py` | `tests/integration/` | `tests/e2e/` |
| Rust | `#[test]` in `*.rs` | `tests/*.rs` | - |
| Go | `*_test.go` | `integration/*_test.go` | - |
| Java | `*Test.java` | `*IT.java` | - |

## Locating Tests

```bash
# JavaScript/TypeScript
find . -name "*.test.ts" -o -name "*.spec.ts" -o -name "*.test.tsx" 2>/dev/null | head -20

# Python
find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | head -20

# By directory structure
ls -la tests/ __tests__/ spec/ 2>/dev/null
```
</test_file_patterns>

<decision_tree>
## Detection Decision Tree

```
Start
  │
  ├─► package.json exists?
  │     │
  │     ├─► YES → Node/JS project
  │     │         │
  │     │         ├─► jest.config.* → Jest
  │     │         ├─► vitest.config.* → Vitest
  │     │         ├─► playwright.config.* → Playwright (E2E)
  │     │         └─► cypress.config.* → Cypress (E2E)
  │     │
  │     └─► NO → Check other platforms
  │
  ├─► pyproject.toml OR requirements.txt?
  │     │
  │     ├─► YES → Python project
  │     │         │
  │     │         ├─► pytest in deps → pytest
  │     │         ├─► django in deps → Django tests
  │     │         └─► unittest only → unittest
  │     │
  │     └─► NO → Check other platforms
  │
  ├─► Cargo.toml?
  │     └─► YES → Rust (cargo test)
  │
  ├─► go.mod?
  │     └─► YES → Go (go test)
  │
  └─► pom.xml OR build.gradle?
        └─► YES → Java (JUnit)
```
</decision_tree>

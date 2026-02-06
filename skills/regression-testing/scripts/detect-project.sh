#!/bin/bash
# Detect project type and test infrastructure
# Usage: bash detect-project.sh
# Output: YAML-like format for easy parsing

set -e

echo "PROJECT_DETECTION:"
echo "  timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "  directory: $(pwd)"
echo ""

# JavaScript/TypeScript
if [ -f "package.json" ]; then
    echo "PLATFORM:"
    echo "  type: node"

    # Detect package manager
    if [ -f "pnpm-lock.yaml" ]; then
        echo "  package_manager: pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "  package_manager: yarn"
    elif [ -f "package-lock.json" ]; then
        echo "  package_manager: npm"
    else
        echo "  package_manager: npm"
    fi

    # Detect framework
    echo ""
    echo "FRAMEWORK:"
    if grep -q '"next"' package.json 2>/dev/null; then
        echo "  name: nextjs"
        echo "  type: fullstack"
    elif grep -q '"react"' package.json 2>/dev/null; then
        echo "  name: react"
        echo "  type: frontend"
    elif grep -q '"vue"' package.json 2>/dev/null; then
        echo "  name: vue"
        echo "  type: frontend"
    elif grep -q '"@angular/core"' package.json 2>/dev/null; then
        echo "  name: angular"
        echo "  type: frontend"
    elif grep -q '"express"' package.json 2>/dev/null; then
        echo "  name: express"
        echo "  type: backend"
    elif grep -q '"fastify"' package.json 2>/dev/null; then
        echo "  name: fastify"
        echo "  type: backend"
    else
        echo "  name: unknown"
        echo "  type: unknown"
    fi

    # Detect test runner
    echo ""
    echo "TEST_RUNNER:"
    if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || [ -f "jest.config.mjs" ]; then
        echo "  name: jest"
        echo "  config_file: $(ls jest.config.* 2>/dev/null | head -1)"
        echo "  command: npm test"
    elif [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
        echo "  name: vitest"
        echo "  config_file: $(ls vitest.config.* 2>/dev/null | head -1)"
        echo "  command: npx vitest run"
    elif grep -q '"mocha"' package.json 2>/dev/null; then
        echo "  name: mocha"
        echo "  command: npm test"
    else
        echo "  name: none_detected"
    fi

    # Detect E2E runner
    echo ""
    echo "E2E_RUNNER:"
    if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
        echo "  name: playwright"
        echo "  config_file: $(ls playwright.config.* 2>/dev/null | head -1)"
        echo "  command: npx playwright test"
    elif [ -f "cypress.config.ts" ] || [ -f "cypress.config.js" ]; then
        echo "  name: cypress"
        echo "  config_file: $(ls cypress.config.* 2>/dev/null | head -1)"
        echo "  command: npx cypress run --headless"
    else
        echo "  name: none_detected"
    fi

# Python
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    echo "PLATFORM:"
    echo "  type: python"

    # Detect package manager
    if [ -f "pyproject.toml" ] && grep -q "uv" pyproject.toml 2>/dev/null; then
        echo "  package_manager: uv"
    elif [ -f "poetry.lock" ]; then
        echo "  package_manager: poetry"
    elif [ -f "Pipfile.lock" ]; then
        echo "  package_manager: pipenv"
    else
        echo "  package_manager: pip"
    fi

    # Detect framework
    echo ""
    echo "FRAMEWORK:"
    if grep -qE "django" pyproject.toml requirements*.txt 2>/dev/null; then
        echo "  name: django"
        echo "  type: fullstack"
    elif grep -qE "fastapi" pyproject.toml requirements*.txt 2>/dev/null; then
        echo "  name: fastapi"
        echo "  type: backend"
    elif grep -qE "flask" pyproject.toml requirements*.txt 2>/dev/null; then
        echo "  name: flask"
        echo "  type: backend"
    else
        echo "  name: unknown"
        echo "  type: unknown"
    fi

    # Detect test runner
    echo ""
    echo "TEST_RUNNER:"
    if [ -f "pytest.ini" ] || [ -f "conftest.py" ] || ([ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null); then
        echo "  name: pytest"
        echo "  command: pytest"
    elif grep -qE "django" pyproject.toml requirements*.txt 2>/dev/null; then
        echo "  name: django_test"
        echo "  command: python manage.py test"
    else
        echo "  name: unittest"
        echo "  command: python -m unittest discover"
    fi

    echo ""
    echo "E2E_RUNNER:"
    echo "  name: none_detected"

# Rust
elif [ -f "Cargo.toml" ]; then
    echo "PLATFORM:"
    echo "  type: rust"
    echo "  package_manager: cargo"

    echo ""
    echo "FRAMEWORK:"
    if grep -q "actix" Cargo.toml 2>/dev/null; then
        echo "  name: actix"
        echo "  type: backend"
    elif grep -q "rocket" Cargo.toml 2>/dev/null; then
        echo "  name: rocket"
        echo "  type: backend"
    else
        echo "  name: unknown"
        echo "  type: unknown"
    fi

    echo ""
    echo "TEST_RUNNER:"
    echo "  name: cargo_test"
    echo "  command: cargo test"

    echo ""
    echo "E2E_RUNNER:"
    echo "  name: none_detected"

# Go
elif [ -f "go.mod" ]; then
    echo "PLATFORM:"
    echo "  type: go"
    echo "  package_manager: go_modules"

    echo ""
    echo "FRAMEWORK:"
    if grep -q "gin" go.mod 2>/dev/null; then
        echo "  name: gin"
        echo "  type: backend"
    elif grep -q "echo" go.mod 2>/dev/null; then
        echo "  name: echo"
        echo "  type: backend"
    else
        echo "  name: unknown"
        echo "  type: unknown"
    fi

    echo ""
    echo "TEST_RUNNER:"
    echo "  name: go_test"
    echo "  command: go test ./..."

    echo ""
    echo "E2E_RUNNER:"
    echo "  name: none_detected"

# Java - Maven
elif [ -f "pom.xml" ]; then
    echo "PLATFORM:"
    echo "  type: java"
    echo "  build_tool: maven"

    echo ""
    echo "FRAMEWORK:"
    if grep -q "spring-boot" pom.xml 2>/dev/null; then
        echo "  name: spring_boot"
        echo "  type: backend"
    else
        echo "  name: unknown"
        echo "  type: unknown"
    fi

    echo ""
    echo "TEST_RUNNER:"
    echo "  name: junit"
    echo "  command: mvn test"

    echo ""
    echo "E2E_RUNNER:"
    echo "  name: none_detected"

# Java - Gradle
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "PLATFORM:"
    echo "  type: java"
    echo "  build_tool: gradle"

    echo ""
    echo "FRAMEWORK:"
    if grep -q "spring-boot" build.gradle* 2>/dev/null; then
        echo "  name: spring_boot"
        echo "  type: backend"
    else
        echo "  name: unknown"
        echo "  type: unknown"
    fi

    echo ""
    echo "TEST_RUNNER:"
    echo "  name: junit"
    echo "  command: ./gradlew test"

    echo ""
    echo "E2E_RUNNER:"
    echo "  name: none_detected"

else
    echo "PLATFORM:"
    echo "  type: unknown"
    echo "  error: Could not detect project type"
fi

# Deployment detection
echo ""
echo "DEPLOYMENT:"
if [ -f "netlify.toml" ]; then
    echo "  platform: netlify"
elif [ -f ".deployment-profile.json" ]; then
    echo "  platform: $(cat .deployment-profile.json | grep -o '"platform"[^,]*' | cut -d'"' -f4 2>/dev/null || echo 'unknown')"
elif [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo "  platform: docker"
else
    echo "  platform: unknown"
fi

# Check for containerization
echo ""
echo "CONTAINERIZATION:"
if [ -f "Dockerfile" ]; then
    echo "  docker: true"
else
    echo "  docker: false"
fi
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo "  docker_compose: true"
else
    echo "  docker_compose: false"
fi

# Test file discovery
echo ""
echo "TEST_FILES:"
echo "  unit_tests:"

# Count and list test files
unit_count=0
if ls ./**/*.test.ts ./**/*.spec.ts ./**/*.test.tsx ./**/*.spec.tsx 2>/dev/null | head -5 > /dev/null; then
    for f in $(find . -name "*.test.ts" -o -name "*.spec.ts" -o -name "*.test.tsx" -o -name "*.spec.tsx" 2>/dev/null | head -10); do
        echo "    - $f"
        unit_count=$((unit_count + 1))
    done
fi
if ls ./test_*.py ./*_test.py ./**/*_test.py ./**/test_*.py 2>/dev/null | head -5 > /dev/null; then
    for f in $(find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | head -10); do
        echo "    - $f"
        unit_count=$((unit_count + 1))
    done
fi
echo "  count: $unit_count"

# E2E test files
echo "  e2e_tests:"
e2e_count=0
if [ -d "e2e" ] || [ -d "tests/e2e" ] || [ -d "cypress/e2e" ]; then
    for f in $(find . -path "*e2e*" -name "*.ts" -o -path "*e2e*" -name "*.spec.ts" 2>/dev/null | head -10); do
        echo "    - $f"
        e2e_count=$((e2e_count + 1))
    done
fi
echo "  count: $e2e_count"

# Progress file check
echo ""
echo "PROGRESS_FILE:"
if [ -f ".claude/regression-progress.md" ]; then
    echo "  exists: true"
    echo "  path: .claude/regression-progress.md"
    # Get current phase if exists
    current_phase=$(grep "^## Current Phase" .claude/regression-progress.md -A 1 2>/dev/null | tail -1 || echo "unknown")
    echo "  current_phase: $current_phase"
else
    echo "  exists: false"
fi

echo ""
echo "DETECTION_COMPLETE: true"

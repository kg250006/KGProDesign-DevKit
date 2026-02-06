# Backend-Only Workflow

<overview>
Run backend-focused regression tests including API endpoints, services, database operations, and integrations.
Skips frontend components, UI tests, and visual regression.
</overview>

<required_reading>
Before starting, read these references:
1. `references/project-detection.md` - Detect backend framework
2. `references/test-frameworks.md` - Framework-specific commands
3. `references/progress-tracking.md` - Progress file format
</required_reading>

<scope>
## Test Scope

### Included
- `server/**/*.test.ts`
- `api/**/*.test.ts`
- `services/**/*.test.ts`
- `lib/server/**/*.test.ts`
- `routes/**/*.test.ts`
- Database integration tests
- API contract tests
- Authentication/authorization tests

### Excluded
- `components/**/*`
- `hooks/**/*`
- `pages/**/*` (unless server-side)
- `ui/**/*`
- Visual tests
- Browser-based E2E

### Python Scope
- `tests/api/**`
- `tests/services/**`
- `tests/integration/**`
- Model tests
- View/endpoint tests
</scope>

<pre_flight>
## Pre-Flight Checks

### 1. Detect Backend Framework

**Node.js:**
```bash
if grep -q '"express"' package.json 2>/dev/null; then
    FRAMEWORK="express"
elif grep -q '"fastify"' package.json 2>/dev/null; then
    FRAMEWORK="fastify"
elif grep -q '"@nestjs/core"' package.json 2>/dev/null; then
    FRAMEWORK="nestjs"
elif grep -q '"hono"' package.json 2>/dev/null; then
    FRAMEWORK="hono"
fi
```

**Python:**
```bash
if grep -qE "fastapi" pyproject.toml requirements*.txt 2>/dev/null; then
    FRAMEWORK="fastapi"
elif grep -qE "django" pyproject.toml requirements*.txt 2>/dev/null; then
    FRAMEWORK="django"
elif grep -qE "flask" pyproject.toml requirements*.txt 2>/dev/null; then
    FRAMEWORK="flask"
fi
```

### 2. Check Database Setup
```bash
# Check for database config
if [ -f "docker-compose.yml" ]; then
    grep -q "postgres\|mysql\|mongo" docker-compose.yml && HAS_DB=true
fi

# Check for ORM
if grep -q '"prisma"' package.json 2>/dev/null; then
    ORM="prisma"
elif grep -q '"drizzle"' package.json 2>/dev/null; then
    ORM="drizzle"
elif grep -q '"typeorm"' package.json 2>/dev/null; then
    ORM="typeorm"
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
- Mode: backend-only
- Framework: [FRAMEWORK]
- ORM: [ORM]
- Database: [DB_TYPE]

## Completed Phases
- [ ] Project Detection
- [ ] Database Setup
- [ ] Coverage Assessment
- [ ] Unit Tests - Services
- [ ] Unit Tests - API Routes
- [ ] Integration Tests
- [ ] API Contract Tests
- [ ] Fix Failures
- [ ] Generate Report

## Current Phase
Project Detection

## Failures to Fix
(none yet)

## Actions Log
- [timestamp] - Started backend regression
EOF
```
</pre_flight>

<phase_1_db_setup>
## Phase 1: Database Setup

**Objective:** Ensure test database is ready.

### Docker-based Setup
```bash
# Start database containers
if [ -f "docker-compose.yml" ]; then
    docker-compose up -d postgres redis 2>/dev/null || true
    sleep 5  # Wait for startup
fi
```

### Run Migrations
```bash
# Prisma
npx prisma migrate deploy --preview-feature 2>/dev/null || true
npx prisma db push 2>/dev/null || true

# Drizzle
npx drizzle-kit push:pg 2>/dev/null || true

# Django
python manage.py migrate --run-syncdb 2>/dev/null || true
```

### Seed Test Data (if needed)
```bash
# Check for seed script
if [ -f "prisma/seed.ts" ]; then
    npx prisma db seed
fi

# Django fixtures
python manage.py loaddata test_fixtures 2>/dev/null || true
```

### Update Progress
```bash
sed -i '' "s/\[ \] Database Setup/[x] Database Setup/" .claude/regression-progress.md
```
</phase_1_db_setup>

<phase_2_services>
## Phase 2: Service Unit Tests

**Objective:** Test business logic in isolation.

### Find Service Tests
```bash
# Node
find . -path "*/services/*" -name "*.test.ts" -o -path "*/lib/*" -name "*.test.ts" 2>/dev/null | grep -v node_modules

# Python
find . -path "*/services/*" -name "test_*.py" -o -name "*_test.py" 2>/dev/null
```

### Run Tests

**Node/Jest:**
```bash
npm test -- --testPathPattern="services|lib" --passWithNoTests --coverage
```

**Node/Vitest:**
```bash
npx vitest run services lib --coverage
```

**Python/pytest:**
```bash
pytest tests/services -v --cov=src/services
```

### Service Test Patterns
```typescript
// Mock external dependencies
jest.mock('../db/client');
jest.mock('../external/payment-api');

// Test business logic in isolation
describe('UserService', () => {
  it('creates user with hashed password', async () => {
    const user = await UserService.create({ email, password });
    expect(user.password).not.toBe(password);
  });
});
```

### Update Progress
```bash
sed -i '' "s/\[ \] Unit Tests - Services/[x] Unit Tests - Services ($PASSED\/$TOTAL)/" .claude/regression-progress.md
```
</phase_2_services>

<phase_3_api>
## Phase 3: API Route Tests

**Objective:** Test API endpoints with mocked dependencies.

### Find API Tests
```bash
# Node
find . -path "*/api/*" -name "*.test.ts" -o -path "*/routes/*" -name "*.test.ts" 2>/dev/null | grep -v node_modules

# Python
find . -path "*/api/*" -name "test_*.py" 2>/dev/null
```

### Run Tests

**Node/Jest:**
```bash
npm test -- --testPathPattern="api|routes" --passWithNoTests
```

**Node/Vitest:**
```bash
npx vitest run api routes
```

**Python/pytest:**
```bash
pytest tests/api -v
```

### API Test Patterns

**Node (supertest):**
```typescript
import request from 'supertest';
import app from '../app';

describe('POST /api/users', () => {
  it('creates user with valid data', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com' })
      .expect(201);

    expect(res.body.user).toHaveProperty('id');
  });
});
```

**Python (FastAPI):**
```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_user():
    response = client.post("/api/users", json={"email": "test@example.com"})
    assert response.status_code == 201
```

### Update Progress
```bash
sed -i '' "s/\[ \] Unit Tests - API Routes/[x] Unit Tests - API Routes ($PASSED\/$TOTAL)/" .claude/regression-progress.md
```
</phase_3_api>

<phase_4_integration>
## Phase 4: Integration Tests

**Objective:** Test with real database and service interactions.

### Find Integration Tests
```bash
find . -name "*.integration.test.ts" -o -path "*/integration/*" -name "*.test.ts" 2>/dev/null
```

### Run Tests

**Node:**
```bash
# Set test environment
DATABASE_URL=postgresql://test:test@localhost:5432/test_db npm test -- --testPathPattern="integration"
```

**Python:**
```bash
pytest tests/integration -v --cov
```

### Integration Test Considerations
- Use separate test database
- Run migrations before tests
- Clean up data after each test
- Handle async operations properly

### Transaction Rollback Pattern
```typescript
describe('UserService Integration', () => {
  beforeEach(async () => {
    await db.$executeRaw`BEGIN`;
  });

  afterEach(async () => {
    await db.$executeRaw`ROLLBACK`;
  });

  it('persists user to database', async () => {
    const user = await UserService.create({ email });
    const found = await db.user.findUnique({ where: { id: user.id }});
    expect(found).toBeDefined();
  });
});
```

### Update Progress
```bash
sed -i '' "s/\[ \] Integration Tests/[x] Integration Tests ($PASSED\/$TOTAL)/" .claude/regression-progress.md
```
</phase_4_integration>

<phase_5_contracts>
## Phase 5: API Contract Tests

**Objective:** Validate API contracts haven't broken.

### OpenAPI/Swagger Validation
```bash
# If using OpenAPI spec
npx @openapitools/openapi-generator-cli validate -i openapi.yaml
```

### Contract Test Patterns

**Response Schema Validation:**
```typescript
import Ajv from 'ajv';
import { userResponseSchema } from '../schemas';

describe('User API Contract', () => {
  it('matches response schema', async () => {
    const res = await request(app).get('/api/users/1');
    const ajv = new Ajv();
    const valid = ajv.validate(userResponseSchema, res.body);
    expect(valid).toBe(true);
  });
});
```

**Python (pydantic):**
```python
from app.schemas import UserResponse

def test_user_response_contract():
    response = client.get("/api/users/1")
    # Pydantic validates automatically
    user = UserResponse(**response.json())
    assert user.id is not None
```

### Update Progress
```bash
sed -i '' "s/\[ \] API Contract Tests/[x] API Contract Tests ($PASSED\/$TOTAL)/" .claude/regression-progress.md
```
</phase_5_contracts>

<phase_6_fix>
## Phase 6: Fix Failures

**Objective:** Debug and fix backend-specific failures.

### Common Backend Failure Categories

| Category | Symptoms | Fix Approach |
|----------|----------|--------------|
| `db-connection` | Cannot connect to DB | Check docker/env vars |
| `migration-drift` | Schema mismatch | Run migrations |
| `auth-failure` | 401/403 errors | Check token/session mocking |
| `validation-error` | 400 errors | Fix request payload |
| `async-leak` | Jest warns about open handles | Close connections properly |
| `data-pollution` | Tests affect each other | Add proper cleanup |

### For Each Failure

1. **Check database state**
   ```bash
   # Is DB running?
   docker ps | grep postgres

   # Can connect?
   npx prisma db pull
   ```

2. **Check environment**
   ```bash
   # Is test env set?
   echo $NODE_ENV
   echo $DATABASE_URL
   ```

3. **Debug with debug-like-expert**
   ```
   Task: Investigate backend test failure
   File: [service/api file]
   Error: [error message]
   ```

4. **Apply fix and re-run**
   ```bash
   npm test -- --testPathPattern="[specific-file]"
   ```

### Update Progress
```bash
sed -i '' "s/\[ \] Fix Failures/[x] Fix Failures ($FIXED fixed)/" .claude/regression-progress.md
```
</phase_6_fix>

<phase_7_cleanup>
## Phase 7: Cleanup and Report

### Stop Services
```bash
docker-compose down 2>/dev/null || true
```

### Generate Report
Create backend-focused report with:
- Service test results
- API test results
- Integration test results
- Contract validation results
- Coverage by module
- Database test metrics

### Save Report
```bash
cp populated-report.md .claude/regression-report-backend-$(date +%Y-%m-%d).md
```

### Final Output
```
========================================
BACKEND REGRESSION COMPLETE
========================================
Services: X/Y passed
API Routes: X/Y passed
Integration: X/Y passed
Contracts: X/Y valid

Coverage: N%
Report: .claude/regression-report-backend-YYYY-MM-DD.md
========================================
```
</phase_7_cleanup>

<success_criteria>
## Success Criteria

Backend regression is complete when:

1. Database setup verified
2. All service tests pass or failures documented
3. All API tests pass or failures documented
4. Integration tests pass with real DB
5. API contracts validated
6. Report generated
7. Services cleaned up (docker down)

### Quality Gates
- Service coverage > 85%
- API endpoint coverage > 90%
- No breaking contract changes
- All integration tests passing
</success_criteria>

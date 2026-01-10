# start-docker

Start the PageForge Docker environment with consistent no-cache builds and test account setup.

## Usage
`/start-docker [environment]`

## Parameters
- `environment`: Optional. Specify 'dev', 'debug', or 'prod'. Defaults to 'debug'.

## Description
This command starts the PageForge Docker environment with:
1. **No-cache builds** - Always builds fresh to ensure latest changes
2. **Test account population** - In debug mode, automatically populates test accounts
3. **Login verification** - Ensures test accounts work with proper credentials

## Command Flow

### 1. Clean Previous Containers
```bash
docker-compose down -v
docker system prune -f
```

### 2. Build with No Cache
```bash
# ALWAYS use --no-cache to ensure fresh builds
docker-compose build --no-cache
```

### 3. Start Services
```bash
# Start all services with proper environment
docker-compose up -d
```

### 4. Test Account Setup (Debug Mode Only)
When running in debug mode, the following test accounts are automatically populated:

| User Type | Email | Password |
|-----------|-------|----------|
| Admin | admin@pageforge.io | Admin123! |
| Editor | editor@pageforge.io | Editor123! |
| Viewer | viewer@pageforge.io | Viewer123! |
| Test User | test@example.com | Test123! |

These accounts match the login page examples and should be used for testing authentication.

### 5. Database Initialization
```bash
# Wait for database to be ready
docker-compose exec backend python -c "
from app.database import init_db
from app.models.user import create_test_users
import os

# Initialize database
init_db()

# In debug mode, create test accounts
if os.getenv('DEBUG', 'true').lower() == 'true':
    create_test_users()
    print('Test accounts created:')
    print('  admin@pageforge.io / Admin123!')
    print('  editor@pageforge.io / Editor123!')
    print('  viewer@pageforge.io / Viewer123!')
    print('  test@example.com / Test123!')
"
```

### 6. Login Verification
```bash
# Verify login works with test account
curl -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pageforge.io","password":"Admin123!"}'
```

## Complete Command Sequence

```bash
# Full no-cache startup sequence
docker-compose down -v && \
docker system prune -f && \
docker-compose build --no-cache && \
docker-compose up -d && \
sleep 5 && \
docker-compose exec backend python -m app.scripts.init_test_data
```

## Environment Variables
Set these in `.env` or `docker-compose.yml`:

```env
# Debug mode enables test accounts
DEBUG=true

# Database settings
DATABASE_URL=postgresql://pageforge:pageforge@db:5432/pageforge

# Ensure no caching
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
```

## Verification Steps

1. **Check all services are running:**
   ```bash
   docker-compose ps
   ```

2. **Verify database connection:**
   ```bash
   docker-compose exec backend python -c "from app.database import engine; print('DB Connected')"
   ```

3. **Test login with frontend:**
   - Navigate to http://localhost:3000
   - Use any test account email/password from the table above
   - Verify successful authentication

4. **Check logs for errors:**
   ```bash
   docker-compose logs -f backend
   docker-compose logs -f frontend
   ```

## Important Notes

- **ALWAYS use --no-cache** when building to ensure latest code changes are included
- **Test accounts are ONLY created in debug mode** - never in production
- **Use exact email and password** from the test accounts table for login testing
- **Frontend login page displays these test accounts** as examples in debug mode
- **All builds should be fresh** - never rely on cached layers for consistency

## Troubleshooting

If login fails with test accounts:
1. Verify DEBUG=true in environment
2. Check backend logs for account creation messages
3. Ensure database was properly initialized
4. Verify password hashing is working correctly

## Example Usage

```bash
# Start in debug mode with fresh build and test accounts
/start-docker debug

# Start in production mode (no test accounts)
/start-docker prod

# Default (debug mode with test accounts)
/start-docker
```
<overview>
GitHub production branch deployment pattern for enterprise applications. Uses a protected `production` branch that triggers deployments via webhooks, cron jobs, or CI/CD pipelines. Commonly paired with Docker for containerized deployments.
</overview>

<when_to_use>
## When to Use This Pattern

**Ideal for:**
- Enterprise applications with formal release processes
- Docker-based deployments
- Multi-environment setups (staging → production)
- Teams requiring PR reviews before production
- Applications with complex build/deploy pipelines
- Self-hosted infrastructure (VMs, Kubernetes)

**Detection signals:**
- Repository has `production` branch
- `Dockerfile` or `docker-compose.yml` in root
- CI/CD config (`.github/workflows/`, `azure-pipelines.yml`)
- Deploy scripts in `scripts/` or `deploy/` directory
</when_to_use>

<branch_strategy>
## Branch Strategy

**Standard flow:**
```
feature/* → main → production
              ↓
         staging (optional)
```

**Protected branches:**
```yaml
# main branch
- Require PR reviews (1-2 reviewers)
- Require status checks (tests pass)
- No direct pushes

# production branch
- Require PR from main only
- Require additional approval
- Restrict who can merge
- No direct pushes
```

**Merge to production:**
```bash
# From local
git checkout production
git merge main
git push origin production

# Via GitHub CLI
gh pr create --base production --head main --title "Release v1.2.3"
gh pr merge --merge
```
</branch_strategy>

<deployment_triggers>
## Deployment Triggers

**Option 1: GitHub Actions (recommended)**
```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  push:
    branches: [production]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to server
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/app
            git fetch origin production
            git reset --hard origin/production
            ./scripts/deploy.sh
```

**Option 2: Webhook to server**
```bash
# Server webhook receiver
# /var/www/webhook/server.js
const http = require('http');
const crypto = require('crypto');
const { exec } = require('child_process');

const SECRET = process.env.WEBHOOK_SECRET;

http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/deploy') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      // Verify signature
      const sig = req.headers['x-hub-signature-256'];
      const hmac = crypto.createHmac('sha256', SECRET);
      const digest = 'sha256=' + hmac.update(body).digest('hex');

      if (sig !== digest) {
        res.writeHead(401);
        return res.end('Invalid signature');
      }

      const payload = JSON.parse(body);
      if (payload.ref === 'refs/heads/production') {
        exec('/var/www/app/scripts/deploy.sh', (err, stdout, stderr) => {
          console.log('Deploy output:', stdout);
          if (err) console.error('Deploy error:', stderr);
        });
      }

      res.writeHead(200);
      res.end('OK');
    });
  }
}).listen(9000);
```

**Option 3: Cron job polling**
```bash
# /etc/cron.d/check-deploy
*/5 * * * * deployuser /var/www/app/scripts/check-and-deploy.sh >> /var/log/deploy.log 2>&1
```

**check-and-deploy.sh:**
```bash
#!/bin/bash
set -e

APP_DIR="/var/www/app"
BRANCH="production"
LOCK="/tmp/deploy.lock"

# Prevent concurrent deploys
[ -f "$LOCK" ] && exit 0

cd $APP_DIR
git fetch origin $BRANCH

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/$BRANCH)

if [ "$LOCAL" = "$REMOTE" ]; then
    exit 0
fi

echo "$(date): New commits detected, deploying..."
touch $LOCK
trap "rm -f $LOCK" EXIT

git reset --hard origin/$BRANCH
./scripts/deploy.sh

echo "$(date): Deploy complete"
```
</deployment_triggers>

<docker_deployment>
## Docker Deployment

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: myapp:${VERSION:-latest}
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    env_file:
      - .env.production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
    depends_on:
      - app
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    restart: unless-stopped

volumes:
  pgdata:
```

**Dockerfile:**
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3000
USER node
CMD ["node", "dist/index.js"]
```

**Deploy script (scripts/deploy.sh):**
```bash
#!/bin/bash
set -e

echo "=== Starting deployment ==="
echo "Time: $(date)"
echo "Commit: $(git rev-parse --short HEAD)"

# Load environment
set -a
source .env.production
set +a

# Pull latest images
echo "Pulling images..."
docker compose pull

# Build app image
echo "Building app..."
VERSION=$(git rev-parse --short HEAD) docker compose build app

# Stop old containers
echo "Stopping current containers..."
docker compose down

# Start new containers
echo "Starting new containers..."
docker compose up -d

# Wait for health check
echo "Waiting for health check..."
sleep 10

# Verify
if curl -sf http://localhost:3000/health > /dev/null; then
    echo "Health check passed!"
else
    echo "Health check failed! Rolling back..."
    docker compose down
    docker compose up -d  # Start previous version
    exit 1
fi

# Cleanup
echo "Cleaning up..."
docker image prune -f
docker volume prune -f

echo "=== Deployment complete ==="
```
</docker_deployment>

<zero_downtime>
## Zero-Downtime Deployment

**Blue-green with Docker Compose:**
```yaml
# docker-compose.yml
services:
  app-blue:
    build: .
    ports:
      - "3001:3000"

  app-green:
    build: .
    ports:
      - "3002:3000"

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
```

**nginx.conf (switch between blue/green):**
```nginx
upstream app {
    # Active deployment
    server app-blue:3000;
    # server app-green:3000;  # Uncomment to switch
}

server {
    listen 80;
    location / {
        proxy_pass http://app;
    }
}
```

**Deploy script with blue-green:**
```bash
#!/bin/bash
set -e

# Determine current and next deployment
CURRENT=$(docker compose ps --format json | jq -r '.[] | select(.State=="running") | .Service' | grep -E "app-(blue|green)" | head -1)

if [ "$CURRENT" = "app-blue" ]; then
    NEXT="app-green"
else
    NEXT="app-blue"
fi

echo "Current: $CURRENT, Deploying to: $NEXT"

# Build and start next version
docker compose build $NEXT
docker compose up -d $NEXT

# Wait for health check
sleep 10
if ! curl -sf http://localhost:$( [ "$NEXT" = "app-blue" ] && echo 3001 || echo 3002)/health; then
    echo "Health check failed"
    docker compose stop $NEXT
    exit 1
fi

# Switch nginx
sed -i "s/server $CURRENT/server $NEXT/" nginx/nginx.conf
docker compose exec nginx nginx -s reload

# Stop old version
sleep 5
docker compose stop $CURRENT

echo "Deployed to $NEXT"
```
</zero_downtime>

<database_migrations>
## Database Migrations

**Run migrations before deploy:**
```bash
#!/bin/bash
# scripts/deploy.sh

# 1. Pull code
git fetch origin production
git reset --hard origin/production

# 2. Run migrations (before stopping old app)
docker compose exec app npm run migrate

# 3. Build new version
docker compose build app

# 4. Deploy
docker compose up -d app

# 5. Verify
curl -f http://localhost:3000/health
```

**Rollback migrations:**
```bash
# Rollback last migration
docker compose exec app npm run migrate:rollback

# Rollback to specific version
docker compose exec app npm run migrate:rollback --to 20240101000000
```

**Safe migration pattern:**
```bash
# Check pending migrations
docker compose exec app npm run migrate:status

# Dry run
docker compose exec app npm run migrate -- --dry-run

# Execute
docker compose exec app npm run migrate
```
</database_migrations>

<environment_variables>
## Environment Variables

**.env.production (on server, never in git):**
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/myapp
REDIS_URL=redis://localhost:6379

# App secrets
JWT_SECRET=super-secret-key
API_KEY=external-api-key

# Feature flags
ENABLE_NEW_FEATURE=true
```

**Sync to server:**
```bash
# Copy to server
scp .env.production user@server:/var/www/app/.env.production

# Set permissions
ssh user@server "chmod 600 /var/www/app/.env.production"
```

**Docker secrets (alternative):**
```yaml
# docker-compose.yml
services:
  app:
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt
```
</environment_variables>

<monitoring>
## Monitoring and Logging

**Check deployment status:**
```bash
# Container status
docker compose ps

# Logs
docker compose logs -f app
docker compose logs --tail 100 app

# Resource usage
docker stats
```

**Health check endpoint:**
```javascript
// /api/health
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    version: process.env.VERSION || 'unknown',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});
```

**Alert on deploy:**
```bash
# In deploy.sh
SLACK_WEBHOOK="https://hooks.slack.com/..."

notify_slack() {
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$1\"}" \
        $SLACK_WEBHOOK
}

notify_slack "Deployment started: $(git rev-parse --short HEAD)"
# ... deploy ...
notify_slack "Deployment complete!"
```
</monitoring>

<rollback>
## Rollback Procedures

**Quick rollback (git):**
```bash
# On server
cd /var/www/app
git log --oneline -5  # Find previous commit
git reset --hard HEAD~1
./scripts/deploy.sh
```

**Docker image rollback:**
```bash
# List available images
docker images myapp

# Rollback to previous tag
VERSION=abc1234 docker compose up -d app
```

**Full rollback script:**
```bash
#!/bin/bash
# scripts/rollback.sh

PREVIOUS=$(git rev-parse HEAD~1)
echo "Rolling back to $PREVIOUS"

git reset --hard $PREVIOUS
docker compose build app
docker compose up -d app

sleep 10
if curl -sf http://localhost:3000/health; then
    echo "Rollback successful"
else
    echo "Rollback failed - manual intervention required"
    exit 1
fi
```
</rollback>

<github_actions_complete>
## Complete GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [production]
  workflow_dispatch:  # Manual trigger

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - uses: actions/checkout@v4

      - name: Set version
        id: version
        run: echo "version=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT

      - name: Login to Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.version.outputs.version }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@v1.0.0
        env:
          VERSION: ${{ needs.build.outputs.version }}
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.SSH_KEY }}
          envs: VERSION
          script: |
            cd /var/www/app
            docker pull ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:$VERSION
            VERSION=$VERSION docker compose up -d app
            sleep 10
            curl -f http://localhost:3000/health || exit 1

      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```
</github_actions_complete>

<security>
## Security Considerations

1. **Protect production branch** - Require reviews, status checks
2. **Use deployment keys** - Separate SSH key for deploy only
3. **Rotate secrets** - Regular rotation of API keys, passwords
4. **Audit deployments** - Log who deployed what when
5. **Limit server access** - Only deploy user can modify app
6. **Sign commits** - GPG signing for production merges
7. **Scan images** - Use Trivy or similar for vulnerability scanning
8. **Secrets in vault** - Not in environment files
</security>

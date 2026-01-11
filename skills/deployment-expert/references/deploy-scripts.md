<overview>
Expert guidance on creating deployment scripts, Docker configurations, cron job setup, and associating deployment automation with projects. Covers best practices for each deployment mechanism.
</overview>

<script_structure>
## Deployment Script Structure

**Standard deploy.sh:**
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
APP_NAME="myapp"
APP_DIR="/var/www/$APP_NAME"
LOG_FILE="/var/log/$APP_NAME/deploy.log"
LOCK_FILE="/tmp/$APP_NAME-deploy.lock"

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Lock to prevent concurrent deploys
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        log "ERROR: Deploy already in progress"
        exit 1
    fi
    echo $$ > "$LOCK_FILE"
    trap "rm -f $LOCK_FILE" EXIT
}

# Health check
health_check() {
    local url=${1:-"http://localhost:3000/health"}
    local retries=${2:-5}

    for i in $(seq 1 $retries); do
        if curl -sf "$url" > /dev/null; then
            return 0
        fi
        log "Health check attempt $i/$retries failed, waiting..."
        sleep 5
    done
    return 1
}

# Rollback
rollback() {
    log "Rolling back..."
    git reset --hard HEAD~1
    deploy_app
}

# Main deployment
deploy_app() {
    log "Installing dependencies..."
    npm ci --production

    log "Building..."
    npm run build

    log "Running migrations..."
    npm run migrate

    log "Restarting app..."
    pm2 restart ecosystem.config.js
}

# Main
main() {
    log "=== Starting deployment ==="
    acquire_lock

    cd "$APP_DIR"

    log "Pulling latest code..."
    git fetch origin main
    git reset --hard origin/main

    deploy_app

    log "Running health check..."
    if ! health_check; then
        log "ERROR: Health check failed!"
        rollback
        exit 1
    fi

    log "=== Deployment complete ==="
}

main "$@"
```

**Modular structure:**
```
scripts/
├── deploy.sh           # Main entry point
├── lib/
│   ├── common.sh       # Shared functions
│   ├── health.sh       # Health check functions
│   └── notify.sh       # Notification functions
├── hooks/
│   ├── pre-deploy.sh   # Run before deploy
│   └── post-deploy.sh  # Run after deploy
└── rollback.sh         # Manual rollback
```
</script_structure>

<platform_scripts>
## Platform-Specific Scripts

**Netlify deploy script:**
```bash
#!/bin/bash
# scripts/deploy-netlify.sh
set -e

echo "Building for Netlify..."
npm run build

echo "Deploying to Netlify..."
if [ "$1" = "--prod" ]; then
    netlify deploy --prod --dir=dist
else
    PREVIEW_URL=$(netlify deploy --dir=dist --json | jq -r '.deploy_url')
    echo "Preview: $PREVIEW_URL"
fi

echo "Verifying deployment..."
SITE_URL=$(netlify status --json | jq -r '.siteUrl')
curl -sf "$SITE_URL" > /dev/null && echo "Site is live!"
```

**Azure VM deploy script:**
```bash
#!/bin/bash
# scripts/deploy-azure.sh
set -e

SERVER="user@vm.azure.com"
APP_PATH="/var/www/app"
SSH_KEY="~/.ssh/azure_deploy"

echo "Building locally..."
npm run build

echo "Syncing files..."
rsync -avz --delete \
    --exclude 'node_modules' \
    --exclude '.git' \
    --exclude '.env*' \
    -e "ssh -i $SSH_KEY" \
    ./dist/ "$SERVER:$APP_PATH/dist/"

echo "Running remote deploy..."
ssh -i "$SSH_KEY" "$SERVER" << 'EOF'
cd /var/www/app
npm ci --production
pm2 restart ecosystem.config.js
EOF

echo "Verifying..."
curl -sf "https://mysite.com/health" && echo "Deployment successful!"
```

**FTP deploy script:**
```bash
#!/bin/bash
# scripts/deploy-ftp.sh
set -e

HOST=$(jq -r '.ftp.host' .deployment-profile.json)
USER=$(jq -r '.ftp.user' .deployment-profile.json)
REMOTE=$(jq -r '.ftp.remotePath' .deployment-profile.json)
PASS=$(cat ~/.deployment-expert/ftp-$(basename $PWD).pass)

echo "Building..."
npm run build

echo "Uploading to $HOST..."
lftp -u "$USER","$PASS" "sftp://$HOST" << EOF
mirror -R --verbose --delete ./dist $REMOTE
quit
EOF

echo "Done!"
```

**GitHub production deploy script:**
```bash
#!/bin/bash
# scripts/deploy-github-prod.sh
set -e

BRANCH="production"

echo "Merging main to production..."
git checkout main
git pull origin main

git checkout "$BRANCH"
git merge main --no-edit

echo "Pushing to trigger deploy..."
git push origin "$BRANCH"

git checkout main
echo "Production deploy triggered!"
```
</platform_scripts>

<docker_configs>
## Docker Configuration

**Dockerfile (production-optimized):**
```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies (cached layer)
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# Prune dev dependencies
RUN npm prune --production

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

# Security: non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy only production files
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

USER nodejs
EXPOSE 3000

ENV NODE_ENV=production

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
```

**docker-compose.yml (production):**
```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${IMAGE_NAME:-myapp}:${VERSION:-latest}
    container_name: myapp
    restart: unless-stopped
    ports:
      - "3000:3000"
    env_file:
      - .env.production
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
    depends_on:
      app:
        condition: service_healthy

networks:
  default:
    name: myapp-network
```

**Docker deploy script:**
```bash
#!/bin/bash
# scripts/docker-deploy.sh
set -e

VERSION=${1:-$(git rev-parse --short HEAD)}
IMAGE_NAME="myapp"

echo "Building image version: $VERSION"
docker build -t "$IMAGE_NAME:$VERSION" -t "$IMAGE_NAME:latest" .

echo "Stopping current containers..."
docker compose down

echo "Starting new containers..."
VERSION=$VERSION docker compose up -d

echo "Waiting for health check..."
sleep 10

if docker compose ps | grep -q "healthy"; then
    echo "Deployment successful!"
    docker image prune -f
else
    echo "Health check failed! Rolling back..."
    docker compose down
    VERSION=latest docker compose up -d
    exit 1
fi
```
</docker_configs>

<cron_setup>
## Cron Job Configuration

**Cron deployment checker:**
```bash
# /etc/cron.d/myapp-deploy
# Check for new commits every 5 minutes
*/5 * * * * deployuser /var/www/myapp/scripts/check-deploy.sh >> /var/log/myapp/cron.log 2>&1
```

**check-deploy.sh:**
```bash
#!/bin/bash
# scripts/check-deploy.sh
set -e

APP_DIR="/var/www/myapp"
DEPLOY_BRANCH="production"
LOCK_FILE="/tmp/myapp-deploy.lock"
LOG_FILE="/var/log/myapp/deploy.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check for lock
if [ -f "$LOCK_FILE" ]; then
    # Check if lock is stale (> 30 minutes old)
    if [ $(($(date +%s) - $(stat -c %Y "$LOCK_FILE"))) -gt 1800 ]; then
        log "Removing stale lock file"
        rm -f "$LOCK_FILE"
    else
        exit 0
    fi
fi

cd "$APP_DIR"

# Fetch latest
git fetch origin "$DEPLOY_BRANCH" --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$DEPLOY_BRANCH")

# No changes
if [ "$LOCAL" = "$REMOTE" ]; then
    exit 0
fi

log "New commits detected: $LOCAL -> $REMOTE"
log "Starting deployment..."

# Create lock
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# Deploy
git reset --hard "origin/$DEPLOY_BRANCH"
./scripts/deploy.sh >> "$LOG_FILE" 2>&1

log "Deployment complete"
```

**Setting up cron:**
```bash
# Create as root
sudo tee /etc/cron.d/myapp-deploy << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin

# Check for updates every 5 minutes
*/5 * * * * deployuser /var/www/myapp/scripts/check-deploy.sh

# Daily cleanup at 3am
0 3 * * * deployuser /var/www/myapp/scripts/cleanup.sh
EOF

# Set permissions
sudo chmod 644 /etc/cron.d/myapp-deploy

# Verify
sudo crontab -l -u deployuser
```

**Cron logging:**
```bash
# Ensure log directory exists
sudo mkdir -p /var/log/myapp
sudo chown deployuser:deployuser /var/log/myapp

# Log rotation
sudo tee /etc/logrotate.d/myapp << 'EOF'
/var/log/myapp/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```
</cron_setup>

<systemd_service>
## Systemd Service (Alternative to Cron)

**myapp-deploy.service:**
```ini
# /etc/systemd/system/myapp-deploy.service
[Unit]
Description=MyApp Deployment Checker
After=network.target

[Service]
Type=oneshot
User=deployuser
WorkingDirectory=/var/www/myapp
ExecStart=/var/www/myapp/scripts/check-deploy.sh
StandardOutput=append:/var/log/myapp/deploy.log
StandardError=append:/var/log/myapp/deploy.log
```

**myapp-deploy.timer:**
```ini
# /etc/systemd/system/myapp-deploy.timer
[Unit]
Description=Run deployment check every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

**Enable:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable myapp-deploy.timer
sudo systemctl start myapp-deploy.timer

# Check status
sudo systemctl list-timers
```
</systemd_service>

<profile_association>
## Associating Scripts with Project

**.deployment-profile.json:**
```json
{
  "version": "1.0",
  "platform": "azure-vm",
  "scripts": {
    "preDeploy": "scripts/hooks/pre-deploy.sh",
    "deploy": "scripts/deploy.sh",
    "postDeploy": "scripts/hooks/post-deploy.sh",
    "rollback": "scripts/rollback.sh",
    "healthCheck": "scripts/health-check.sh"
  },
  "cron": {
    "enabled": true,
    "schedule": "*/5 * * * *",
    "script": "scripts/check-deploy.sh",
    "logPath": "/var/log/myapp/cron.log"
  },
  "docker": {
    "dockerfile": "Dockerfile",
    "compose": "docker-compose.yml",
    "imageName": "myapp",
    "registry": "ghcr.io/myorg/myapp"
  }
}
```

**Initialize scripts for project:**
```bash
#!/bin/bash
# scripts/init-deploy-scripts.sh

PLATFORM=${1:-netlify}
SCRIPTS_DIR="./scripts"

mkdir -p "$SCRIPTS_DIR/hooks"

# Create base scripts based on platform
case $PLATFORM in
    netlify)
        cp ~/.deployment-expert/templates/netlify-deploy.sh "$SCRIPTS_DIR/deploy.sh"
        ;;
    azure-vm)
        cp ~/.deployment-expert/templates/azure-deploy.sh "$SCRIPTS_DIR/deploy.sh"
        cp ~/.deployment-expert/templates/check-deploy.sh "$SCRIPTS_DIR/check-deploy.sh"
        ;;
    ftp)
        cp ~/.deployment-expert/templates/ftp-deploy.sh "$SCRIPTS_DIR/deploy.sh"
        ;;
    github-production)
        cp ~/.deployment-expert/templates/docker-deploy.sh "$SCRIPTS_DIR/deploy.sh"
        cp ~/.deployment-expert/templates/check-deploy.sh "$SCRIPTS_DIR/check-deploy.sh"
        ;;
esac

# Make executable
chmod +x "$SCRIPTS_DIR"/*.sh

echo "Deploy scripts initialized for $PLATFORM"
```
</profile_association>

<best_practices>
## Best Practices

**Script essentials:**
1. `set -euo pipefail` at the start
2. Use functions for reusability
3. Log everything with timestamps
4. Use lock files to prevent concurrent runs
5. Always have a rollback path
6. Health check after every deploy

**Docker essentials:**
1. Multi-stage builds for smaller images
2. Non-root user in container
3. Health checks defined
4. Resource limits set
5. Proper logging configuration

**Cron essentials:**
1. Full paths in scripts
2. Redirect output to log files
3. Set up log rotation
4. Use lock files
5. Handle stale locks
6. Test manually first (`bash -x script.sh`)

**Security essentials:**
1. Dedicated deploy user (not root)
2. Minimal permissions
3. Secrets never in scripts
4. SSH keys over passwords
5. Audit logging
</best_practices>

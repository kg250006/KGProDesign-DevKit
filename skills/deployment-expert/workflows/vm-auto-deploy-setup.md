<required_reading>
Read references/azure-vm.md for SSH and authentication context.
Read workflows/troubleshoot.md for error handling patterns.
</required_reading>

<overview>
## VM Auto-Deploy Setup

Set up automated git-based deployment on a Linux VM with:
- Cron-based change detection
- Safety patterns (disk check, failure tracking, circuit breaker)
- SSH deploy key authentication (NOT Personal Access Tokens)
- Logrotate for log management
- Docker Compose orchestration with NPM reverse proxy

**CRITICAL: When entering any VM for deployment or troubleshooting, the FIRST action must be to read /opt/containers/OPERATIONS-RUNBOOK.md if it exists.**
</overview>

<process>
## Step 1: Verify Prerequisites

**On your local machine:**
```bash
# SSH access to VM
ssh {deploy-user}@{vm-ip} "echo 'SSH working'"

# Verify user is NOT root (security best practice)
# Deploy user should have sudo access but not be root
```

**On the VM:**
```bash
# Docker and Docker Compose installed
docker --version
docker compose version  # v2 syntax

# Git installed
git --version

# Sufficient disk space (need at least 5GB free)
df -h /
```

## Step 2: Create Directory Structure

```bash
# Run these commands on the VM as the deploy user (NOT root)
ssh {deploy-user}@{vm-ip}

# Application directory (clone your repo here)
sudo mkdir -p /opt/{app-name}
sudo chown {deploy-user}:{deploy-user} /opt/{app-name}

# Cron job infrastructure
sudo mkdir -p /opt/cron/{jobs,logs,locks,state}
sudo chown -R {deploy-user}:{deploy-user} /opt/cron

# Shared scripts and backups
sudo mkdir -p /opt/{scripts,database_backups,npm-config-backups}
sudo chown -R {deploy-user}:{deploy-user} /opt/scripts /opt/database_backups /opt/npm-config-backups

# NPM container directory (if using Nginx Proxy Manager)
sudo mkdir -p /opt/containers/nginx-proxy-manager
sudo chown -R {deploy-user}:{deploy-user} /opt/containers
```

**Expected structure:**
```
/opt/
├── containers/
│   ├── OPERATIONS-RUNBOOK.md      # *** READ THIS FIRST ***
│   └── nginx-proxy-manager/       # NPM configuration
├── {app-name}/                    # Application repository
│   ├── docker-compose.prod.yml
│   ├── .env.production            # NEVER in git
│   └── scripts/
│       ├── deploy-production.sh
│       └── cron/
│           ├── auto-deploy.sh
│           └── logrotate.conf
├── cron/
│   ├── jobs/                      # Symlinked cron scripts
│   ├── logs/                      # Deployment logs
│   ├── locks/                     # Lock files
│   └── state/                     # Failure tracking
├── scripts/                       # Shared VM utilities
└── database_backups/              # Database backup storage
```

## Step 3: Set Up GitHub SSH Deploy Key

**Why SSH Deploy Keys (NOT Personal Access Tokens):**
- Repository-specific (more secure than account-wide PAT)
- Read-only by default (safer for auto-deploy)
- No expiration issues causing deployment failures
- Won't be leaked in logs like tokens can be

**Generate key on VM:**
```bash
# As the deploy user (NOT root)
ssh-keygen -t ed25519 -C "{deploy-user}@{app-name}-deploy" -f ~/.ssh/id_ed25519

# View public key (add this to GitHub)
cat ~/.ssh/id_ed25519.pub
```

**Add to GitHub repository:**
```bash
# Option A: Via GitHub CLI (if installed)
gh repo deploy-key add ~/.ssh/id_ed25519.pub --repo {owner}/{repo} --title "{app-name}-vm-deploy"

# Option B: Via GitHub Web UI
# 1. Go to: https://github.com/{owner}/{repo}/settings/keys
# 2. Click "Add deploy key"
# 3. Title: "{app-name}-vm-deploy"
# 4. Key: Paste the public key
# 5. Allow write access: UNCHECKED (read-only is safer)
# 6. Click "Add key"
```

**Configure SSH for GitHub:**
```bash
# Create SSH config for GitHub
cat >> ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking no
EOF

# Set correct permissions
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Add GitHub to known hosts (prevents prompt in cron)
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
```

**Test authentication:**
```bash
ssh -T git@github.com
# Expected: "Hi {owner}/{repo}! You've successfully authenticated..."
```

## Step 4: Clone Repository with SSH URL

```bash
cd /opt
git clone git@github.com:{owner}/{repo}.git {app-name}
cd {app-name}

# Verify remote is SSH (not HTTPS)
git remote -v
# Should show: git@github.com:{owner}/{repo}.git

# If HTTPS, change to SSH:
git remote set-url origin git@github.com:{owner}/{repo}.git
```

## Step 5: Create Auto-Deploy Cron Script

Create `/opt/{app-name}/scripts/cron/auto-deploy.sh`:

```bash
#!/bin/bash
# Auto-deployment cron job for {app-name}
# Cron schedule: */5 * * * * /opt/cron/jobs/auto-deploy-{app}.sh

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================
APP_NAME="{app-name}"
REPO_DIR="${REPO_DIR:-/opt/${APP_NAME}}"
BRANCH="${BRANCH:-production}"
LOG_DIR="${LOG_DIR:-/opt/cron/logs}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/${APP_NAME}-deploy.log}"
LOCK_FILE="${LOCK_FILE:-/opt/cron/locks/${APP_NAME}-deploy.lock}"
DEPLOY_SCRIPT="${DEPLOY_SCRIPT:-${REPO_DIR}/scripts/deploy-production.sh}"

# Safety settings
LOCK_TIMEOUT=3600          # 1 hour max deployment time
FAILURE_TRACKER="/opt/cron/state/${APP_NAME}-failures"
MAX_CONSECUTIVE_FAILURES=3
FAILURE_COOLDOWN=3600      # Resume after 1 hour
MIN_DISK_SPACE_GB=5

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2; }
log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" | tee -a "$LOG_FILE"; }
log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $*" | tee -a "$LOG_FILE"; }
log_warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*" | tee -a "$LOG_FILE"; }

# CRITICAL: Disk space check before deployment
check_disk_space() {
    AVAILABLE_GB=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [[ $AVAILABLE_GB -lt $MIN_DISK_SPACE_GB ]]; then
        log_warn "Low disk space: ${AVAILABLE_GB}GB (need ${MIN_DISK_SPACE_GB}GB)"
        # Auto-cleanup
        docker system prune -af 2>/dev/null || true
        sudo journalctl --vacuum-time=7d 2>/dev/null || true
        AVAILABLE_GB=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
        if [[ $AVAILABLE_GB -lt $MIN_DISK_SPACE_GB ]]; then
            log_error "Still low disk space after cleanup: ${AVAILABLE_GB}GB"
            return 1
        fi
        log_info "Disk space recovered: ${AVAILABLE_GB}GB available"
    fi
    return 0
}

# Circuit breaker: Stop after N consecutive failures
check_failure_threshold() {
    [[ ! -f "$FAILURE_TRACKER" ]] && echo "0" > "$FAILURE_TRACKER"
    FAILURE_COUNT=$(cat "$FAILURE_TRACKER")

    # Reset if cooldown passed
    if [[ -f "$FAILURE_TRACKER" ]]; then
        # Linux stat syntax
        LAST_FAILURE_TIME=$(stat -c %Y "$FAILURE_TRACKER" 2>/dev/null || stat -f %m "$FAILURE_TRACKER")
        TIME_SINCE=$(($(date +%s) - LAST_FAILURE_TIME))
        if [[ $TIME_SINCE -gt $FAILURE_COOLDOWN ]]; then
            echo "0" > "$FAILURE_TRACKER"
            return 0
        fi
    fi

    if [[ $FAILURE_COUNT -ge $MAX_CONSECUTIVE_FAILURES ]]; then
        log_error "Auto-deploy DISABLED: $FAILURE_COUNT consecutive failures (cooldown ${FAILURE_COOLDOWN}s)"
        log_error "Manual intervention required. Reset with: echo 0 > $FAILURE_TRACKER"
        exit 1
    fi
}

record_failure() { echo $(($(cat "$FAILURE_TRACKER") + 1)) > "$FAILURE_TRACKER"; }
record_success() { echo "0" > "$FAILURE_TRACKER"; }

cleanup() { [[ -f "$LOCK_FILE" ]] && rm -f "$LOCK_FILE"; }
trap cleanup EXIT

# =============================================================================
# LOCK FILE HANDLING
# =============================================================================
if [[ -f "$LOCK_FILE" ]]; then
    # Linux stat syntax (macOS uses -f %m)
    LOCK_AGE=$(($(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE")))
    if [[ $LOCK_AGE -gt $LOCK_TIMEOUT ]]; then
        log_warn "Stale lock file (${LOCK_AGE}s old), removing"
        rm -f "$LOCK_FILE"
    else
        log_info "Deploy already in progress (lock age: ${LOCK_AGE}s)"
        exit 0
    fi
fi
touch "$LOCK_FILE"

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
mkdir -p "$LOG_DIR" "$(dirname "$FAILURE_TRACKER")"
check_failure_threshold
check_disk_space || { record_failure; exit 1; }

# =============================================================================
# GIT CHANGE DETECTION
# =============================================================================
cd "$REPO_DIR"
git fetch origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse "origin/$BRANCH")

if [[ "$LOCAL_COMMIT" == "$REMOTE_COMMIT" ]]; then
    log_info "No changes detected, already at $LOCAL_COMMIT"
    exit 0
fi

# =============================================================================
# DEPLOY
# =============================================================================
log_success "Changes detected! Updating from ${LOCAL_COMMIT:0:7} to ${REMOTE_COMMIT:0:7}"
git pull origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"

if bash "$DEPLOY_SCRIPT" 2>&1 | tee -a "$LOG_FILE"; then
    record_success
    log_success "AUTO-DEPLOYMENT COMPLETED SUCCESSFULLY"
else
    record_failure
    log_error "Deployment failed! Failures: $(cat "$FAILURE_TRACKER")/${MAX_CONSECUTIVE_FAILURES}"
    exit 1
fi
```

## Step 6: Create Main Deploy Script

Create `/opt/{app-name}/scripts/deploy-production.sh`:

```bash
#!/bin/bash
# Production deployment script for {app-name}
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="${APP_DIR}/docker-compose.prod.yml"
ENV_FILE="${APP_DIR}/.env.production"
NPM_CONTAINER="nginx-proxy-manager"
MIN_DISK_SPACE_GB=5

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
check_disk_space() {
    AVAILABLE_GB=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [[ $AVAILABLE_GB -lt $MIN_DISK_SPACE_GB ]]; then
        log "Low disk space: ${AVAILABLE_GB}GB, cleaning up..."
        docker system prune -af
        sudo journalctl --vacuum-time=7d 2>/dev/null || true
    fi
}

check_prerequisites() {
    command -v docker >/dev/null || { log_error "Docker not found"; exit 1; }
    command -v docker compose >/dev/null || { log_error "Docker Compose not found"; exit 1; }
    [[ -f "$COMPOSE_FILE" ]] || { log_error "Compose file not found: $COMPOSE_FILE"; exit 1; }
    [[ -f "$ENV_FILE" ]] || { log_error "Env file not found: $ENV_FILE"; exit 1; }
}

validate_npm_health() {
    if docker ps --format '{{.Names}}' | grep -q "^${NPM_CONTAINER}$"; then
        if ! docker exec ${NPM_CONTAINER} nginx -t 2>/dev/null; then
            log_error "NPM nginx config invalid"
            return 1
        fi
        log "NPM container healthy"
    else
        log "NPM container not found (may be on different host)"
    fi
}

# =============================================================================
# DEPLOYMENT
# =============================================================================
log "Starting deployment..."
cd "$APP_DIR"

check_disk_space
check_prerequisites
validate_npm_health

# Stop existing services
log "Stopping existing containers..."
docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

# Build and start
log "Building images..."
docker compose -f "$COMPOSE_FILE" build --no-cache

log "Starting services..."
docker compose -f "$COMPOSE_FILE" up -d

# Wait for health checks
log "Waiting for containers to be healthy..."
sleep 30

# CRITICAL: Reload NPM to refresh DNS cache
log "Reloading NPM DNS cache..."
if docker ps --format '{{.Names}}' | grep -q "^${NPM_CONTAINER}$"; then
    docker exec ${NPM_CONTAINER} nginx -s reload
    sleep 2
    log "NPM reloaded successfully"
fi

# Verify deployment
log "Verifying deployment..."
docker compose -f "$COMPOSE_FILE" ps

log "Deployment complete!"
```

## Step 7: Set Up Logrotate

Create `/opt/{app-name}/scripts/cron/logrotate.conf`:

```
/opt/cron/logs/{app-name}-deploy.log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    delaycompress
    # CRITICAL: Create with correct ownership for deploy user
    # Logrotate runs as root and creates new files as root
    # This ensures the deploy user can still write to the log
    create 0664 {deploy-user} {deploy-user}
    dateext
    dateformat -%Y%m%d
    sharedscripts
}
```

**Install logrotate config:**
```bash
sudo cp /opt/{app-name}/scripts/cron/logrotate.conf /etc/logrotate.d/{app-name}
sudo logrotate -d /etc/logrotate.d/{app-name}  # Test (dry run)
```

## Step 8: Install Cron Job

```bash
# Symlink script to cron jobs directory
ln -sf /opt/{app-name}/scripts/cron/auto-deploy.sh /opt/cron/jobs/auto-deploy-{app-name}.sh

# Make executable
chmod +x /opt/{app-name}/scripts/cron/auto-deploy.sh
chmod +x /opt/{app-name}/scripts/deploy-production.sh

# Add to crontab (as deploy user, NOT root)
crontab -e
# Add this line:
# */5 * * * * /opt/cron/jobs/auto-deploy-{app-name}.sh >> /opt/cron/logs/{app-name}-deploy.log 2>&1
```

**Verify crontab:**
```bash
crontab -l
# Should show the auto-deploy entry
```

## Step 9: Create Operations Runbook

Create `/opt/containers/OPERATIONS-RUNBOOK.md` following the template in `templates/operations-runbook.template.md`.

## Step 10: Test the Setup

```bash
# Manual test of auto-deploy script
/opt/cron/jobs/auto-deploy-{app-name}.sh

# Check logs
tail -f /opt/cron/logs/{app-name}-deploy.log

# Verify cron execution
grep CRON /var/log/syslog | tail -20

# Test failure tracking
cat /opt/cron/state/{app-name}-failures  # Should be 0 after success
```
</process>

<gotchas>
## Critical Gotchas

1. **ALWAYS read /opt/containers/OPERATIONS-RUNBOOK.md first** when entering any VM
2. **Never run cron jobs with sudo** - root can't access deploy user's SSH keys
3. **Use SSH deploy keys, NOT Personal Access Tokens** - more secure and no expiration issues
4. **Always reload NPM after container rebuilds** - fixes 502 Bad Gateway
5. **Use 127.0.0.1 instead of localhost** in Docker health checks (IPv6 issues)
6. **Logrotate creates files as root** - must specify correct ownership in config
7. **stat command differs between Linux/macOS** - script handles both
8. **Docker Compose v1 vs v2** - use `docker compose` (v2) not `docker-compose` (v1)
</gotchas>

<verification_checklist>
## Verification Checklist

- [ ] SSH key exists: `ls -la ~/.ssh/id_ed25519`
- [ ] SSH config exists: `cat ~/.ssh/config | grep github`
- [ ] Known hosts has GitHub: `grep github ~/.ssh/known_hosts`
- [ ] Remote is SSH URL: `git remote -v | grep "git@github.com"`
- [ ] Auth works: `ssh -T git@github.com`
- [ ] Fetch works: `git fetch origin {branch}`
- [ ] Cron installed: `crontab -l | grep auto-deploy`
- [ ] Logs writable: `touch /opt/cron/logs/test.log && rm /opt/cron/logs/test.log`
- [ ] Scripts executable: `ls -la /opt/{app-name}/scripts/*.sh`
- [ ] Docker running: `docker ps`
- [ ] Operations runbook exists: `cat /opt/containers/OPERATIONS-RUNBOOK.md | head -20`
</verification_checklist>

<success_criteria>
Setup is complete when:
- [ ] Directory structure created
- [ ] SSH deploy key configured and working
- [ ] Repository cloned with SSH remote
- [ ] Auto-deploy script installed and executable
- [ ] Deploy script installed and executable
- [ ] Logrotate configured with correct ownership
- [ ] Cron job installed (as deploy user, not root)
- [ ] Manual test deployment successful
- [ ] Operations runbook created
</success_criteria>

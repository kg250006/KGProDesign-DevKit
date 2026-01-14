<required_reading>
Read the platform-specific reference troubleshooting section.
Read references/deploy-scripts.md for script debugging.
</required_reading>

<process>
## Step 1: Identify the Problem

**Ask user:**
```
What issue are you experiencing?

1. Build fails
2. Deploy fails
3. Site is down / not responding
4. Environment variables not working
5. Forms not working (Netlify)
6. SSL/HTTPS issues
7. Other (describe)
```

## Step 2: Gather Context

```bash
# Get deployment info
PLATFORM=$(jq -r '.platform' .deployment-profile.json)
LAST_DEPLOY=$(jq -r '.lastDeploy' .deployment-profile.json)
LAST_STATUS=$(jq -r '.history[0].status' .deployment-profile.json)
LAST_COMMIT=$(jq -r '.history[0].commit' .deployment-profile.json)

echo "Platform: $PLATFORM"
echo "Last deploy: $LAST_DEPLOY"
echo "Last status: $LAST_STATUS"
echo "Last commit: $LAST_COMMIT"
```

## Step 3: Problem-Specific Diagnosis

### Build Fails

```bash
# Check build command
BUILD_CMD=$(jq -r '.build.command' .deployment-profile.json)
echo "Running: $BUILD_CMD"

# Capture full output
$BUILD_CMD 2>&1 | tee build.log

# Analyze errors
if grep -q "TypeScript" build.log; then
    echo "TypeScript errors detected"
    grep -A 3 "error TS" build.log
elif grep -q "Module not found" build.log; then
    echo "Missing module detected"
    grep "Module not found" build.log
elif grep -q "ENOENT" build.log; then
    echo "File not found error"
    grep "ENOENT" build.log
fi
```

**Common fixes:**
- Missing dependencies: `npm ci`
- Node version mismatch: Check `.nvmrc` or profile
- TypeScript errors: Fix types or add `// @ts-ignore`
- Memory issues: `NODE_OPTIONS=--max-old-space-size=4096`

### Deploy Fails

**Netlify:**
```bash
# Check auth
netlify status

# Check site connection
netlify link --id $(jq -r '.netlify.siteId' .deployment-profile.json)

# View deploy logs
netlify open:admin
```

**Azure VM:**
```bash
HOST=$(jq -r '.azureVm.host' .deployment-profile.json)
USER=$(jq -r '.azureVm.user' .deployment-profile.json)
KEY=$(jq -r '.azureVm.sshKeyPath' .deployment-profile.json)

# Test SSH connection
ssh -i "$KEY" -o ConnectTimeout=10 "$USER@$HOST" "echo 'Connection OK'"

# Check server logs
ssh -i "$KEY" "$USER@$HOST" "tail -50 /var/log/myapp/deploy.log"

# Check disk space
ssh -i "$KEY" "$USER@$HOST" "df -h"
```

**FTP:**
```bash
# Test connection
lftp -u "$USER" "sftp://$HOST" -e "pwd; quit"

# Check permissions
lftp -u "$USER" "sftp://$HOST" -e "ls -la /public_html; quit"
```

### Site Down / Not Responding

```bash
# Check DNS
dig +short "$SITE_URL"

# Check HTTP response
curl -I "$SITE_URL"

# Check specific endpoints
curl -v "$SITE_URL/api/health"

# Check from different location
curl -I "https://httpstat.us/200"  # Verify your internet works
```

**For Azure VM:**
```bash
# Check if app is running
ssh "$USER@$HOST" "pm2 status" 2>/dev/null || \
ssh "$USER@$HOST" "docker compose ps" 2>/dev/null

# Check ports
ssh "$USER@$HOST" "netstat -tlnp | grep LISTEN"

# Check nginx
ssh "$USER@$HOST" "systemctl status nginx"

# Check app logs
ssh "$USER@$HOST" "pm2 logs --lines 100" 2>/dev/null || \
ssh "$USER@$HOST" "docker compose logs --tail 100"
```

### Environment Variables Not Working

```bash
# Check local file exists
if [ -f ".env.production" ]; then
    echo "Local .env.production exists"
    echo "Variables defined: $(grep -c '^[A-Z]' .env.production)"
else
    echo "No .env.production file!"
fi

# Check platform
case $PLATFORM in
    netlify)
        echo "Platform variables:"
        netlify env:list
        ;;
    azure-vm)
        ssh "$USER@$HOST" "cat /var/www/app/.env | grep -c '^[A-Z]'" 2>/dev/null
        ;;
esac

# Check build-time vs runtime confusion
echo ""
echo "Build-time vars (baked into bundle):"
grep -E "^(NEXT_PUBLIC_|VITE_)" .env.production || echo "  None"

echo ""
echo "Runtime vars (read at startup):"
grep -vE "^(NEXT_PUBLIC_|VITE_|#|$)" .env.production | cut -d= -f1 || echo "  None"
```

### Netlify Forms Not Working

```bash
# Check form detection in deploy
netlify deploy --build 2>&1 | grep -i "form"

# Check HTML for required attributes
grep -r "data-netlify" ./dist/ || echo "No data-netlify attribute found!"
grep -r "form.*name=" ./dist/ || echo "No form name attribute found!"

# Check if forms are client-side rendered
# (Netlify can't detect forms rendered by JavaScript)
echo "If forms are rendered by React/Vue/etc., they won't be detected."
echo "Use static HTML or Netlify's form submission API instead."
```

### SSL/HTTPS Issues

```bash
# Check certificate
echo | openssl s_client -servername "$SITE_URL" -connect "${SITE_URL#https://}:443" 2>/dev/null | openssl x509 -noout -text | head -20

# Check for mixed content
curl -s "$SITE_URL" | grep -i "http://" | head -5

# Force HTTPS redirect check
curl -I "http://${SITE_URL#https://}" 2>/dev/null | grep -i "location"
```

## Step 4: Suggest Fixes

Based on diagnosis, provide actionable steps:

**Example output:**
```
═══════════════════════════════════════
Diagnosis Complete
═══════════════════════════════════════

Problem: Site returns 502 Bad Gateway

Root Cause: Node.js application crashed due to missing DATABASE_URL

Evidence:
  - pm2 shows app in "errored" state
  - App logs show: "Error: DATABASE_URL is not defined"

Fix:
1. Add DATABASE_URL to .env.production
2. Sync to server: scp .env.production user@host:/var/www/app/.env
3. Restart app: ssh user@host "pm2 restart all"
4. Verify: curl https://mysite.com/api/health

Would you like me to help with these steps?
═══════════════════════════════════════
```

## Step 5: Apply Fix (with user confirmation)

```
I can attempt to fix this automatically:

1. Add DATABASE_URL to .env.production
2. Sync environment to server
3. Restart application
4. Verify deployment

Proceed? (y/n)
```

## Step 6: Verify Fix

After applying fix:
```bash
# Wait for changes to take effect
sleep 10

# Check health
curl -s "$SITE_URL/api/health"

# Report result
if [ $? -eq 0 ]; then
    echo "Fix successful! Site is now healthy."
else
    echo "Issue persists. Additional investigation needed."
fi
```

## Step 7: Document Issue

Add to deployment history for future reference:
```bash
jq '.history = [{
    timestamp: (now | todate),
    commit: "troubleshooting",
    status: "fixed",
    issue: "502 Bad Gateway - missing DATABASE_URL",
    resolution: "Added env var and restarted"
}] + .history[:9]' .deployment-profile.json > tmp.json
mv tmp.json .deployment-profile.json
```
</process>

<common_issues>
## Quick Reference: Common Issues

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| 404 Not Found | Wrong output dir | Check build.output in profile |
| 502 Bad Gateway | App crashed OR NPM DNS stale | Reload NPM: `docker exec nginx-proxy-manager nginx -s reload` |
| Build timeout | Large dependencies | Increase timeout, cache deps |
| SSL error | Cert expired | Renew certificate |
| Env var undefined | Not synced to platform | Run env sync workflow |
| Forms not working | Client-rendered | Use static HTML forms |
| Slow deploys | No caching | Enable build cache |
| Permission denied | Wrong SSH key | Check key path and permissions |
| Disk full during build | Docker images accumulated | `docker system prune -af && journalctl --vacuum-time=7d` |
| Frontend container unhealthy | Health check uses localhost (IPv6) | Change to 127.0.0.1 in Dockerfile |
| Cron git fetch fails | SSH config missing | Create ~/.ssh/config with IdentityFile |
| Log permission denied | Logrotate ownership | Add `create 0664 {user} {user}` to logrotate config |
| Port already in use | Another container/process using port | Use Docker DNS + NPM, don't expose ports |
</common_issues>

<vm_specific_issues>
## VM Auto-Deploy Issues (Docker/NPM)

### Issue 1: Disk Full During Build (CRITICAL)
**Symptoms:** Docker build fails with "no space left on device"
**Diagnosis:**
```bash
df -h /                    # Check disk space
docker system df           # Check Docker usage
```
**Fix:**
```bash
# Auto-cleanup (add to deploy script)
docker system prune -af
sudo journalctl --vacuum-time=7d
```
**Prevention:** Add disk check at start of deployment script (see vm-auto-deploy-setup workflow)

### Issue 2: 502 Bad Gateway After Deploy (CRITICAL)
**Symptoms:** Site returns 502 immediately after successful deployment
**Root Cause:** Nginx Proxy Manager caches container IPs. After rebuild, containers get new IPs but NPM still routes to old ones.
**Diagnosis:**
```bash
# Check if containers are running
docker ps | grep {app}

# Check if NPM can reach container (from NPM container)
docker exec nginx-proxy-manager curl -sf http://{app}-backend-prod:8000/health
```
**Fix:**
```bash
# Reload NPM nginx config to refresh DNS cache
docker exec nginx-proxy-manager nginx -s reload
sleep 2
```
**Prevention:** Add NPM reload step to deploy script after containers start

### Issue 3: Cron Git Permission Denied (HIGH)
**Symptoms:** Cron job fails with "Permission denied (publickey)" but manual git works
**Root Cause:** Cron runs with minimal environment, can't access SSH agent
**Diagnosis:**
```bash
# Check if SSH config exists
cat ~/.ssh/config | grep github

# Check key permissions
ls -la ~/.ssh/id_ed25519

# Check if running as wrong user
whoami  # Should be deploy user, not root
```
**Fix:**
```bash
# Create SSH config with explicit IdentityFile
cat >> ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config

# Add github to known hosts
ssh-keyscan -H github.com >> ~/.ssh/known_hosts

# Use SSH remote URL (not HTTPS)
git remote set-url origin git@github.com:{owner}/{repo}.git
```
**Critical:** Never run cron job with sudo - root can't access deploy user's SSH keys

### Issue 4: Log File Permission Denied (HIGH)
**Symptoms:** Cron script fails to write logs after logrotate runs
**Root Cause:** Logrotate runs as root and creates new files as root. Deploy user can't write.
**Diagnosis:**
```bash
ls -la /opt/cron/logs/{app}-deploy.log
# If owned by root, this is the problem
```
**Fix:**
```bash
# Fix current file
sudo chown {deploy-user}:{deploy-user} /opt/cron/logs/{app}-deploy.log

# Fix logrotate config
sudo vi /etc/logrotate.d/{app}
# Add: create 0664 {deploy-user} {deploy-user}
```

### Issue 5: Frontend Shows Unhealthy (MEDIUM)
**Symptoms:** Frontend container perpetually "unhealthy" despite working
**Root Cause:** Health check uses "localhost" which may resolve to IPv6 (::1), but Next.js only listens on IPv4 (0.0.0.0)
**Diagnosis:**
```bash
# Check health check in Dockerfile
grep -A 2 HEALTHCHECK Dockerfile

# Test from inside container
docker exec {app}-frontend-prod node -e "require('http').get('http://localhost:3000')"
docker exec {app}-frontend-prod node -e "require('http').get('http://127.0.0.1:3000')"
```
**Fix:**
Update Dockerfile HEALTHCHECK to use 127.0.0.1:
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://127.0.0.1:3000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
```

### Issue 6: Migration Fails with PostgreSQL Error (MEDIUM)
**Symptoms:** Alembic/migration fails on boolean column default
**Root Cause:** PostgreSQL doesn't accept "0" or "1" as boolean defaults, must use "true"/"false"
**Diagnosis:**
```bash
# Check migration file
grep -r "server_default.*text" alembic/versions/
```
**Fix:**
```python
# Change this:
server_default=sa.text("0")

# To this:
server_default=sa.text("false")
```

### Issue 7: Database Container Won't Start (MEDIUM)
**Symptoms:** Database exits immediately with volume mount error
**Diagnosis:**
```bash
docker logs {app}-db-prod --tail 50
```
**Common causes:**
- Backup directory doesn't exist
- Permissions issue on mount
**Fix:**
```bash
# Create backup directory
sudo mkdir -p /mnt/backups/postgres
sudo chown {deploy-user}:{deploy-user} /mnt/backups/postgres
```

### Issue 8: Port Already in Use / Address Already Bound (HIGH)
**Symptoms:** Container fails to start with "port is already allocated" or "address already in use"
**Root Cause:** Another container or process is using the same host port
**Diagnosis:**
```bash
# Check what's using the port
sudo ss -tlnp | grep ":8000 "
# Or
sudo netstat -tlnp | grep ":8000 "

# Check Docker port bindings
docker ps --format '{{.Names}}: {{.Ports}}' | grep 8000

# List all bound ports
docker ps --format '{{.Names}}: {{.Ports}}'
```
**Fix Options:**

**Option A: Change the port (quick fix):**
```yaml
# Change host port in docker-compose.yml
ports:
  - "8001:8000"  # Use different host port
```

**Option B: Use Docker DNS + NPM (recommended):**
```yaml
# REMOVE ports section entirely
services:
  backend:
    # ports:        # DELETE THIS
    #   - "8000:8000"
    networks:
      - npm-network  # Add to NPM network instead

# Configure NPM to forward to container:internal_port
# Forward hostname: {app}-backend-prod
# Forward port: 8000 (internal, no clash possible)
```

**Why Option B is better:**
- Multiple apps can all use port 8000 internally without conflict
- Only NPM exposes ports 80/443 to the outside world
- Cleaner architecture, better security
- No port management headaches

**Prevention:**
- Never expose ports to host in production
- Use Docker DNS + NPM for all routing
- Run validation script before deploy: `./validate-deployment.sh`
</vm_specific_issues>

<decision_tree>
## Quick Diagnosis Tree

```
Site not working?
├─ Getting 502?
│   ├─ After deploy? → Reload NPM: docker exec nginx-proxy-manager nginx -s reload
│   ├─ Container stopped? → Check logs: docker logs {app}-backend-prod
│   └─ NPM not running? → docker compose up -d nginx-proxy-manager
├─ Getting 404?
│   ├─ Wrong URL? → Check domain in NPM config
│   └─ App not serving? → Check nginx/routing config
├─ SSL error?
│   └─ Check NPM → certbot certificates
└─ App crashing?
    ├─ Check logs → docker compose logs --tail 100
    ├─ OOM? → Increase memory limits
    └─ Missing env var? → Check .env.production

Cron not deploying?
├─ Check if running → grep CRON /var/log/syslog | tail -10
├─ Permission denied?
│   ├─ SSH? → Check ~/.ssh/config has IdentityFile
│   └─ Logs? → Check logrotate ownership
├─ Locked? → Check /opt/cron/locks/
└─ Circuit breaker? → Check /opt/cron/state/{app}-failures

Container won't start?
├─ "port already allocated"?
│   ├─ Find what's using it → ss -tlnp | grep :{port}
│   └─ FIX: Remove ports from compose, use Docker DNS + NPM
├─ "no space left"?
│   └─ docker system prune -af && journalctl --vacuum-time=7d
└─ Volume mount error?
    └─ Create directory with correct ownership
```
</decision_tree>

<success_criteria>
Troubleshooting is complete when:
- [ ] Problem identified
- [ ] Root cause determined
- [ ] Fix applied (with user consent)
- [ ] Site verified working
- [ ] Issue documented in history
- [ ] User informed of prevention measures
</success_criteria>

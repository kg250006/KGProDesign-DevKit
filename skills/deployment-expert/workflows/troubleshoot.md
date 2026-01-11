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
| 502 Bad Gateway | App crashed | Check pm2/docker logs |
| Build timeout | Large dependencies | Increase timeout, cache deps |
| SSL error | Cert expired | Renew certificate |
| Env var undefined | Not synced to platform | Run env sync workflow |
| Forms not working | Client-rendered | Use static HTML forms |
| Slow deploys | No caching | Enable build cache |
| Permission denied | Wrong SSH key | Check key path and permissions |
</common_issues>

<success_criteria>
Troubleshooting is complete when:
- [ ] Problem identified
- [ ] Root cause determined
- [ ] Fix applied (with user consent)
- [ ] Site verified working
- [ ] Issue documented in history
- [ ] User informed of prevention measures
</success_criteria>

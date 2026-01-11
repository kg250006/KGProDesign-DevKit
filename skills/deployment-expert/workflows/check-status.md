<required_reading>
Read the platform-specific reference for status checking commands.
</required_reading>

<process>
## Step 1: Load Profile

```bash
PROFILE=".deployment-profile.json"

if [ ! -f "$PROFILE" ]; then
    echo "No deployment profile found."
    exit 1
fi

PLATFORM=$(jq -r '.platform' "$PROFILE")
LAST_DEPLOY=$(jq -r '.lastDeploy // "Never"' "$PROFILE")
SITE_URL=$(jq -r '.verification.url' "$PROFILE")
HEALTH_ENDPOINT=$(jq -r '.verification.healthEndpoint // ""' "$PROFILE")
```

## Step 2: Check Site Health

```bash
FULL_URL="${SITE_URL}${HEALTH_ENDPOINT}"
echo "Checking: $FULL_URL"

RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 30 "$FULL_URL")
STATUS=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "200" ]; then
    echo "Status: ✓ Healthy (HTTP $STATUS)"
    if [ -n "$BODY" ]; then
        echo "Response: $BODY"
    fi
else
    echo "Status: ✗ Unhealthy (HTTP $STATUS)"
fi
```

## Step 3: Platform-Specific Status

### Netlify:
```bash
echo ""
echo "Netlify Status:"
netlify status

# Recent deploys
echo ""
echo "Recent Deploys:"
netlify api listSiteDeploys --data '{"site_id":"'$(jq -r '.netlify.siteId' "$PROFILE")'"}' | \
    jq -r '.[:5][] | "  \(.created_at) - \(.state) - \(.commit_ref[:7] // "manual")"'
```

### Azure VM:
```bash
HOST=$(jq -r '.azureVm.host' "$PROFILE")
USER=$(jq -r '.azureVm.user' "$PROFILE")
KEY=$(jq -r '.azureVm.sshKeyPath' "$PROFILE")

echo ""
echo "Server Status:"
ssh -i "$KEY" "$USER@$HOST" << 'EOF'
echo "Uptime: $(uptime -p)"
echo "Disk: $(df -h / | tail -1 | awk '{print $5 " used"}')"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo ""
echo "App Status:"
pm2 list 2>/dev/null || docker compose ps 2>/dev/null || echo "  No process manager detected"
EOF
```

### FTP:
```bash
HOST=$(jq -r '.ftp.host' "$PROFILE")
USER=$(jq -r '.ftp.user' "$PROFILE")

echo ""
echo "FTP Status:"
lftp -u "$USER" "sftp://$HOST" << 'EOF'
pwd
ls -la
quit
EOF
```

### GitHub Production:
```bash
BRANCH=$(jq -r '.githubProduction.branch' "$PROFILE")

echo ""
echo "Production Branch Status:"
git fetch origin "$BRANCH" --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")
MAIN=$(git rev-parse origin/main)

echo "  Main branch:       $(git rev-parse --short origin/main)"
echo "  Production branch: $(git rev-parse --short origin/$BRANCH)"

if [ "$REMOTE" = "$MAIN" ]; then
    echo "  Status: Production is up to date with main"
else
    BEHIND=$(git rev-list --count "$REMOTE..$MAIN")
    echo "  Status: Production is $BEHIND commits behind main"
fi
```

## Step 4: Deployment History

```bash
echo ""
echo "Deployment History:"
jq -r '.history[:5][] | "  \(.timestamp) - \(.commit) - \(.status)"' "$PROFILE" 2>/dev/null || echo "  No history recorded"
```

## Step 5: Environment Check

```bash
echo ""
echo "Environment Variables:"
REQUIRED=$(jq -r '.envVars.required[]' "$PROFILE" 2>/dev/null)

case $PLATFORM in
    netlify)
        PLATFORM_VARS=$(netlify env:list --json 2>/dev/null | jq -r '.[].key' || echo "")
        ;;
esac

for var in $REQUIRED; do
    if echo "$PLATFORM_VARS" | grep -q "^$var$"; then
        echo "  ✓ $var"
    else
        echo "  ✗ $var (not set on platform)"
    fi
done
```

## Step 6: SSL/Certificate Status (if applicable)

```bash
echo ""
echo "SSL Certificate:"
CERT_INFO=$(echo | openssl s_client -servername "$SITE_URL" -connect "${SITE_URL#https://}:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)

if [ -n "$CERT_INFO" ]; then
    EXPIRY=$(echo "$CERT_INFO" | grep "notAfter" | cut -d= -f2)
    echo "  Expires: $EXPIRY"

    # Check if expiring soon (30 days)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$EXPIRY" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

    if [ $DAYS_LEFT -lt 30 ]; then
        echo "  ⚠ Certificate expires in $DAYS_LEFT days!"
    else
        echo "  ✓ Valid for $DAYS_LEFT days"
    fi
else
    echo "  Could not check certificate"
fi
```

## Step 7: Summary Report

```
═══════════════════════════════════════
Deployment Status Summary
═══════════════════════════════════════

Platform:     Netlify
Site URL:     https://my-site.netlify.app
Last Deploy:  2025-01-11T14:30:00Z
Commit:       abc1234

Health:       ✓ Healthy
SSL:          ✓ Valid (45 days remaining)
Env Vars:     ✓ All required variables set

Recent Activity:
  - 2025-01-11 14:30 - Deployed abc1234 (success)
  - 2025-01-10 10:15 - Deployed def5678 (success)

No issues detected.
═══════════════════════════════════════
```
</process>

<success_criteria>
Status check is complete when:
- [ ] Site health verified
- [ ] Platform-specific status retrieved
- [ ] Deployment history displayed
- [ ] Environment variables checked
- [ ] SSL certificate status verified
- [ ] Summary report provided to user
</success_criteria>

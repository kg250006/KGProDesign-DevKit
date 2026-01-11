<required_reading>
Based on detected platform, read:
- Netlify: references/netlify.md
- Azure VM: references/azure-vm.md
- FTP: references/ftp.md
- GitHub Production: references/github-production.md

Always read: references/env-vars.md (for variable validation)
</required_reading>

<process>
## Step 1: Check for Deployment Profile

```bash
if [ -f ".deployment-profile.json" ]; then
    PLATFORM=$(jq -r '.platform' .deployment-profile.json)
    echo "Found profile: $PLATFORM deployment"
else
    echo "No deployment profile found."
    # Route to setup-profile workflow
fi
```

**If no profile exists:**
→ Ask: "No deployment profile found. Would you like to set one up?"
→ Route to `workflows/setup-profile.md`

**If profile exists:**
→ Continue with deployment

## Step 2: Validate Environment Variables

Check that required environment variables are set:

```bash
# Get required vars from profile
REQUIRED=$(jq -r '.envVars.required[]' .deployment-profile.json)

# Check each
for var in $REQUIRED; do
    if ! grep -q "^$var=" .env.production 2>/dev/null; then
        echo "Missing: $var"
        MISSING+=("$var")
    fi
done
```

**If variables missing:**
→ Ask: "Missing required variables: [list]. Would you like to add them now?"
→ Route to `workflows/manage-env-vars.md` if yes

## Step 3: Build the Project

```bash
BUILD_CMD=$(jq -r '.build.command' .deployment-profile.json)
OUTPUT_DIR=$(jq -r '.build.output' .deployment-profile.json)

echo "Building with: $BUILD_CMD"
eval "$BUILD_CMD"

# Verify build output
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Build failed: output directory not found"
    exit 1
fi
```

**Report to user:**
- "Build complete. Output in `dist/` (X files, Y MB)"

## Step 4: Execute Platform-Specific Deploy

### Netlify
```bash
SITE_ID=$(jq -r '.netlify.siteId' .deployment-profile.json)
netlify deploy --prod --dir="$OUTPUT_DIR" --site="$SITE_ID"
```

### Azure VM
```bash
HOST=$(jq -r '.azureVm.host' .deployment-profile.json)
USER=$(jq -r '.azureVm.user' .deployment-profile.json)
KEY=$(jq -r '.azureVm.sshKeyPath' .deployment-profile.json)

# Sync files
rsync -avz --delete -e "ssh -i $KEY" \
    ./$OUTPUT_DIR/ "$USER@$HOST:/var/www/app/dist/"

# Run deploy script
ssh -i "$KEY" "$USER@$HOST" "cd /var/www/app && ./deploy.sh"
```

### FTP
```bash
HOST=$(jq -r '.ftp.host' .deployment-profile.json)
USER=$(jq -r '.ftp.user' .deployment-profile.json)
REMOTE=$(jq -r '.ftp.remotePath' .deployment-profile.json)

lftp -u "$USER" "sftp://$HOST" << EOF
mirror -R --verbose --delete "$OUTPUT_DIR" "$REMOTE"
quit
EOF
```

### GitHub Production
```bash
BRANCH=$(jq -r '.githubProduction.branch' .deployment-profile.json)
BASE=$(jq -r '.githubProduction.baseBranch' .deployment-profile.json)

git checkout "$BASE"
git pull origin "$BASE"
git checkout "$BRANCH"
git merge "$BASE" --no-edit
git push origin "$BRANCH"
```

## Step 5: Wait for Propagation

Different platforms have different propagation times:
- Netlify: 30-60 seconds
- Azure VM: immediate after script completes
- FTP: immediate
- GitHub Production: depends on CI/CD pipeline (1-5 minutes)

```bash
echo "Waiting for deployment to propagate..."
sleep 30  # Adjust based on platform
```

## Step 6: Verify Deployment

```bash
URL=$(jq -r '.verification.url' .deployment-profile.json)
HEALTH=$(jq -r '.verification.healthEndpoint // ""' .deployment-profile.json)
EXPECTED=$(jq -r '.verification.expectedStatus // 200' .deployment-profile.json)

FULL_URL="$URL$HEALTH"
echo "Checking $FULL_URL..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "$FULL_URL")

if [ "$STATUS" = "$EXPECTED" ]; then
    echo "Deployment verified! Site is live."
else
    echo "Warning: Expected status $EXPECTED, got $STATUS"
fi
```

## Step 7: Update Profile and Report

```bash
# Update last deploy timestamp
jq '.lastDeploy = now | todate' .deployment-profile.json > tmp.json
mv tmp.json .deployment-profile.json

# Add to history
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
jq --arg commit "$COMMIT" \
   '.history = [{ timestamp: (now | todate), commit: $commit, status: "success" }] + (.history // [])[:9]' \
   .deployment-profile.json > tmp.json
mv tmp.json .deployment-profile.json
```

**Report to user:**
```
Deployment Complete!

Platform: Netlify
Site URL: https://my-site.netlify.app
Commit: abc1234
Status: Live and verified
Duration: 45 seconds
```
</process>

<error_handling>
## Error Handling

**Build failure:**
```
Build failed with exit code 1.

Errors:
- TypeScript error in src/index.ts line 45

Would you like me to:
1. Show the full error log
2. Help fix the error
3. Cancel deployment
```

**Deploy failure:**
```
Deployment failed.

Error: Unable to connect to Netlify API
Status: 401 Unauthorized

This usually means:
- Auth token expired
- Site ID incorrect

Would you like me to:
1. Re-authenticate with Netlify
2. Check site configuration
3. View detailed error log
```

**Verification failure:**
```
Deployment completed but verification failed.

Expected: 200 OK
Got: 502 Bad Gateway

The site may still be propagating. Options:
1. Wait and retry verification
2. Check application logs
3. Roll back to previous version
```
</error_handling>

<success_criteria>
Deployment is successful when:
- [ ] Profile exists and is valid
- [ ] Environment variables validated
- [ ] Build completes without errors
- [ ] Files deployed to platform
- [ ] Site responds with expected status
- [ ] Profile updated with deployment record
- [ ] User notified with deployment URL
</success_criteria>

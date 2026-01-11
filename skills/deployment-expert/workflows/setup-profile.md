<required_reading>
Read references/profiles.md for profile structure.
Based on platform selection, also read the relevant platform reference.
</required_reading>

<process>
## Step 1: Detect Existing Indicators

Check for platform signals in the project:

```bash
# Detection order
if [ -f "netlify.toml" ]; then
    SUGGESTED="netlify"
    REASON="Found netlify.toml configuration file"
elif [ -f ".azure/config" ] || [ -f "azure-pipelines.yml" ]; then
    SUGGESTED="azure-vm"
    REASON="Found Azure configuration files"
elif git branch -r 2>/dev/null | grep -q "origin/production"; then
    if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
        SUGGESTED="github-production"
        REASON="Found production branch with Docker configuration"
    fi
elif [ -f ".ftpconfig" ] || [ -f "ftp-deploy.json" ]; then
    SUGGESTED="ftp"
    REASON="Found FTP configuration file"
fi
```

**Ask user to confirm:**
```
I detected this might be a [platform] project because: [reason]

Is this correct?
1. Yes, set up [platform] deployment
2. No, use a different platform
3. Let me explain my setup
```

## Step 2: Gather Platform-Specific Information

### For Netlify:
```
Questions:
1. Do you have a Netlify account connected? (Run `netlify status` to check)
2. Is this a new site or linking to existing?
   - New: What should the site be named?
   - Existing: What's the site ID or name?
3. Does your project use Netlify Forms? (yes/no)
4. Does your project use Netlify Functions? (yes/no)
```

### For Azure VM:
```
Questions:
1. What's the VM hostname or IP address?
2. What username should I use for SSH?
3. Where is the SSH key located? (default: ~/.ssh/id_ed25519)
4. What's the application path on the server? (e.g., /var/www/app)
5. Is there an existing deploy script? (e.g., ./deploy.sh)
```

### For FTP:
```
Questions:
1. What's the FTP hostname?
2. What's your FTP username?
3. What protocol? (SFTP recommended, FTP, or FTPS)
4. What's the remote path? (e.g., /public_html)
5. Is this for a PHP application or static files?
```

### For GitHub Production:
```
Questions:
1. What's the production branch name? (default: production)
2. Does this use Docker? (yes/no)
3. How is deployment triggered?
   - GitHub Actions
   - Webhook to server
   - Cron job on server
4. If cron: What server hosts the application?
```

## Step 3: Detect Build Configuration

```bash
# Detect package manager and build command
if [ -f "package.json" ]; then
    # Check for common build scripts
    BUILD_CMD=$(jq -r '.scripts.build // empty' package.json)

    # Detect framework and output dir
    if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
        FRAMEWORK="Next.js"
        OUTPUT="out"  # or .next for SSR
    elif [ -f "astro.config.mjs" ]; then
        FRAMEWORK="Astro"
        OUTPUT="dist"
    elif [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
        FRAMEWORK="Vite"
        OUTPUT="dist"
    else
        FRAMEWORK="Node.js"
        OUTPUT="dist"
    fi
fi
```

**Confirm with user:**
```
Detected build configuration:
- Framework: [framework]
- Build command: npm run build
- Output directory: dist/

Is this correct, or would you like to customize?
```

## Step 4: Test Connection

### Netlify:
```bash
netlify status
netlify link --id $SITE_ID
```

### Azure VM:
```bash
ssh -i $KEY_PATH -o ConnectTimeout=10 $USER@$HOST "echo 'Connection successful'"
```

### FTP:
```bash
lftp -u $USER "sftp://$HOST" -e "ls; quit"
```

### GitHub Production:
```bash
git ls-remote origin $BRANCH
```

**If connection fails:**
→ Help troubleshoot
→ Offer to re-enter credentials

## Step 5: Create Profile File

```bash
cat > .deployment-profile.json << EOF
{
  "version": "1.0",
  "name": "$(basename $PWD)",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "lastDeploy": null,
  "platform": "$PLATFORM",

  "build": {
    "command": "$BUILD_CMD",
    "output": "$OUTPUT",
    "nodeVersion": "20"
  },

  "$PLATFORM": {
    $PLATFORM_CONFIG
  },

  "envVars": {
    "required": [],
    "optional": [],
    "source": ".env.production"
  },

  "verification": {
    "url": "$SITE_URL",
    "healthEndpoint": "/api/health",
    "expectedStatus": 200
  },

  "history": []
}
EOF
```

## Step 6: Set Up Environment Variables

```
Would you like to configure environment variables now?

1. Yes, import from .env.production
2. Yes, enter manually
3. Skip for now (configure later)
```

If importing:
```bash
# Extract variable names from .env file
grep -E "^[A-Z_]+=" .env.production | cut -d= -f1 | while read var; do
    echo "  - $var"
done
```

## Step 7: Create Deploy Scripts (if needed)

For Azure VM and GitHub Production, offer to create deploy scripts:

```
This platform typically uses a deploy script on the server.
Would you like me to create one?

1. Yes, create scripts/deploy.sh
2. Yes, create Docker-based deployment
3. No, I have existing scripts
```

If yes, create appropriate script from templates.

## Step 8: Update .gitignore

```bash
# Add deployment-specific ignores
cat >> .gitignore << 'EOF'

# Deployment
.env.production
.env.*.local
*.pass
EOF
```

## Step 9: Test Deployment (Optional)

```
Profile created! Would you like to test the deployment now?

1. Yes, deploy to [platform]
2. No, I'll deploy later
```

If yes → Route to `workflows/deploy.md`
</process>

<platform_configs>
## Platform Configuration Templates

**Netlify:**
```json
"netlify": {
  "siteId": "",
  "siteName": "",
  "team": "",
  "forms": false,
  "functions": false,
  "functionsDir": "netlify/functions"
}
```

**Azure VM:**
```json
"azureVm": {
  "host": "",
  "user": "deployuser",
  "sshKeyPath": "~/.ssh/azure_deploy",
  "appPath": "/var/www/app",
  "deployScript": "./scripts/deploy.sh",
  "useSudo": false
}
```

**FTP:**
```json
"ftp": {
  "host": "",
  "user": "",
  "protocol": "sftp",
  "remotePath": "/public_html",
  "passive": true
}
```

**GitHub Production:**
```json
"githubProduction": {
  "branch": "production",
  "baseBranch": "main",
  "docker": {
    "enabled": true,
    "compose": true,
    "file": "docker-compose.yml"
  },
  "trigger": {
    "method": "cron",
    "schedule": "*/5 * * * *"
  }
}
```
</platform_configs>

<success_criteria>
Profile setup is complete when:
- [ ] Platform selected and confirmed
- [ ] Connection tested successfully
- [ ] Profile file created with valid JSON
- [ ] Build configuration detected/confirmed
- [ ] Environment variable requirements documented
- [ ] Deploy scripts created (if needed)
- [ ] .gitignore updated
- [ ] User informed of next steps
</success_criteria>

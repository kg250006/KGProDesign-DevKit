<overview>
Deployment profile management - creating, updating, and using project-specific deployment configurations. Profiles store deployment method, credentials references, build settings, and verification steps.
</overview>

<profile_purpose>
## Why Use Deployment Profiles

**Benefits:**
- One-command deploys after initial setup
- Consistent deployments across team members
- Self-documenting deployment process
- Easy to switch between environments
- Rollback and history tracking

**Profile lifecycle:**
```
First deploy → Create profile → Commit profile → Future deploys use profile
```
</profile_purpose>

<profile_structure>
## Profile Structure

**.deployment-profile.json:**
```json
{
  "$schema": "https://kgprodesign.dev/schemas/deployment-profile.json",
  "version": "1.0",
  "name": "my-project",
  "created": "2025-01-11T00:00:00Z",
  "lastDeploy": null,

  "platform": "netlify",

  "build": {
    "command": "npm run build",
    "output": "dist",
    "environment": {
      "NODE_ENV": "production"
    },
    "nodeVersion": "20"
  },

  "netlify": {
    "siteId": "abc123-def456",
    "siteName": "my-project",
    "team": "my-team",
    "forms": true,
    "functions": true,
    "functionsDir": "netlify/functions"
  },

  "envVars": {
    "required": ["DATABASE_URL", "API_KEY"],
    "optional": ["ANALYTICS_ID"],
    "source": ".env.production",
    "publicPrefix": ["NEXT_PUBLIC_", "VITE_"]
  },

  "verification": {
    "url": "https://my-project.netlify.app",
    "healthEndpoint": "/api/health",
    "expectedStatus": 200,
    "timeout": 30
  },

  "notifications": {
    "slack": {
      "webhook": "https://hooks.slack.com/...",
      "channel": "#deploys"
    }
  },

  "history": []
}
```

**Platform-specific sections:**

**Netlify:**
```json
{
  "netlify": {
    "siteId": "abc123",
    "siteName": "my-site",
    "team": "team-slug",
    "forms": true,
    "functions": true,
    "functionsDir": "netlify/functions",
    "redirects": true,
    "headers": true
  }
}
```

**Azure VM:**
```json
{
  "azureVm": {
    "host": "vm.azure.com",
    "user": "deployuser",
    "sshKeyPath": "~/.ssh/azure_deploy",
    "appPath": "/var/www/app",
    "deployScript": "./scripts/deploy.sh",
    "useSudo": false
  }
}
```

**FTP:**
```json
{
  "ftp": {
    "host": "ftp.example.com",
    "user": "ftpuser",
    "protocol": "sftp",
    "remotePath": "/public_html",
    "passive": true,
    "exclude": [".git", "node_modules", ".env"]
  }
}
```

**GitHub Production:**
```json
{
  "githubProduction": {
    "branch": "production",
    "baseBranch": "main",
    "triggerMethod": "push",
    "docker": {
      "enabled": true,
      "compose": true,
      "registry": "ghcr.io/myorg/myapp"
    },
    "webhook": {
      "enabled": true,
      "secret": "webhook-secret-ref"
    },
    "cron": {
      "enabled": true,
      "schedule": "*/5 * * * *"
    }
  }
}
```
</profile_structure>

<creating_profiles>
## Creating Profiles

**Auto-detection approach:**
```bash
#!/bin/bash
# detect-platform.sh

detect_platform() {
    if [ -f "netlify.toml" ]; then
        echo "netlify"
    elif [ -f ".azure/config" ] || [ -f "azure-pipelines.yml" ]; then
        echo "azure-vm"
    elif git branch -r | grep -q "production"; then
        if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
            echo "github-production"
        fi
    elif [ -f ".ftpconfig" ] || [ -f "ftp-deploy.json" ]; then
        echo "ftp"
    else
        echo "unknown"
    fi
}

PLATFORM=$(detect_platform)
echo "Detected platform: $PLATFORM"
```

**Interactive profile creation:**
```bash
# Pseudo-code for workflow
1. Detect existing indicators
2. Ask to confirm or override platform
3. Gather platform-specific details
4. Validate credentials/access
5. Test connection
6. Write profile
7. Add to .gitignore (sensitive parts)
```

**Profile templates by platform:**
```
templates/
├── deployment-profile.json      # Base template
├── netlify-profile.json         # Netlify-specific
├── azure-vm-profile.json        # Azure VM
├── ftp-profile.json             # FTP/SFTP
└── github-production-profile.json # GitHub + Docker
```
</creating_profiles>

<profile_security>
## Security Considerations

**What goes in profile (safe to commit):**
```json
{
  "platform": "netlify",
  "build": { "command": "npm run build" },
  "netlify": { "siteName": "my-site" },
  "verification": { "url": "https://my-site.com" }
}
```

**What stays separate (never commit):**
```json
// Stored in ~/.deployment-expert/credentials/
{
  "netlify": { "authToken": "..." },
  "azureVm": { "sshKeyPath": "..." },
  "ftp": { "password": "..." }
}
```

**Credential references:**
```json
{
  "credentials": {
    "type": "file",
    "path": "~/.deployment-expert/credentials/my-project.json"
  }
}
```

**.gitignore entries:**
```
# Deployment
.deployment-credentials.json
.env.production
*.pass
```
</profile_security>

<profile_usage>
## Using Profiles

**Deploy using profile:**
```bash
#!/bin/bash
# deploy-from-profile.sh

PROFILE=".deployment-profile.json"

if [ ! -f "$PROFILE" ]; then
    echo "No deployment profile found. Run setup first."
    exit 1
fi

PLATFORM=$(jq -r '.platform' "$PROFILE")
BUILD_CMD=$(jq -r '.build.command' "$PROFILE")
OUTPUT_DIR=$(jq -r '.build.output' "$PROFILE")

echo "Platform: $PLATFORM"
echo "Building with: $BUILD_CMD"

# Build
eval "$BUILD_CMD"

# Deploy based on platform
case $PLATFORM in
    netlify)
        SITE_ID=$(jq -r '.netlify.siteId' "$PROFILE")
        netlify deploy --prod --dir="$OUTPUT_DIR" --site="$SITE_ID"
        ;;
    azure-vm)
        HOST=$(jq -r '.azureVm.host' "$PROFILE")
        USER=$(jq -r '.azureVm.user' "$PROFILE")
        SCRIPT=$(jq -r '.azureVm.deployScript' "$PROFILE")
        ssh "$USER@$HOST" "cd /var/www/app && git pull && $SCRIPT"
        ;;
    ftp)
        HOST=$(jq -r '.ftp.host' "$PROFILE")
        REMOTE=$(jq -r '.ftp.remotePath' "$PROFILE")
        USER=$(jq -r '.ftp.user' "$PROFILE")
        lftp -u "$USER" "sftp://$HOST" -e "mirror -R $OUTPUT_DIR $REMOTE; quit"
        ;;
    github-production)
        BRANCH=$(jq -r '.githubProduction.branch' "$PROFILE")
        git checkout "$BRANCH"
        git merge main
        git push origin "$BRANCH"
        ;;
esac

# Update last deploy
jq '.lastDeploy = now | todate' "$PROFILE" > tmp.json && mv tmp.json "$PROFILE"

echo "Deploy complete!"
```

**Verify deployment:**
```bash
#!/bin/bash
# verify-deployment.sh

PROFILE=".deployment-profile.json"
URL=$(jq -r '.verification.url' "$PROFILE")
HEALTH=$(jq -r '.verification.healthEndpoint' "$PROFILE")
EXPECTED=$(jq -r '.verification.expectedStatus' "$PROFILE")
TIMEOUT=$(jq -r '.verification.timeout' "$PROFILE")

echo "Verifying $URL$HEALTH..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$URL$HEALTH")

if [ "$STATUS" = "$EXPECTED" ]; then
    echo "Verification passed! Status: $STATUS"
    exit 0
else
    echo "Verification failed! Expected: $EXPECTED, Got: $STATUS"
    exit 1
fi
```
</profile_usage>

<profile_history>
## Deployment History

**Track deployments:**
```json
{
  "history": [
    {
      "timestamp": "2025-01-11T14:30:00Z",
      "commit": "abc1234",
      "branch": "main",
      "status": "success",
      "duration": 45,
      "deployUrl": "https://abc1234--my-site.netlify.app"
    },
    {
      "timestamp": "2025-01-10T10:15:00Z",
      "commit": "def5678",
      "branch": "main",
      "status": "failed",
      "error": "Build failed: TypeScript errors"
    }
  ]
}
```

**Add to history:**
```bash
add_to_history() {
    local status=$1
    local commit=$(git rev-parse --short HEAD)
    local branch=$(git branch --show-current)

    jq --arg status "$status" \
       --arg commit "$commit" \
       --arg branch "$branch" \
       '.history = [{
           timestamp: now | todate,
           commit: $commit,
           branch: $branch,
           status: $status
       }] + .history[:9]' \
       "$PROFILE" > tmp.json && mv tmp.json "$PROFILE"
}
```

**View history:**
```bash
jq '.history[] | "\(.timestamp) - \(.commit) - \(.status)"' .deployment-profile.json
```
</profile_history>

<multiple_environments>
## Multiple Environments

**Environment-specific profiles:**
```
.deployment-profile.json         # Default (production)
.deployment-profile.staging.json # Staging
.deployment-profile.dev.json     # Development
```

**Or single profile with environments:**
```json
{
  "environments": {
    "production": {
      "netlify": { "siteId": "prod-site-id" },
      "verification": { "url": "https://mysite.com" }
    },
    "staging": {
      "netlify": { "siteId": "staging-site-id" },
      "verification": { "url": "https://staging.mysite.com" }
    }
  },
  "defaultEnvironment": "production"
}
```

**Deploy to specific environment:**
```bash
./deploy.sh --env staging
```
</multiple_environments>

<profile_migration>
## Migrating Between Platforms

**Change platform:**
```bash
# Backup current profile
cp .deployment-profile.json .deployment-profile.json.bak

# Update platform
jq '.platform = "azure-vm" |
    .azureVm = {
        host: "vm.azure.com",
        user: "deployuser",
        appPath: "/var/www/app"
    }' .deployment-profile.json > tmp.json && mv tmp.json .deployment-profile.json

# Remove old platform config (optional)
jq 'del(.netlify)' .deployment-profile.json > tmp.json && mv tmp.json .deployment-profile.json
```

**Keep old config for reference:**
```json
{
  "platform": "azure-vm",
  "azureVm": { ... },
  "_previousPlatforms": {
    "netlify": { "siteId": "...", "retired": "2025-01-11" }
  }
}
```
</profile_migration>

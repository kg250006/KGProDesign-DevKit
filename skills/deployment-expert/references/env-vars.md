<overview>
Cross-platform environment variable management. Covers syncing between local and production, handling secrets securely, and validating required variables before deployment.
</overview>

<env_file_structure>
## Environment File Structure

**Standard naming:**
```
.env                # Local development (git-ignored)
.env.local          # Local overrides (git-ignored)
.env.development    # Development defaults (can be committed)
.env.staging        # Staging environment
.env.production     # Production values (git-ignored, sensitive)
.env.example        # Template with placeholder values (committed)
```

**.env.example (committed to git):**
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/myapp

# External APIs
API_KEY=your-api-key-here
STRIPE_SECRET_KEY=sk_test_...

# App Configuration
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug

# Feature Flags
ENABLE_NEW_FEATURE=false
```

**.gitignore:**
```
.env
.env.local
.env.production
.env.*.local
```
</env_file_structure>

<variable_categories>
## Variable Categories

**Public (safe to expose):**
```bash
NODE_ENV=production
PORT=3000
API_URL=https://api.example.com
ENABLE_ANALYTICS=true
```

**Sensitive (never expose):**
```bash
DATABASE_URL=postgresql://...
API_SECRET_KEY=...
JWT_SECRET=...
STRIPE_SECRET_KEY=...
AWS_SECRET_ACCESS_KEY=...
```

**Build-time vs Runtime:**
```bash
# Build-time (baked into bundle)
NEXT_PUBLIC_API_URL=https://api.example.com
VITE_APP_TITLE=My App

# Runtime (read at startup)
DATABASE_URL=...
PORT=3000
```
</variable_categories>

<validation>
## Pre-Deploy Validation

**Validation script (scripts/validate-env.sh):**
```bash
#!/bin/bash
set -e

ENV_FILE=${1:-.env.production}
REQUIRED_VARS=(
    "DATABASE_URL"
    "API_KEY"
    "JWT_SECRET"
    "STRIPE_SECRET_KEY"
)

echo "Validating $ENV_FILE..."

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found"
    exit 1
fi

source "$ENV_FILE"

MISSING=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING+=("$var")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Missing required variables:"
    printf '  - %s\n' "${MISSING[@]}"
    exit 1
fi

echo "All required variables present!"
```

**Node.js validation:**
```javascript
// config/validate-env.js
const required = [
  'DATABASE_URL',
  'API_KEY',
  'JWT_SECRET',
];

const missing = required.filter(key => !process.env[key]);

if (missing.length > 0) {
  console.error('Missing required environment variables:');
  missing.forEach(key => console.error(`  - ${key}`));
  process.exit(1);
}

console.log('Environment validated successfully');
```
</validation>

<syncing>
## Syncing Environment Variables

**To Netlify:**
```bash
#!/bin/bash
# sync-to-netlify.sh

ENV_FILE=${1:-.env.production}

while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    # Remove quotes from value
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    echo "Setting $key..."
    netlify env:set "$key" "$value" --context production
done < "$ENV_FILE"

echo "Sync complete!"
```

**To Azure VM:**
```bash
#!/bin/bash
# sync-to-azure.sh

ENV_FILE=${1:-.env.production}
SERVER="user@vm.azure.com"
REMOTE_PATH="/var/www/app/.env"

# Copy file
scp "$ENV_FILE" "$SERVER:$REMOTE_PATH"

# Set permissions
ssh "$SERVER" "chmod 600 $REMOTE_PATH"

echo "Synced to $SERVER"
```

**From platform to local:**
```bash
# Netlify
netlify env:list > .env.production

# Azure (if stored in Key Vault)
az keyvault secret list --vault-name myVault --query "[].name" -o tsv | while read name; do
    value=$(az keyvault secret show --vault-name myVault --name "$name" --query value -o tsv)
    echo "${name}=${value}" >> .env.production
done
```
</syncing>

<secrets_management>
## Secrets Management

**Local secure storage:**
```bash
# Create secure directory
mkdir -p ~/.deployment-expert/secrets
chmod 700 ~/.deployment-expert/secrets

# Store per-project secrets
echo "sk_live_..." > ~/.deployment-expert/secrets/myapp-stripe.txt
chmod 600 ~/.deployment-expert/secrets/myapp-stripe.txt
```

**Platform-specific secrets:**
```bash
# Netlify - via CLI
netlify env:set STRIPE_SECRET_KEY "$(cat ~/.deployment-expert/secrets/myapp-stripe.txt)"

# Azure Key Vault
az keyvault secret set --vault-name myVault --name stripe-secret --file ~/.deployment-expert/secrets/myapp-stripe.txt

# GitHub Secrets (via gh CLI)
gh secret set STRIPE_SECRET_KEY < ~/.deployment-expert/secrets/myapp-stripe.txt
```

**Never do:**
```bash
# DON'T commit secrets to git
# DON'T log secret values
# DON'T pass secrets as command args (visible in ps)
# DON'T store in unencrypted files in repo
```
</secrets_management>

<per_environment>
## Per-Environment Configuration

**Profile-based loading:**
```json
// .deployment-profile.json
{
  "envVars": {
    "required": ["DATABASE_URL", "API_KEY", "JWT_SECRET"],
    "optional": ["ANALYTICS_ID", "SENTRY_DSN"],
    "mappings": {
      "local": ".env.local",
      "staging": ".env.staging",
      "production": ".env.production"
    },
    "publicPrefix": ["NEXT_PUBLIC_", "VITE_"],
    "buildTime": ["NEXT_PUBLIC_API_URL", "VITE_APP_VERSION"],
    "runtime": ["DATABASE_URL", "API_KEY"]
  }
}
```

**Load correct env for deploy:**
```bash
#!/bin/bash
# In deploy workflow

ENVIRONMENT=${1:-production}
PROFILE=".deployment-profile.json"

# Get env file path from profile
ENV_FILE=$(jq -r ".envVars.mappings.$ENVIRONMENT" "$PROFILE")

if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file not found: $ENV_FILE"
    exit 1
fi

# Validate and deploy
./scripts/validate-env.sh "$ENV_FILE"
./scripts/sync-env.sh "$ENV_FILE"
```
</per_environment>

<docker_env>
## Docker Environment Variables

**docker-compose.yml:**
```yaml
services:
  app:
    image: myapp:latest
    env_file:
      - .env.production
    environment:
      # Override or add specific vars
      - NODE_ENV=production
      - LOG_LEVEL=info
```

**Build-time args:**
```dockerfile
# Dockerfile
ARG NODE_ENV=production
ARG API_URL

ENV NODE_ENV=$NODE_ENV
ENV API_URL=$API_URL
```

```bash
docker build \
  --build-arg NODE_ENV=production \
  --build-arg API_URL=https://api.example.com \
  -t myapp .
```

**Runtime injection:**
```bash
docker run -d \
  --env-file .env.production \
  -e EXTRA_VAR=value \
  myapp
```
</docker_env>

<ci_cd_env>
## CI/CD Environment Variables

**GitHub Actions:**
```yaml
env:
  NODE_ENV: production

jobs:
  deploy:
    environment: production
    steps:
      - name: Build
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          API_KEY: ${{ secrets.API_KEY }}
        run: npm run build
```

**Netlify CI:**
```toml
# netlify.toml
[build.environment]
  NODE_VERSION = "20"
  # Sensitive vars set in Netlify dashboard
```

**Azure Pipelines:**
```yaml
variables:
  - group: production-secrets
  - name: NODE_ENV
    value: production

steps:
  - script: npm run build
    env:
      DATABASE_URL: $(DATABASE_URL)
```
</ci_cd_env>

<troubleshooting>
## Troubleshooting

**Variable not available:**
```bash
# Check if set
echo $VAR_NAME
printenv | grep VAR_NAME

# Check .env file syntax
cat -A .env  # Shows hidden chars

# Common issues:
# - Spaces around = (VAR = value is wrong)
# - Missing export (for shell scripts)
# - Wrong file loaded
```

**Build vs runtime confusion:**
```bash
# NEXT_PUBLIC_ and VITE_ are build-time only
# They get baked into the bundle
# Changing them requires rebuild

# Runtime vars need server restart
pm2 restart app
docker compose restart app
```

**Escaping special characters:**
```bash
# Use single quotes for special chars
DATABASE_URL='postgresql://user:p@ss!word@host:5432/db'

# Or escape
DATABASE_URL=postgresql://user:p\@ss\!word@host:5432/db
```
</troubleshooting>

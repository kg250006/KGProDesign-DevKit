---
name: deployment-expert
description: Deploy projects to any platform - Netlify, Azure VM (SSH/CLI), FTP servers, GitHub production branches with Docker. Auto-detects deployment profiles, manages environment variables, handles forms and build configs. Use when deploying, setting up hosting, or managing production environments.
---

<essential_principles>
## How Deployment Works

**The skill auto-detects deployment method from project profile, or creates one on first deploy.**

### 1. Profile-First Deployment

Every project gets a `.deployment-profile.json` in its root that defines:
- Platform (netlify, azure-vm, ftp, github-production)
- Connection details (site ID, VM address, FTP host, branch name)
- Build commands and output directory
- Environment variable mappings
- Post-deploy verification steps

Once created, subsequent deploys are one-command: detect profile → execute → verify.

### 2. Global vs Project Config

**Global config** (`~/.deployment-expert/`):
- Account credentials (Netlify tokens, Azure subscriptions, FTP credentials)
- SSH keys and connection profiles
- Default settings

**Project config** (`.deployment-profile.json`):
- Platform selection
- Build configuration
- Environment variable mappings
- Deploy hooks

Global handles "who am I", project handles "how to deploy this".

### 3. Verify Every Deploy

Never assume success. Every deployment verifies:
```
Deploy → Wait for propagation → Check live site → Report status
```

Verification includes:
- HTTP status check
- Build output validation
- Environment variable confirmation (non-sensitive)
- Form functionality (if applicable)

### 4. Environment Variable Safety

Production variables are sensitive. The skill:
- Never logs secret values
- Syncs from `.env.production` to platform
- Validates required vars exist before deploy
- Reports which vars are set without exposing values

### 5. Modular Platform Support

Each platform is a self-contained module:
- `references/netlify.md` - Netlify CLI expertise
- `references/azure-vm.md` - SSH and Azure CLI deployment
- `references/ftp.md` - FTP/SFTP deployment
- `references/github-production.md` - Branch-based Docker deployment

Adding a new platform = adding a new reference file + workflow additions.
</essential_principles>

<intake>
**Ask the user:**

What would you like to do?
1. Deploy this project
2. Set up deployment profile (first-time setup)
3. Manage environment variables
4. Check deployment status
5. Troubleshoot deployment issues
6. Connect/configure account (Netlify, Azure, FTP)
7. Set up VM auto-deploy (cron-based git monitoring)
8. Run post-deploy health checks

**Then read the matching workflow and follow it.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "deploy", "push", "ship", "publish" | `workflows/deploy.md` |
| 2, "setup", "profile", "configure", "first" | `workflows/setup-profile.md` |
| 3, "env", "variables", "secrets", "config" | `workflows/manage-env-vars.md` |
| 4, "status", "check", "verify" | `workflows/check-status.md` |
| 5, "trouble", "fix", "debug", "broken", "failed", "502", "error" | `workflows/troubleshoot.md` |
| 6, "connect", "account", "auth", "login" | `workflows/connect-account.md` |
| 7, "auto-deploy", "cron", "vm setup", "git monitoring" | `workflows/vm-auto-deploy-setup.md` |
| 8, "health", "post-deploy", "verify deployment" | `workflows/post-deploy-health.md` |

**Platform auto-detection:**
- If `.deployment-profile.json` exists → read platform, route to platform-specific reference
- If `netlify.toml` exists → suggest Netlify profile
- If repo has `production` branch → suggest GitHub Production profile
- If `.azure/` or `azure-pipelines.yml` exists → suggest Azure VM profile
- Otherwise → ask user which platform
</routing>

<platform_detection>
## Auto-Detection Logic

Check in order:
1. `.deployment-profile.json` - Explicit profile (use it)
2. `netlify.toml` - Netlify project
3. `vercel.json` - Suggest Netlify alternative or add Vercel module
4. `.azure/`, `azure-pipelines.yml` - Azure project
5. `production` branch + `Dockerfile` - GitHub Production pattern
6. `docker-compose.yml` + remote server config - Docker deployment
7. `.ftpconfig`, `ftp-deploy.json` - FTP project
8. Ask user

When suggesting, explain why:
"I see `netlify.toml` in your project. This looks like a Netlify deployment. Should I set up the profile for Netlify?"
</platform_detection>

<quick_reference>
## CLI Quick Reference

**Netlify:**
```bash
netlify login                    # Auth (once)
netlify link                     # Connect to site
netlify deploy --prod            # Production deploy
netlify env:set KEY "value"      # Set env var
netlify forms:list               # Check forms
```

**Azure VM (SSH):**
```bash
ssh user@vm.azure.com "cd /app && git pull && ./deploy.sh"
az vm run-command invoke --name vmname --command-id RunShellScript --scripts "./deploy.sh"
```

**FTP:**
```bash
lftp -u user,pass -e "mirror -R ./dist /public_html; quit" ftp.host.com
ncftp -u user -p pass ftp.host.com  # Interactive
```

**GitHub Production:**
```bash
git checkout production
git merge main
git push origin production       # Triggers deployment via cron/webhook
```
</quick_reference>

<profile_schema>
## Deployment Profile Structure

```json
{
  "version": "1.0",
  "platform": "netlify|azure-vm|ftp|github-production",
  "created": "2025-01-11T00:00:00Z",
  "lastDeploy": "2025-01-11T00:00:00Z",

  "build": {
    "command": "npm run build",
    "output": "dist",
    "nodeVersion": "20"
  },

  "netlify": {
    "siteId": "site-id-here",
    "siteName": "my-site",
    "team": "team-slug",
    "forms": true,
    "functions": false
  },

  "azureVm": {
    "host": "vm.azure.com",
    "user": "deploy",
    "keyPath": "~/.ssh/azure_deploy",
    "appPath": "/var/www/app",
    "deployScript": "./deploy.sh"
  },

  "ftp": {
    "host": "ftp.host.com",
    "user": "ftpuser",
    "remotePath": "/public_html",
    "protocol": "sftp|ftp"
  },

  "githubProduction": {
    "branch": "production",
    "dockerCompose": true,
    "deployScript": "./scripts/deploy.sh",
    "cronTrigger": true
  },

  "envVars": {
    "required": ["DATABASE_URL", "API_KEY"],
    "optional": ["ANALYTICS_ID"],
    "mappings": {
      "local": ".env.local",
      "production": ".env.production"
    }
  },

  "verification": {
    "url": "https://mysite.com",
    "healthEndpoint": "/api/health",
    "expectedStatus": 200
  }
}
```
</profile_schema>

<reference_index>
## Platform Knowledge

All in `references/`:

**Platforms:**
- netlify.md - Netlify CLI, forms, functions, env vars
- azure-vm.md - SSH deployment, Azure CLI, deploy scripts
- ftp.md - FTP/SFTP deployment for PHP/static sites
- github-production.md - Branch-based Docker deployment with cron

**Cross-Platform:**
- env-vars.md - Environment variable management patterns
- verification.md - Post-deploy verification strategies
- profiles.md - Profile creation and management
</reference_index>

<workflows_index>
## Workflows

All in `workflows/`:

| File | Purpose |
|------|---------|
| deploy.md | Execute deployment based on profile |
| setup-profile.md | Create deployment profile for new project |
| manage-env-vars.md | Sync and manage environment variables |
| check-status.md | Verify deployment status and health |
| troubleshoot.md | Debug failed deployments (includes VM/Docker issues) |
| connect-account.md | Set up platform credentials |
| vm-auto-deploy-setup.md | **NEW:** Set up cron-based git monitoring auto-deploy |
| post-deploy-health.md | **NEW:** Comprehensive post-deploy health checks with NPM reload |
</workflows_index>

<templates_index>
## Templates

All in `templates/`:

**Profiles:**
| File | Purpose |
|------|---------|
| deployment-profile.json | Base profile structure |
| netlify-profile.json | Netlify-specific profile |
| azure-vm-profile.json | Azure VM profile |
| ftp-profile.json | FTP deployment profile |
| github-production-profile.json | GitHub production branch profile |

**Docker/VM Templates (NEW):**
| File | Purpose |
|------|---------|
| docker-compose.prod.template.yml | Production Docker Compose with health checks, NPM network |
| Dockerfile.backend.template | Python/FastAPI backend with 127.0.0.1 health check |
| Dockerfile.frontend.template | Next.js frontend with standalone mode, 127.0.0.1 health check |
| validate-deployment.sh.template | Pre-deployment validation script |
| operations-runbook.template.md | VM operations manual template |
</templates_index>

<success_criteria>
A successful deployment:
- Profile exists and is valid
- Build completes without errors
- Files transferred to platform
- Environment variables verified
- Live site responds correctly
- User notified of deployment URL and status
- **For VM/Docker:** NPM reloaded after container rebuild
</success_criteria>

<critical_gotchas>
## Critical Gotchas (Must Know!)

These are battle-tested lessons from production incidents. Memorize them.

### Priority 0: Always Read the Runbook First
When entering any VM for deployment or troubleshooting:
```bash
cat /opt/containers/OPERATIONS-RUNBOOK.md
```
This is the source of truth for that VM's specific procedures.

### Priority 1: Never Run Cron Jobs with Sudo
```bash
# WRONG - root can't access deploy user's SSH keys
sudo /opt/cron/jobs/auto-deploy.sh

# CORRECT - run as deploy user
/opt/cron/jobs/auto-deploy.sh
```

### Priority 2: Always Reload NPM After Container Rebuilds
```bash
# This fixes 502 Bad Gateway after deploy
docker exec nginx-proxy-manager nginx -s reload
```
NPM caches container IPs. After rebuild, containers get new IPs.

### Priority 3: Use 127.0.0.1 NOT localhost in Health Checks
```dockerfile
# WRONG - may resolve to IPv6 (::1)
HEALTHCHECK CMD curl http://localhost:3000/health

# CORRECT - explicit IPv4
HEALTHCHECK CMD curl http://127.0.0.1:3000/health
```

### Priority 4: Logrotate Creates Files as Root
```
# In /etc/logrotate.d/{app}, specify ownership:
create 0664 {deploy-user} {deploy-user}
```
Otherwise deploy user can't write to rotated log.

### Priority 5: Use SSH Deploy Keys, NOT Personal Access Tokens
- Deploy keys are repository-specific (more secure)
- No expiration issues
- Won't be leaked in logs
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
# Add public key to GitHub repo settings → Deploy keys
```

### Priority 6: PostgreSQL Boolean Defaults
```python
# WRONG - PostgreSQL rejects
server_default=sa.text("0")

# CORRECT
server_default=sa.text("false")
```

### Priority 7: stat Command Differs Between Linux/macOS
```bash
# Linux
stat -c %Y file.txt

# macOS
stat -f %m file.txt
```
Scripts should handle both.

### Priority 8: Docker Compose v1 vs v2
```bash
# Old (v1) - deprecated
docker-compose up

# New (v2) - use this
docker compose up
```

### Priority 9: Avoid Port Clashes - Use Docker DNS Instead
```yaml
# WRONG - Exposes ports to host, causes clashes with other apps
services:
  backend:
    ports:
      - "8000:8000"  # Will clash if another app uses 8000
  frontend:
    ports:
      - "3000:3000"  # Will clash if another app uses 3000

# CORRECT - No host ports, use NPM with Docker DNS
services:
  backend:
    # No ports exposed - NPM routes via container name
    networks:
      - npm-network
  frontend:
    networks:
      - npm-network

# NPM proxy host config:
# Forward hostname: {app}-backend-prod (Docker DNS name)
# Forward port: 8000 (internal container port)
```

**Why this matters:**
- Multiple apps on same VM will clash if they all expose port 3000, 8000, etc.
- Docker DNS lets NPM route to containers by name without host port binding
- Each app can use the same internal ports (3000, 8000) without conflict
- Only NPM exposes ports 80/443 to the outside world

**Check for port conflicts:**
```bash
# See what's using ports on host
sudo netstat -tlnp | grep -E ":(80|443|3000|8000|5432)"
# Or
sudo ss -tlnp | grep -E ":(80|443|3000|8000|5432)"

# Check Docker port bindings
docker ps --format '{{.Names}}: {{.Ports}}'
```
</critical_gotchas>

<vm_quick_commands>
## VM Quick Commands

**Fix 502 Bad Gateway:**
```bash
docker exec nginx-proxy-manager nginx -s reload
```

**Check auto-deploy status:**
```bash
tail -50 /opt/cron/logs/{app}-deploy.log
cat /opt/cron/state/{app}-failures  # Failure count
```

**Reset circuit breaker:**
```bash
echo 0 > /opt/cron/state/{app}-failures
```

**Free disk space:**
```bash
docker system prune -af && journalctl --vacuum-time=7d
```

**Full health check:**
```bash
docker ps | grep {app} && curl -sf https://{domain}/api/health && df -h / | tail -1
```
</vm_quick_commands>

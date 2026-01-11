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

**Then read the matching workflow and follow it.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "deploy", "push", "ship", "publish" | `workflows/deploy.md` |
| 2, "setup", "profile", "configure", "first" | `workflows/setup-profile.md` |
| 3, "env", "variables", "secrets", "config" | `workflows/manage-env-vars.md` |
| 4, "status", "check", "verify" | `workflows/check-status.md` |
| 5, "trouble", "fix", "debug", "broken", "failed" | `workflows/troubleshoot.md` |
| 6, "connect", "account", "auth", "login" | `workflows/connect-account.md` |

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
| troubleshoot.md | Debug failed deployments |
| connect-account.md | Set up platform credentials |
</workflows_index>

<templates_index>
## Templates

All in `templates/`:

| File | Purpose |
|------|---------|
| deployment-profile.json | Base profile structure |
| netlify-profile.json | Netlify-specific profile |
| azure-vm-profile.json | Azure VM profile |
| ftp-profile.json | FTP deployment profile |
| github-production-profile.json | GitHub production branch profile |
</templates_index>

<success_criteria>
A successful deployment:
- Profile exists and is valid
- Build completes without errors
- Files transferred to platform
- Environment variables verified
- Live site responds correctly
- User notified of deployment URL and status
</success_criteria>

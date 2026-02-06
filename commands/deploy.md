---
name: deploy
description: Deploy project using deployment-expert skill. Supports Netlify, Azure VM, FTP, and GitHub production branch deployments.
argument-hint: [ship|status|setup|env|troubleshoot]
allowed-tools: Skill(deployment-expert), Read, Bash, Grep, Glob, Write, Edit, Task
---

Invoke the deployment-expert skill for: $ARGUMENTS

## Smart Routing

**For existing Azure VM apps** (has `.deployment-profile.json` with `platform: "azure-vm"`):

If user says "ship", "deploy", or no arguments:
→ Route directly to `workflows/azure-vm-ship.md`
→ Fast path: commit → PR to production → SSH monitor → verify

**For new apps or explicit setup:**
→ Full skill intake menu

## Common Invocations

### Fast Path (Existing Apps)
- `/deploy` - Ship to production (commit, PR, merge, monitor)
- `/deploy ship` - Same as above, explicit
- `/deploy monitor` - SSH to VM and watch deployment logs

### Setup & Config
- `/deploy setup` - Set up deployment profile (first-time)
- `/deploy env` - Manage environment variables
- `/deploy status` - Check deployment status

### Troubleshooting
- `/deploy troubleshoot` - Debug deployment issues
- `/deploy health` - Run post-deploy health checks

## Philosophy (Azure VM)

1. **Monitor, don't intervene** - Let auto-deploy do its job
2. **Only intervene on failure** - Then fix the codebase, not the VM
3. **Never modify database directly** - All changes through migrations
4. **Migrations must complete** - Deployment isn't done until migrations run

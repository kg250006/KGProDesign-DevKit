---
name: deploy
description: Deploy project using deployment-expert skill (Netlify, Azure VM, FTP, GitHub production branch), or the kgp-hosting skill when the repo has kgp.toml.
argument-hint: [ship|status|setup|env|troubleshoot]
allowed-tools: Skill(deployment-expert), Skill(kgp-hosting), Read, Bash, Grep, Glob, Write, Edit, Task
---

Invoke the deployment-expert skill for: $ARGUMENTS

Check the routing below first. A repo with `kgp.toml` goes to the kgp-hosting skill instead.

## Smart Routing

**For KGP Host sites** (has `kgp.toml` at the repo root or a parent folder up to the git root):
→ Invoke the `kgp-hosting` skill instead of deployment-expert, and follow its prerequisites and guardrails
→ "ship" or "deploy" means a draft release (`kgp deploy --json --yes`); publish only when the user asks for production

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

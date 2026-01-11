---
name: deploy
description: Deploy project using deployment-expert skill. Supports Netlify, Azure VM, FTP, and GitHub production branch deployments.
argument-hint: [platform|status|setup|env]
allowed-tools: Skill(deployment-expert), Read, Bash, Grep, Glob, Write, Edit
---

Invoke the deployment-expert skill for: $ARGUMENTS

If no arguments provided, the skill will detect the deployment profile and proceed with deployment.

Common invocations:
- `/deploy` - Deploy using existing profile
- `/deploy setup` - Set up deployment profile
- `/deploy status` - Check deployment status
- `/deploy env` - Manage environment variables
- `/deploy troubleshoot` - Debug deployment issues

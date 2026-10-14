# KGProDesign-DevKit Installation Guide

## Local Installation

Install this plugin directly from your local filesystem using Claude Code's plugin manager.

### Prerequisites

- Claude Code installed (`npm install -g @anthropic-ai/claude-code`)
- Git installed on your machine
- Python 3 (the hooks and the static-validation suite use it)

Optional, per feature:

- **Desktop tools:** `pip install -r requirements.txt` in `tools/CronLike/` and `tools/MouseJiggler/`.
- **KGP Host (`kgp-hosting` skill):** Node 20+, pnpm 9, and the `kgp` CLI on PATH, built from the KGP-WebHosting-Tools repo. Check with `kgp --version` and `kgp whoami --json`.

### Installation Steps

#### Step 1: Clone the Repository

First, clone the KGProDesign-DevKit repository to your local machine:

```bash
# Navigate to where you want to store the plugin
cd ~/PROJECTS  # or your preferred directory

# Clone the repository
git clone https://github.com/kg250006/KGProDesign-DevKit.git

# Verify the clone was successful
ls KGProDesign-DevKit
```

You should see the plugin structure including `agents/`, `commands/`, `skills/`, and `.claude-plugin/`.

#### Step 2: Add the Marketplace to Claude Code

Open Claude Code and run the `/plugin` command with the path to your cloned repository:

```
/plugin marketplace add /path/to/KGProDesign-DevKit
```

**Examples by OS:**

macOS:
```
/plugin marketplace add /Users/yourusername/PROJECTS/KGProDesign-DevKit
```

Linux:
```
/plugin marketplace add /home/yourusername/PROJECTS/KGProDesign-DevKit
```

Windows (WSL):
```
/plugin marketplace add /mnt/c/Users/yourusername/PROJECTS/KGProDesign-DevKit
```

You should see: `Successfully added marketplace: KGP`

#### Step 3: Install the Plugin

1. Run `/plugin` to open the plugin manager
2. Navigate to the **Discover** tab
3. Find **KGP** and install it

#### Step 4: Verify Installation

```
/plugin
```
Navigate to the **Installed** tab to confirm KGP is listed and enabled.

---

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Agents | 12 | Frontend, Backend, Data, QA, DevOps, Docs, Project Coordinator, Dev Engineer + 4 auditors |
| Commands | 30 | PRP workflow (create/validate/execute), debugging, plugin authoring, Agent Teams, communication style, desktop tools |
| Skills | 21 | Reusable knowledge modules for development, design, deployment, KGP Host, and business tasks |
| Hooks | 3 | Auto-invocation hooks (UserPromptSubmit, SessionStart, PostToolUse) |
| Tools | 2 | Standalone desktop utilities: CronLike scheduler and MouseJiggler |

---

## Quick Start

After installation, prime your context:
```
/KGP:context-prime
```

Or start with the help command:
```
/KGP:help
```

---

## Updating

To update the plugin after pulling new changes:

1. Pull the latest changes:
   ```bash
   cd /path/to/KGProDesign-DevKit
   git pull
   ```

2. Restart Claude Code or run `/plugin` to refresh.

### When `/plugin update` appears to do nothing

The plugin cache is keyed by version (`~/.claude/plugins/cache/KGP/KGP/<version>/`). If content was pushed without bumping `version` in `.claude-plugin/plugin.json`, the updater has no new directory to resolve to and silently no-ops. Your installed copy stays on the old content and nothing reports an error.

To force a refresh:

```bash
/plugin uninstall KGP@KGP
rm -rf ~/.claude/plugins/cache/KGP/KGP/<version>/
/plugin install KGP@KGP
```

Substitute the version you currently have installed for `<version>`. On Windows PowerShell, use `Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\plugins\cache\KGP\KGP\<version>\"` for the middle step.

The durable fix is to bump the version with every content change, which is why every release in CHANGELOG.md carries one.

---

## Uninstalling

1. Run `/plugin`
2. Navigate to the **Installed** tab
3. Select **KGP** and choose **Uninstall**

To remove the marketplace:
```
/plugin marketplace remove KGP
```

---

## Troubleshooting

### Plugin not appearing in Discover tab
- Verify the path is correct and accessible
- Check `/plugin` → **Errors** tab for loading issues
- Ensure `plugin.json` exists in `.claude-plugin/` directory

### Commands not working
- Confirm the plugin is enabled in the **Installed** tab
- Restart Claude Code session
- Run `/KGP:help` to verify available commands

### Permission errors
- Ensure you have read access to the plugin directory
- Check file permissions: `ls -la /path/to/KGProDesign-DevKit`

---

## Remote Installation

The repository is public, so you can install directly from GitHub:
```
/plugin marketplace add kg250006/KGProDesign-DevKit
```

---

## Support

- Repository: https://github.com/kg250006/KGProDesign-DevKit
- Issues: https://github.com/kg250006/KGProDesign-DevKit/issues

# KGProDesign-DevKit Installation Guide

## Local Installation

Install this plugin directly from your local filesystem using Claude Code's plugin manager.

### Prerequisites

- Claude Code installed (`npm install -g @anthropic-ai/claude-code`)
- Git installed on your machine

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
   ```
   /plugin marketplace add /path/to/KGProDesign-DevKit
   ```

   Example:
   ```
   /plugin marketplace add /Users/username/PROJECTS/KGProDesign-DevKit
   ```

3. **Install the plugin**:
   - Run `/plugin` to open the plugin manager
   - Navigate to the **Discover** tab
   - Find **KGP** and install it

4. **Verify installation**:
   ```
   /plugin
   ```
   Navigate to the **Installed** tab to confirm KGP is listed and enabled.

---

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Agents | 8 | Frontend, Backend, Data, QA, DevOps, Docs, Project Coordinator, Config Auditor |
| Commands | 26 | Including Ralph Loop, PRP workflow, debugging, and creation toolkit |
| Skills | 16 | Reusable knowledge modules for development tasks |
| Hooks | 2 | Event-driven automation |

---

## Quick Start

After installation, prime your context:
```
/SG-STAC:context-prime
```

Or start with the help command:
```
/SG-STAC:help
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
- Run `/SG-STAC:help` to verify available commands

### Permission errors
- Ensure you have read access to the plugin directory
- Check file permissions: `ls -la /path/to/KGProDesign-DevKit`

---

## Remote Installation (Future)

Once the repository is public, install directly from GitHub:
```
/plugin marketplace add kg250006/KGProDesign-DevKit
```

---

## Support

- Repository: https://github.com/kg250006/KGProDesign-DevKit
- Issues: https://github.com/kg250006/KGProDesign-DevKit/issues

# KGProDesign-DevKit

Universal Claude Code development toolkit for any project.

## Why Use This Plugin

- **Unified Foundation** - Every developer starts with identical tools, workflows, and guidelines
- **Focused Agents** - 12 agents (7 engineering + 4 auditors + 1 workflow orchestrator) covering all development categories
- **Essential Commands** - 30 commands for efficient workflows
- **Native PRP Execution** - Spec-driven development in a single long-running session, no external scripts
- **Design-First Frontend** - Website PRPs include design-token phases and visual QA gates
- **Tunable Communication** - Install a per-project rule so replies stay concise and plainly worded, personal and git-excluded by default

## Installation

### Prerequisites

- **Claude Code CLI** installed and configured
- **GitHub Access** - Clone or download the repository

### Recommended: Plugin Manager Install

```bash
claude
/plugin marketplace add kg250006/KGProDesign-DevKit
/plugin install KGP@KGP
```

### Alternative: Manual Install

```bash
git clone https://github.com/kg250006/KGProDesign-DevKit.git
mkdir -p ~/.claude/plugins
cp -r KGProDesign-DevKit ~/.claude/plugins/
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\plugins"
Copy-Item -Recurse KGProDesign-DevKit "$env:USERPROFILE\.claude\plugins\"
```

### Verification

```bash
claude
/KGP:help  # Should explain the plugin and its commands
```

### Updating the Plugin

```bash
cd /path/to/your/KGProDesign-DevKit
git pull origin main
# Then re-copy (manual install) or /plugin update (plugin manager)
```

## Quick Start (5 Minutes)

### 1. Initialize Context
```bash
claude
/KGP:context-prime
```

### 2. Create Your First PRP
```bash
/KGP:prp-create "Add user authentication"
```

### 3. Validate & Execute the PRP
```bash
/KGP:prp-validate PRPs/PRP-user-auth.md
/KGP:prp-execute PRPs/PRP-user-auth.md
```

## Available Agents

### Engineering (7)

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| `frontend-engineer` | UI/UX and component development | React, Vue, styling, accessibility |
| `backend-engineer` | API and service development | REST, GraphQL, business logic |
| `data-engineer` | Database and data layer | Schema, migrations, queries |
| `qa-engineer` | Testing and code review | Unit tests, E2E, security |
| `project-coordinator` | Project management | Sprint planning, task breakdown |
| `document-specialist` | Documentation | PRDs, PRPs, technical docs |
| `devops-engineer` | Infrastructure | CI/CD, Docker, deployment |

### Auditors (4)

| Agent | Purpose |
|-------|---------|
| `config-auditor` | Plugin config validation |
| `skill-auditor` | Skill audits |
| `slash-command-auditor` | Slash command audits |
| `subagent-auditor` | Subagent audits |

## Available Commands

### PRP Workflow
- `/KGP:prp-create` - Generate Product Requirement Prompt with intent-lock + decision-log
- `/KGP:prp-validate` - Pre-flight PRP validation with auto-fix
- `/KGP:prp-execute <prp.md> [<prp2.md> ...]` - Execute one or more PRPs end-to-end in a single native Claude Code session

### Agent Teams (Experimental)
- `/KGP:team-invoke "<task>"` - Spawn a 3–5 teammate Agent Team (recipe auto-picked)
- `/KGP:prp-execute <prp> --team[=<recipe>]` - Run a PRP with auto-partitioned team

### Project & Deployment
- `/KGP:context-prime` - Initialize project context
- `/KGP:deploy` - Deploy via deployment-expert skill (Netlify, Azure VM, FTP, GitHub), or via the kgp-hosting skill when the repo has `kgp.toml`
- `/KGP:run-regression` - Automated regression testing
- `/KGP:comm-style` - Set up, review, or tweak this project's communication style (`.claude/rules/`, personal by default, never committed unless you say so)
- `/KGP:help` - Plugin overview

### Desktop Tools (tools/)
- `/KGP:tools:status` - Install path, dependency health, and running state for both desktop tools
- `/KGP:tools:cron` - Start, stop, inspect, autostart, or hand-fire CronLike jobs
- `/KGP:tools:schedule` - Add, edit, enable, disable, or remove a CronLike job, scoped to the current project
- `/KGP:tools:jiggler` - Start, stop, inspect, or autostart the Mouse Jiggler

### Plugin Authoring & Audits (core/)
- `/KGP:core:create-hook` - Configure Claude Code hooks
- `/KGP:core:create-subagent` - Create specialized subagents
- `/KGP:core:create-slash-command` - Create slash commands
- `/KGP:core:create-agent-skill` - Create Claude Code skills
- `/KGP:core:create-meta-prompt` - Create multi-stage prompts
- `/KGP:core:audit-skill` / `audit-slash-command` / `audit-subagent` - Best-practice audits
- `/KGP:core:heal-skill` - Apply corrections discovered during execution

### Daily Workflow (dev/)
- `/KGP:dev:debug` - Expert debugging
- `/KGP:dev:create-plan` - Hierarchical project plans
- `/KGP:dev:run-plan` - Execute a PLAN.md
- `/KGP:dev:create-prompt` / `run-prompt` - Meta-prompting to fresh contexts
- `/KGP:dev:add-to-todos` / `check-todos` - Todo management
- `/KGP:dev:whats-next` - Context handoff document

## Directory Structure

```
~/.claude/plugins/KGProDesign-DevKit/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── agents/           # 12 specialized agents
├── commands/         # 30 commands (top-level + core/ + dev/ + tools/)
├── hooks/            # Auto-invocation hooks (hooks.json)
├── skills/           # 21 skills (PRP, design, deployment, KGP Host, testing, communication, business, desktop tools)
├── scripts/
│   ├── hooks/            # Hook scripts
│   └── tests/            # Static-validation suite
├── templates/
│   ├── prp_base.md       # XML PRP template
│   ├── prp_planning.md   # PRD generation template
│   └── frameworks/       # Tech stack CLAUDE.md templates
├── tools/            # Standalone desktop utilities (not slash commands)
├── CLAUDE.md         # Reference guide
├── CHANGELOG.md      # Version history
└── README.md         # This file
```

## Tools

Standalone desktop utilities that ship with the plugin. These are ordinary programs you run yourself: not slash commands, not agent orchestration.

| Tool | What it does |
|------|--------------|
| [MouseJiggler](tools/MouseJiggler/README.md) | Keeps the machine awake. Tray icon, Windows and macOS. |
| [CronLike](tools/CronLike/README.md) | Runs commands on a human-readable JSON schedule. Tray icon, Windows and macOS. Configuration reference in [SCHEDULE.md](tools/CronLike/SCHEDULE.md). |

Each has its own README with install and usage instructions. Both are Python and need `pip install -r requirements.txt` in their own directory.

Control them from any project with the `/KGP:tools:*` commands above, or just describe what you want and the `desktop-tools` skill routes it. Autostart at login survives plugin updates: the Startup entry points at a stable shim in `~/.kgp-tools/` that resolves the plugin at launch time, never a version-stamped path.

## KGP Host

The `kgp-hosting` skill deploys, publishes, rolls back, and diagnoses sites on KGP Host through the `kgp` CLI. It activates in any repo with a `kgp.toml` and never publishes to production unless asked.

Prerequisite: the `kgp` CLI on PATH (`kgp --version`), built from the KGP-WebHosting-Tools repo, plus a logged-in hosting instance (`kgp whoami --json`). The skill's `<prerequisites>` section has the steps. The skill's source lives in KGP-WebHosting-Tools; copy changes here with that repo's `scripts/install-skill.sh --devkit PATH`.

## Framework Templates

Pre-built CLAUDE.md templates for common tech stacks. Copy to your project root:

```bash
# For Next.js 15 projects
cp templates/frameworks/CLAUDE-NEXTJS-15.md /your/project/CLAUDE.md

# For Python FastAPI projects
cp templates/frameworks/CLAUDE-PYTHON-BASIC.md /your/project/CLAUDE.md
```

Available templates:
- **CLAUDE-NEXTJS-15.md** - Next.js 15 + React 19 + TypeScript
- **CLAUDE-REACT.md** - React 19 + TypeScript (Vite)
- **CLAUDE-ASTRO.md** - Astro 5 + Islands Architecture
- **CLAUDE-NODE.md** - Node.js 23 + Fastify
- **CLAUDE-PYTHON-BASIC.md** - Python + FastAPI + UV
- **CLAUDE-JAVA-GRADLE.md** - Java 21 + Spring Boot + Gradle
- **CLAUDE-JAVA-MAVEN.md** - Java 21 + Spring Boot + Maven

## Native Long-Run Execution

`/KGP:prp-execute` runs PRPs end-to-end in a single native Claude Code session. With 1M-context-capable models (Sonnet 5, Opus 4.8, or Fable 5 on a plan tier that supports it) and Auto mode, multi-thousand-line PRPs and multi-PRP queues execute without external orchestration.

```bash
/KGP:prp-execute PRPs/PRP-feature.md
/KGP:prp-execute PRPs/PRP-foundation.md PRPs/PRP-core.md
```

For multi-hour runs: start locally, then monitor from claude.ai/code or the mobile app via remote control.

See https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents for Anthropic's harness design guidance.

## Agent Teams (Experimental)

Parallel 3–5 teammate execution. Enable in `settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Then restart Claude Code. Commands:

```bash
/KGP:team-invoke "review PR #42 for auth changes"   # auto-picks `review` recipe
/KGP:prp-execute PRPs/feature.md --team             # auto-picks + partitions tasks
```

Recipes: `implementation`, `review`, `research`, `hypothesis`. Classifier + disambiguation rules live in `skills/agent-teams/references/playbooks.md`.

## Documentation

- [CLAUDE.md](./CLAUDE.md) - Complete reference guide
- [CHANGELOG.md](./CHANGELOG.md) - Version history
- [INSTALL.md](./INSTALL.md) - Detailed install options

## Core Principles

1. **Keep It Simple (KISS)** - Straightforward solutions over complex ones
2. **Always Test and Verify** - Run tests after changes
3. **Clean Up Documentation Regularly** - Keep docs current

## Support

- Issues: GitHub Issues

---
Universal development toolkit | v2.11.0

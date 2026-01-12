# KGProDesign-DevKit

Universal Claude Code development toolkit for any project.

## Why Use This Plugin

- **Unified Foundation** - Every developer starts with identical tools, workflows, and guidelines
- **Streamlined Agents** - 8 focused agents (reduced from 40) covering all development categories
- **Essential Commands** - 23 commands (reduced from 59) for efficient workflows

## Installation

### Prerequisites

- **Claude Code CLI** installed and configured
- **GitHub Access** - Clone or download the repository

### Step 1: Clone the Repository

First, clone this repository to a local directory:

**HTTPS:**
```bash
git clone https://github.com/kg250006/KGProDesign-DevKit.git
```

**SSH (If configured):**
```bash
git clone git@github.com:kg250006/KGProDesign-DevKit.git
```

### Step 2: Copy to Claude Plugins Directory

After cloning, copy the repository to your Claude Code plugins directory:

**macOS / Linux:**
```bash
mkdir -p ~/.claude/plugins
cp -r KGProDesign-DevKit ~/.claude/plugins/
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\plugins"
Copy-Item -Recurse KGProDesign-DevKit "$env:USERPROFILE\.claude\plugins\"
```

**Windows (Command Prompt):**
```cmd
mkdir %USERPROFILE%\.claude\plugins
xcopy /E /I KGProDesign-DevKit "%USERPROFILE%\.claude\plugins\KGProDesign-DevKit"
```

### Per-Project Install (Alternative)

If you prefer project-specific installation:

```bash
cp -r KGProDesign-DevKit/.claude/* /your/project/.claude/
```

### Verification

```bash
claude
/help  # Should show KGProDesign-DevKit commands
```

### Updating the Plugin

To get the latest version, pull from your cloned repository and re-copy:

```bash
cd /path/to/your/KGProDesign-DevKit
git pull origin main
# Then repeat Step 2 to copy updated files
```

## Quick Start (5 Minutes)

### 1. Initialize Context
```bash
claude
/context-prime
```

### 2. Create Your First PRP
```bash
/$PLUGIN_NAME:prp-create "Add user authentication"
```

### 3. Execute the PRP
```bash
/$PLUGIN_NAME:prp-execute PRPs/active/user-auth/prp.md
```

## Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| `frontend-engineer` | UI/UX and component development | React, Vue, styling, accessibility |
| `backend-engineer` | API and service development | REST, GraphQL, business logic |
| `data-engineer` | Database and data layer | Schema, migrations, queries |
| `qa-engineer` | Testing and code review | Unit tests, E2E, security |
| `project-coordinator` | Project management | Sprint planning, task breakdown |
| `document-specialist` | Documentation | PRDs, PRPs, technical docs |
| `devops-engineer` | Infrastructure | CI/CD, Docker, deployment |
| `config-auditor` | Plugin validation | Audit skills, commands, agents |

## Available Commands

### Core
- `/context-prime` - Initialize project context
- `/create <type> [name]` - Universal scaffolding
- `/debug [issue]` - Expert debugging

### PRP Workflow
- `/$PLUGIN_NAME:prp-create` - Generate Product Requirement Prompt
- `/$PLUGIN_NAME:prp-execute` - Execute PRP with validation
- `/$PLUGIN_NAME:prp-validate` - Pre-flight PRP validation

### Workflow
- `/commit` - Smart git commit
- `/pr` - Create pull request
- `/review` - Code review

### Meta-Prompting
- `/create-prompt` - Create prompts for other Claudes
- `/run-prompt` - Delegate to fresh contexts

### Creation Toolkit
- `/create-hook` - Configure Claude Code hooks
- `/create-subagent` - Create specialized subagents
- `/create-slash-command` - Create slash commands
- `/create-agent-skill` - Create Claude Code skills
- `/create-plan` - Create project plans
- `/create-meta-prompt` - Create multi-stage prompts

### Analysis
- `/consider <framework>` - Decision frameworks (12 available)
- `/onboard` - Project onboarding

### Utility
- `/handoff` - Context handoff document
- `/resolve-conflicts` - Git conflict resolution

## Directory Structure

```
~/.claude/plugins/KGProDesign-DevKit/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── agents/           # 8 specialized agents
├── commands/         # 23 streamlined commands
├── templates/
│   ├── prp_base.md       # Context-rich PRP template
│   ├── prp_planning.md   # PRD generation template
│   └── frameworks/       # Tech stack CLAUDE.md templates
│       ├── CLAUDE-NEXTJS-15.md
│       ├── CLAUDE-REACT.md
│       ├── CLAUDE-ASTRO.md
│       ├── CLAUDE-NODE.md
│       ├── CLAUDE-PYTHON-BASIC.md
│       ├── CLAUDE-JAVA-GRADLE.md
│       └── CLAUDE-JAVA-MAVEN.md
├── scripts/
│   └── prp_runner.py     # Programmatic PRP execution
├── CLAUDE.md         # Reference guide
├── README.md         # This file
├── QUICKSTART.md     # Extended tutorial
└── VERSION_MANIFEST.md
```

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

## Programmatic PRP Execution

Use `scripts/prp_runner.py` for CI/CD or batch processing:

```bash
# Interactive mode
uv run scripts/prp_runner.py --prp feature-name --interactive

# Headless with JSON output
uv run scripts/prp_runner.py --prp-path PRPs/active/feature.md --output-format json
```

## Documentation

- [CLAUDE.md](./CLAUDE.md) - Complete reference guide
- [QUICKSTART.md](./QUICKSTART.md) - Extended onboarding tutorial

## Core Principles

1. **Keep It Simple (KISS)** - Straightforward solutions over complex ones
2. **Always Test and Verify** - Run tests after changes
3. **Clean Up Documentation Regularly** - Keep docs current

## Support

- Issues: GitHub Issues

---
Universal development toolkit | v1.0.0

# CLAUDE.md - KGProDesign-DevKit Reference

This file provides guidance to Claude Code when working in projects using the KGProDesign-DevKit plugin.

## Core Principles

### 1. Keep It Simple (KISS)
- Choose straightforward solutions over complex ones
- Simple solutions are easier to understand, maintain, and debug
- If it takes more than 3 steps to explain, simplify it

### 2. Always Test and Verify
- Your work is not complete until tests pass
- Run verification after every significant change
- Use the appropriate testing commands for your stack

### 3. Clean Up Documentation Regularly
- Update CLAUDE.md when workflows change
- Remove outdated commands/agents
- Keep examples current and working

---

## PRP Workflow

### What is a PRP?
Product Requirement Prompt - A structured specification that Claude executes to implement features with validation gates.

### PRP Lifecycle
```
1. Create PRP    → /KGP:prp-create (gather requirements)
2. Validate PRP  → /KGP:prp-validate (pre-flight checks)
3. Execute PRP   → /KGP:prp-execute (Claude implements)
4. Verify        → Run tests, review changes (qa-engineer agent)
5. Commit        → git commit with conventional format
```

### PRP Creation
```bash
/KGP:prp-create "Add user authentication with OAuth2"
```
Claude will:
1. Ask clarifying questions
2. Research existing patterns in codebase
3. Generate structured PRP document
4. Save to PRPs/ directory

### PRP Execution
```bash
/KGP:prp-execute PRPs/PRP-auth-oauth2.md
```
Claude will:
1. Parse the PRP specification
2. Implement step by step
3. Run validation at each step
4. Report completion status

### Native Long-Run Execution

`/KGP:prp-execute` runs PRPs end-to-end in a single Claude Code session. With a 1M-token-context model (Sonnet 5, Opus 4.8, or Fable 5 on a plan tier that supports it) and Auto mode, multi-thousand-line PRPs (or several PRPs at once) execute without external orchestration, scripts, or iteration loops.

Recommended invocation:

```bash
/KGP:prp-execute PRPs/PRP-feature.md
/KGP:prp-execute PRPs/PRP-foundation.md PRPs/PRP-core.md PRPs/PRP-polish.md
/KGP:prp-execute PRPs/PRP-feature.md --team
```

Tips:

- Auto mode (`Shift+Tab` to cycle, or `autoMode` in `settings.json`) eliminates per-tool prompts during long runs.
- Delegate verbose-output tasks (large test runs, exploratory research, builds) to subagents via the Task tool so their noise never enters the main context. This matters more than relying on auto-compaction.
- Checkpoints are automatic at each user prompt; `/rewind` recovers from a bad mid-run state without restarting the whole PRP.
- See https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents for Anthropic's harness design guidance.

### Model Strategy

| Phase | Recommended model | Why |
|-------|-------------------|-----|
| PRP creation / architecture | Opus 4.8 or Fable 5 | Deepest reasoning for planning and decomposition |
| PRP execution (long runs) | Sonnet 5 or Opus 4.8 (1M context) | Capability + context headroom for multi-PRP sessions |
| Mechanical subagent work | Haiku 4.5 | Cheap, fast; set `model: haiku` in agent frontmatter |
| Time-critical output | Opus 4.8 + `/fast` | Fast mode: faster output on the same model |

### Remote Monitoring for Long Runs

For multi-hour PRP executions, start the run locally, then attach to the live session from claude.ai/code or the mobile app (remote control). You can answer halt-condition questions or check progress from anywhere — the session keeps running on your machine. This is the recommended pattern for any run you won't be sitting in front of.

**Migration notes:**

- **v2.0.0** removed the forked `/KGP:ralph-loop` and `/KGP:cancel-ralph` commands.
- **v2.2.0** removed `/KGP:prp-execute-batch` and `/KGP:prp-execute-isolated`. Their use cases are absorbed by `/KGP:prp-execute` accepting multiple PRP paths and native subagent delegation.
- **v2.3.0** removed the duplicate `toolkit/` create-* commands (use the `core/` equivalents), modernized visual testing to Chrome DevTools MCP, and added auto-invocation hooks. See CHANGELOG.md.

Stale state files in existing projects can be cleaned manually:

```bash
rm -f .claude/ralph-loop.local.md .claude/KGP:ralph-loop.local.md .claude/ralph-progress.md \
      .claude/prp-orchestrator-state.log .claude/current-task.md .claude/prp-progress.md \
      .claude/prp-batch-progress.md
```

### Agent Teams (Experimental)

Parallel 3–5 teammate execution with inter-teammate messaging. Enable in `settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Restart Claude Code after changing settings.

**Commands:**

```bash
# Spawn a one-off team (recipe auto-picked from task text)
/KGP:team-invoke "review PR #42 for auth changes"
/KGP:team-invoke "why does the app crash on startup?"
/KGP:team-invoke "build a user profile page with avatar upload"

# Run a PRP with auto-partitioned team
/KGP:prp-execute PRPs/feature.md --team
/KGP:prp-execute PRPs/feature.md --team=review   # explicit recipe
```

**Recipes:**
- `implementation` — `frontend-engineer` + `backend-engineer` + `data-engineer`
- `review` — `qa-engineer` + `backend-engineer` + `frontend-engineer`
- `research` — 3 generalists (UX / architecture / devil's-advocate)
- `hypothesis` — 3–5 teammates, one per hypothesis

**When NOT to use `--team`:** if a phase is deterministic fan-out (apply the same change across N files, verify N criteria independently), Claude Code's native Workflow tool is cheaper and more reliable than a team. Reserve `--team` for genuinely independent tracks that benefit from peer messaging.

**Skill:** `skills/agent-teams/` (`SKILL.md` router + `references/playbooks.md` with classifier + spawn templates).

---

## Design Workflow (Websites & UI)

Most KGProDesign projects are design-forward websites. The design pipeline:

1. **Tokens first.** Before implementing UI, establish design tokens. For KG ProDesign-owned properties, the `kgprodesign-branding` skill is the source of truth (colors, logos, typography). If the project syncs with Claude Design (claude.ai/design), pull the design system before generating components.
2. **Generate with design skills.** When the official `frontend-design` plugin/skill is installed, invoke it for component and page generation — it avoids generic AI aesthetics. Use the `dataviz` skill for any chart, dashboard, or data visualization.
3. **Visual QA loop.** After implementing UI, run the screenshot-iterate loop from the `ui-visual-testing` skill: render → screenshot (Chrome DevTools MCP or claude-in-chrome) → critique against the style guide → refine. Do at least one iteration on every user-facing page.
4. **Frontend PRPs get a design phase.** `/KGP:prp-create` emits a "Phase 0: Design Foundation" for website/UI PRPs — token setup, component inventory, and a visual QA gate in the integration validation.

---

## Framework Templates

Pre-built CLAUDE.md templates for common tech stacks in `templates/frameworks/`:

| Template | Stack | Use Case |
|----------|-------|----------|
| `CLAUDE-NEXTJS-15.md` | Next.js 15 + React 19 + TypeScript | Full-stack web apps |
| `CLAUDE-REACT.md` | React 19 + TypeScript | Frontend SPAs |
| `CLAUDE-ASTRO.md` | Astro 5 + Islands Architecture | Content-heavy sites |
| `CLAUDE-NODE.md` | Node.js 23 + Fastify | Backend APIs |
| `CLAUDE-PYTHON-BASIC.md` | Python + FastAPI + UV | Python APIs |
| `CLAUDE-JAVA-GRADLE.md` | Java 21 + Spring Boot + Gradle | Enterprise Java |
| `CLAUDE-JAVA-MAVEN.md` | Java 21 + Spring Boot + Maven | Enterprise Java |

### Using Framework Templates
Copy the appropriate template to your project root:

```bash
cp templates/frameworks/CLAUDE-NEXTJS-15.md /your/project/CLAUDE.md
```

Or reference it in your project's CLAUDE.md:

```markdown
# Project CLAUDE.md

## Framework Reference
@~/.claude/plugins/KGProDesign-DevKit/templates/frameworks/CLAUDE-NEXTJS-15.md

## Project-specific overrides
...
```

---

## Available Agents (12)

### Engineering

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| `dev-engineer` | Workflow-enforcing orchestrator (Vibe Kanban default) | Any implementation card — always runs PRP-Create → Validate → Execute |
| `frontend-engineer` | UI, components, performance, accessibility | Building UI, implementing designs, state management |
| `backend-engineer` | APIs, business logic, services | API design, auth, service integration |
| `data-engineer` | Schema, migrations, optimization | Data modeling, query optimization |
| `qa-engineer` | Testing, security, code review | Before merging, after complex features |
| `devops-engineer` | CI/CD, Docker, infrastructure | Pipeline setup, deployment, monitoring |
| `project-coordinator` | Sprint planning, task breakdown | Planning, estimation, progress tracking |
| `document-specialist` | PRDs, PRPs, technical docs | Documentation of any kind |

### Auditors

| Agent | Purpose |
|-------|---------|
| `config-auditor` | Plugin configuration validation (skills + commands + agents) |
| `skill-auditor` | SKILL.md best-practices audits |
| `slash-command-auditor` | Slash command audits |
| `subagent-auditor` | Subagent configuration audits |

Invoke agents via the Task tool with the matching `subagent_type`.

---

## Commands Reference (31)

### Top-Level

| Command | Purpose |
|---------|---------|
| `/KGP:comm-style` | Set up, review, tweak, or remove a project's communication style rule (`.claude/rules/`, personal and git-excluded by default) |
| `/KGP:context-prime` | Initialize project understanding (structure, stack, CLAUDE.md files) |
| `/KGP:deploy` | Deploy via deployment-expert skill (Netlify, Azure VM, FTP, GitHub), or kgp-hosting when the repo has `kgp.toml` |
| `/KGP:help` | Explain the plugin and available commands |
| `/KGP:migrate-netlify` | Move a Netlify site to KGP Host step by step, with an approval gate before each owner action |
| `/KGP:prp-create` | Generate PRP from requirements (intent-lock + decision-log) |
| `/KGP:prp-validate` | Pre-flight PRP validation with auto-fix |
| `/KGP:prp-execute` | Execute one or more PRPs in a single native session |
| `/KGP:run-regression` | Automated regression tests (frontend, backend, E2E, coverage) |
| `/KGP:team-invoke` | Spawn an experimental Agent Team |

### core/ — Plugin Authoring & Audits

| Command | Purpose |
|---------|---------|
| `/KGP:core:audit-skill` | Audit a skill for best practices |
| `/KGP:core:audit-slash-command` | Audit a slash command |
| `/KGP:core:audit-subagent` | Audit a subagent config |
| `/KGP:core:create-agent-skill` | Create a Claude Code skill |
| `/KGP:core:create-hook` | Configure Claude Code hooks |
| `/KGP:core:create-meta-prompt` | Create multi-stage Claude-to-Claude prompts |
| `/KGP:core:create-slash-command` | Create a slash command |
| `/KGP:core:create-subagent` | Create a specialized subagent |
| `/KGP:core:heal-skill` | Apply corrections to skill docs discovered during execution |

### dev/ — Daily Workflow

| Command | Purpose |
|---------|---------|
| `/KGP:dev:add-to-todos` | Add todo item to TO-DOS.md with context |
| `/KGP:dev:check-todos` | List outstanding todos and pick one |
| `/KGP:dev:create-plan` | Create hierarchical project plans |
| `/KGP:dev:create-prompt` | Create a prompt for another Claude to execute |
| `/KGP:dev:debug` | Expert debugging methodology |
| `/KGP:dev:run-plan` | Execute a PLAN.md directly |
| `/KGP:dev:run-prompt` | Delegate prompts to fresh sub-task contexts |
| `/KGP:dev:whats-next` | Create a handoff document for continuing in a fresh context |

### tools/ — Desktop Utilities

| Command | Purpose |
|---------|---------|
| `/KGP:tools:status` | Install path, dependency health, and running state for both desktop tools |
| `/KGP:tools:cron` | Start, stop, restart, inspect, autostart, hand-fire jobs, read logs |
| `/KGP:tools:schedule` | Add, edit, enable, disable, remove a CronLike job, scoped to the current project |
| `/KGP:tools:jiggler` | Start, stop, inspect, or autostart the Mouse Jiggler |

---

## Tools

`tools/` holds standalone desktop utilities that ship with the plugin. They are **not** agent orchestration, and the Execution Philosophy section below does not apply to them: they have no notion of agents, tasks, PRPs, iteration, or retries. CronLike runs whatever string you put in a config field, on a clock. Treat them the way you would treat any other program installed on the machine.

| Tool | Entry point | Docs |
|------|-------------|------|
| MouseJiggler | `tools/MouseJiggler/mouse_jiggler.py` | `tools/MouseJiggler/README.md` |
| CronLike | `tools/CronLike/cronlike.py` | `tools/CronLike/README.md`, `tools/CronLike/SCHEDULE.md` |

Both are Python and install with `pip install -r requirements.txt` from their own directory. Neither registers a command, agent, skill, or hook.

**Operational knowledge lives in the `desktop-tools` skill** (`skills/desktop-tools/`): a router plus references for each tool, scheduling recipes, the install-and-update layout, and a troubleshooting table. It auto-invokes on phrases like "schedule this to run every morning" or "keep my machine awake". `workflows/add-tool.md` is the procedure for adding a third tool: one registry row plus one reference file.

All process control goes through `scripts/tools/toolctl.sh`. The four commands and the skill are two front doors to one implementation; neither reimplements start, stop, or status.

**Configuring CronLike:** read `tools/CronLike/SCHEDULE.md` first. It is the complete field reference and the error-message contract, and it is the file to load before adding or editing a scheduled job. The live config is at `~/.cronlike/schedule.json`; validate any edit with `python cronlike.py --check`, which prints the next 5 fire times per job so a wrong schedule is visible before it runs.

---

## KGP Host

`skills/kgp-hosting/` deploys, publishes, rolls back, and diagnoses sites on KGP Host through the `kgp` CLI. It applies when the repo has `kgp.toml` and takes priority over deployment-expert there. It needs the `kgp` CLI on PATH and a logged-in instance; see its `<prerequisites>` section. It also pushes posts, pages, media and content-model entries from a repo's `wordpress/content/` folder to WordPress concept, demo or client sites (`kgp wp content push`; drafts unless asked, owner-only for client sites).

The source of truth is `skills/kgp-hosting/` in the private KGP-WebHosting-Tools repo. Change it there and copy it here with `scripts/install-skill.sh --devkit PATH`, which refuses host-specific details because this repo is public. Never add IP addresses, cPanel host names, account names, or home paths to this skill.

---

## Automatic Skill Invocation

The plugin ships hooks (see `hooks/hooks.json`) that make skill selection automatic:

- **UserPromptSubmit** — detects PRP-shaped, design-shaped, deploy-shaped, and debug-shaped prompts and injects a one-line hint pointing at the right command/skill.
- **SessionStart** — inventories `PRPs/` in the working project and surfaces in-flight PRPs so a fresh session knows what's active.
- **PostToolUse** — after editing a `SKILL.md`, command, or agent file, suggests the matching auditor agent.

Skills also self-invoke through their descriptions — each skill's `description` lists concrete trigger phrases. When adding a skill, write the description as "Use when [specific user phrasings]…" so Claude fires it without being asked.

---

## Maintenance Processes

### Adding New Commands

1. Create `commands/[category]/command-name.md` in the plugin
2. Follow YAML frontmatter format:
   ```yaml
   ---
   description: Brief description
   argument-hint: "<expected-args>"
   allowed-tools: [Read, Write, Bash, Grep, Glob]
   ---
   ```
3. Document in CLAUDE.md
4. Test with `/KGP:command-name`

### Adding New Agents

1. Create `agents/agent-name.md`
2. Include frontmatter:
   ```yaml
   ---
   name: agent-name
   description: Detailed purpose with "MUST BE USED when..." trigger phrasing
   tools: Read, Write, Bash, Task
   model: haiku   # optional — pin cheap models for mechanical agents
   color: Blue
   ---
   ```
3. Define clear purpose and instructions
4. Document in CLAUDE.md

### Updating Documentation

- Update CHANGELOG.md with every version bump
- Periodically run `/KGP:core:audit-skill`, `audit-slash-command`, `audit-subagent` across the plugin
- Re-run a capability sweep against the Claude Code changelog every few months and prune anything stale

---

## Best Practices

### For All Development

1. **Start with context:** Run `/KGP:context-prime` in new sessions (the SessionStart hook covers the basics automatically)
2. **Use agents for complexity:** Single commands for simple tasks, agents for complex
3. **Verify before commit:** Run tests and delegate a review to `qa-engineer` before committing
4. **Test incrementally:** Don't batch large changes

### For PRP Workflow

1. **Be specific in requirements:** Vague PRPs produce vague results
2. **Review before executing:** PRPs are editable - refine them
3. **Break large features:** Multiple small PRPs beat one large PRP
4. **Save successful PRPs:** Build a library of working patterns

### Execution Philosophy

With 1M-context models, full PRPs (or several PRPs at once) execute in a single native Claude Code session. There is no "isolation mode," no batch runner, no iteration loop. The single command handles all cases.

**Commands comparison:**

| Command | Context | Best For |
|---------|---------|----------|
| `prp-execute <prp.md>` | Single session | Most PRPs |
| `prp-execute <prp1.md> <prp2.md> ...` | Single session | Multiple related PRPs in sequence |
| `prp-execute <prp.md> --team` | Single session, parallel teammates | Tasks with independent tracks |

If a single PRP is so large that context pressure becomes a problem, the right moves are: (1) delegate verbose-output tasks to subagents via the Task tool, and (2) split the PRP — `/KGP:prp-validate` warns when a PRP exceeds the recommended envelope. Do NOT spin up external orchestration.

### For Code Review

1. **Review early:** Don't wait until PR time
2. **Focus on business logic:** Syntax is the easy part
3. **Track patterns:** Note recurring issues for CLAUDE.md

---

## Troubleshooting

### Command Not Found
```bash
# Verify the plugin is installed
/plugin

# Restart Claude session
Ctrl+D
claude
```

### Agent Not Available
```bash
# Check agent file exists in the plugin
ls ~/.claude/plugins/KGProDesign-DevKit/agents/

# Verify frontmatter format
cat ~/.claude/plugins/KGProDesign-DevKit/agents/agent-name.md
```

### Context Issues
```bash
# Clear and reinitialize
/clear
/KGP:context-prime
```

---

## Configuration

### Project settings (`.claude/settings.json`)
```json
{
  "permissions": {
    "allow": ["Bash(npm run lint)", "Bash(npm run test:*)"]
  },
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### Project-Specific CLAUDE.md
Create project-specific CLAUDE.md in your project root:

```markdown
# Project CLAUDE.md

## Project-specific context
- Framework: Next.js 15
- Database: PostgreSQL with Prisma ORM
- Testing: Vitest + Playwright

## Import plugin documentation
@~/.claude/plugins/KGProDesign-DevKit/CLAUDE.md
```

---

Last Updated: 2026-10-13
Maintained by: KGProDesign

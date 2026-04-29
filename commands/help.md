---
description: "[KGP] Explain KGProDesign-DevKit plugin and available commands"
---

# KGProDesign-DevKit Help

Please explain the following to the user:

## What is KGProDesign-DevKit?

A Claude Code plugin providing agents, commands, skills, and hooks for PRP-driven development. v2.2.0 simplifies PRP execution into a single native single-session command with no external scripts or iteration loops.

## Execution Model — Native Single-Session

`/KGP:prp-execute` runs one or more PRPs end-to-end in this Claude Code session. With 1M-context-capable models (Opus 4.7, Sonnet 4.6 on a plan tier that supports it) and Auto mode, multi-thousand-line PRPs and multi-PRP queues execute without external orchestration.

See https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents for Anthropic's harness design guidance.

## Available Commands

### PRP Workflow

```bash
/KGP:prp-create "feature description"              # Generate a PRP (with intent-lock + decision-log)
/KGP:prp-validate PRPs/feature.md                  # Pre-flight validation
/KGP:prp-execute PRPs/feature.md                   # Execute one PRP, native single session
/KGP:prp-execute PRPs/a.md PRPs/b.md PRPs/c.md     # Execute multiple PRPs in one session
/KGP:prp-execute PRPs/feature.md --team            # Execute with Agent Team (experimental)
```

### Agent Teams (Experimental)

Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `settings.json`:

```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```

Then:

```bash
/KGP:team-invoke "<task>"                          # Spawn a 3–5 teammate team (auto recipe)
/KGP:team-invoke "<task>" --recipe review          # Explicit recipe
/KGP:prp-execute <prp> --team                      # Auto-partition PRP across team
```

**Recipes:** `implementation`, `review`, `research`, `hypothesis`.

## Available Agents

Use the `Task` tool with `subagent_type` to delegate work:

| Agent | Specialization |
|---|---|
| `backend-engineer` | APIs, auth, services, business logic |
| `frontend-engineer` | Components, accessibility, responsive design |
| `data-engineer` | Schema, migrations, queries, data modeling |
| `qa-engineer` | Testing, security, code review |
| `devops-engineer` | CI/CD, Docker, infrastructure |
| `document-specialist` | PRDs, technical writing, API docs |
| `project-coordinator` | Sprint planning, task breakdown |
| `config-auditor` | Plugin config validation |
| `skill-auditor` | Skill audits |
| `slash-command-auditor` | Slash command audits |
| `subagent-auditor` | Subagent audits |

## Migration

- **v2.0.0** removed the forked `/KGP:ralph-loop` and `/KGP:cancel-ralph` commands.
- **v2.2.0** removed `/KGP:prp-execute-batch` and `/KGP:prp-execute-isolated`. Their use cases are absorbed by `/KGP:prp-execute` accepting multiple PRP paths and by Claude Code's native auto-compaction + subagent delegation.

Clean stale state files from existing projects:

```bash
# v2.0.0 cleanup
rm -f .claude/ralph-loop.local.md .claude/KGP:ralph-loop.local.md .claude/ralph-progress.md

# v2.2.0 cleanup
rm -f .claude/prp-orchestrator-state.log .claude/current-task.md .claude/prp-progress.md .claude/prp-batch-progress.md
```

## Learn More

- Anthropic harness design: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Auto mode: https://code.claude.com/docs/en/permissions#permission-modes
- Subagents: https://code.claude.com/docs/en/sub-agents
- Agent Teams skill: `skills/agent-teams/SKILL.md` (playbooks at `references/playbooks.md`)

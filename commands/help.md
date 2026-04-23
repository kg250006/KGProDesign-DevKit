---
description: "[KGP] Explain KGProDesign-DevKit plugin and available commands"
---

# KGProDesign-DevKit Help

Please explain the following to the user:

## What is KGProDesign-DevKit?

A Claude Code plugin providing agents, commands, skills, and hooks for PRP-driven development. v2.0.0 replaces the forked Ralph Loop with a three-tier execution strategy and adds experimental Agent Teams.

## Execution Model — Three-Tier PRP Dispatch

`/KGP:prp-execute` detects your environment and chooses a tier automatically:

- **Tier 1** — Marketplace plugin `ralph-loop@claude-plugins-official` installed → delegates to `/ralph-loop` for iterative retry.
- **Tier 2** — Plugin not installed → runs single-pass in-session, prints install recommendation.
- **Tier 3** — Detection primitives missing (no `jq` or `claude` CLI) → single-pass with neutral note.

Install the marketplace Ralph Loop once:

```
/plugin install ralph-loop@claude-plugins-official
```

## Available Commands

### PRP Workflow

```bash
/KGP:prp-create "feature description"              # Generate a PRP
/KGP:prp-validate PRPs/feature.md                  # Pre-flight validation
/KGP:prp-execute PRPs/feature.md                   # Execute via three-tier dispatch
/KGP:prp-execute PRPs/feature.md --team            # Execute with Agent Team (experimental)
/KGP:prp-execute-batch <prp1> <prp2> ...           # Run multiple PRPs sequentially
/KGP:prp-execute-isolated PRPs/feature.md          # Hard per-task isolation (large PRPs)
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

**Recipes:** `implementation`, `review`, `research`, `hypothesis`. Mutex: `--team` and `--isolated` cannot both be set.

### Direct Marketplace Ralph Loop

If `ralph-loop@claude-plugins-official` is installed, call it directly:

```bash
/ralph-loop "<prompt>" --max-iterations 20 --completion-promise "DONE"
/cancel-ralph
```

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

## Migration from v1.x

The forked `/KGP:ralph-loop` and `/KGP:cancel-ralph` commands are removed in v2.0.0. To preserve iterative execution, install the marketplace plugin above — `/KGP:prp-execute` will auto-delegate.

Clean stale state files from existing projects:

```bash
rm -f .claude/ralph-loop.local.md .claude/KGP:ralph-loop.local.md .claude/ralph-progress.md
```

## Learn More

- Marketplace Ralph Loop: `ralph-loop@claude-plugins-official`
- Agent Teams docs: https://code.claude.com/docs/en/agent-teams
- Agent Teams skill: `skills/agent-teams/SKILL.md` (playbooks at `references/playbooks.md`)
- Ralph Wiggum technique (original): https://ghuntley.com/ralph/

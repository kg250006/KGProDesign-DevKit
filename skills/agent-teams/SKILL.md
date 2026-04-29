---
name: agent-teams
description: Experimental parallel execution via Claude Code Agent Teams. Use when a task has independent tracks that can run in parallel, or when multi-lens review improves quality. Requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1.
triggers:
  - "parallel review"
  - "agent team"
  - "competing hypotheses"
  - "team invoke"
  - "multi-lens review"
allowed-tools: [Read, Glob]
---

# Agent Teams — Router

Spawn 3–5 specialized teammates that run in parallel with inter-teammate messaging. Lead session coordinates and owns progress-file writes.

## When to use vs when not to use

```
Task has >=2 independent tracks (no cross-dependency)?   → consider Teams
Task benefits from multiple reviewer lenses?              → Teams (review)
Bug with unclear root cause?                              → Teams (hypothesis)
Early design / library choice?                            → Teams (research)
Full-stack feature spanning UI + API + schema?            → Teams (implementation)

Otherwise:
- Single subagent (Task tool) for one-lens work
- /KGP:prp-execute (native single-session) for any PRP, single or multi
```

## Recipes (at a glance)

| Recipe | Teammates | Use case |
|---|---|---|
| `implementation` | `frontend-engineer`, `backend-engineer`, `data-engineer` | Full-stack features with parallel tracks |
| `review` | `qa-engineer`, `backend-engineer`, `frontend-engineer` | Pre-merge / pre-ship review from 3 lenses |
| `research` | 3 generalists (UX / architecture / devil's-advocate) | Discovery, design exploration |
| `hypothesis` | 3–5 teammates, one per hypothesis | Hard bugs with unknown root cause |

Detail + spawn-prompt templates + classifier: see `references/playbooks.md`.

## Prerequisites

Enable the experimental flag in `settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Restart Claude Code after changing `settings.json`.

Optional: `tmux` or `iTerm2` for split-pane monitoring when the lead spawns a team.

**One-team-per-session rule:** a session can host at most one team. No nested teams. Teammate sessions cannot be resumed in-process after their work completes.

## Hazards

- **Linear token cost.** 3–5 teammates is the cost/benefit sweet spot.
- **No nested teams.** A teammate cannot spawn its own team.
- **Single-team-per-session.** Finish or cancel a team before starting another.

## Eyeball-comparison workflow

Formal benchmarking (`team-evaluate`) is deferred. For now:

1. Run the same PRP or task twice — once with `--team` (or `/KGP:team-invoke`), once without.
2. Compare completion time, test-pass rate, and surfaced issues.
3. Choose the default for this project going forward.

## Related commands

- `/KGP:team-invoke "<task>" [--recipe <name>] [--force]` — spawn a one-off team with auto-picked recipe.
- `/KGP:prp-execute <prp> [<prp2> ...] --team[=<recipe>]` — run one or more PRPs with an auto-partitioned team.

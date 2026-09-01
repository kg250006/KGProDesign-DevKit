---
description: "[KGP] Set up, review, tweak, or remove a project's communication style ruleset — concise, plain-language replies at a chosen reading level"
argument-hint: "[setup|review|tweak|remove|user]"
allowed-tools: [Skill, Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion]
---

Invoke the communication-style skill for: $ARGUMENTS

## Smart Routing

**If a rule exists in `.claude/rules/` AND the request is review/show/check**
→ Report what is active. Write nothing.

**If a rule exists in `.claude/rules/` AND the request is setup/install**
→ Review first, then offer a tweak. Setup never overwrites an existing install.

**If nothing is installed**
→ Run the wizard: detect the repo's gates, ticket prefix, and CLAUDE.md conflicts, then ask
at most five questions, then generate and install.

**If the request names user/global/all projects**
→ Install to `~/.claude/rules/communication.md` instead of the project.

## Common Invocations

### First time in a repo

```bash
/KGP:comm-style                 # Wizard: detect, ask, generate, install
/KGP:comm-style user            # Install at user level for all projects
```

### Afterwards

```bash
/KGP:comm-style review          # Show what is active and check for drift
/KGP:comm-style tweak           # Change reading level, overlays, gates, or phrases
/KGP:comm-style remove          # Uninstall from this project
```

## Tracked or Personal

The first question the wizard asks is whether the style should be tracked by the repository.
**It defaults to personal**, because a communication ruleset is a preference and committing
one makes everyone who clones the repo inherit how one person likes to be spoken to.

| Choice | Path | Tracked |
|--------|------|---------|
| **Personal (recommended, and the default)** | `.claude/rules/communication.local.md` | No, via `.git/info/exclude` |
| Shared | `.claude/rules/communication.md` | Yes, committed and reviewed in a PR |
| Every repo on this machine | `~/.claude/rules/communication.md` | Touches nothing here |

Files in `.claude/rules/` auto-load, so no import line is written anywhere. A personal
install leaves `git status` completely empty.

Reversible either way with `/KGP:comm-style tweak`.

## What Gets Installed

A single file between 40 and 60 lines in `.claude/rules/`. It carries its own settings in
YAML frontmatter, so `review` and `tweak` read it back without a sidecar config file.

Defaults: plain language at a high-school-senior reading level, anti-verbosity rules, stable
reference codes for lists of three or more, and the four aliases `scr`, `eli`, `foc`, `ref`.

## Philosophy

1. **Detect before asking.** Anything readable from the filesystem is not a question.
2. **Chat replies only.** The ruleset never governs source code, commits, or PRP documents.
3. **Short beats thorough.** The file loads every session. Input tokens spent must stay below
   output tokens saved.
4. **Model-agnostic.** Only the banned-phrase section varies by model. Switching models is a
   `tweak`, not a rewrite.
5. **Never impose on the repo.** Personal by default, excluded via `.git/info/exclude` so
   `git status` stays clean.
6. **Never overwrite silently.** An existing install routes to review.

Changes take effect in the next session, not the current one.

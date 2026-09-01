---
name: communication-style
description: Generates and installs a tailored communication ruleset into any project so Claude answers concisely in plain language at a chosen reading level, with stable reference codes and short aliases. Model-agnostic - only the banned-phrase layer varies by model. Installs at project or user scope and supports reviewing, tweaking, and removing an existing ruleset. Use when Claude is too verbose or too technical in a repo, when setting up or updating communication style for a project, or when asked to simplify replies, make responses shorter, stop over-explaining, or explain things more simply.
---

<essential_principles>

## 1. Detect before asking

Read the repo's CLAUDE.md, its gates, and its ticket prefix first. Every question you can
answer from the filesystem is a question the user should not have to answer.

## 2. Scope to chat replies

Prose rules must never govern source code, commit messages, PR bodies, or plan and PRP
documents. "Avoid semicolons and fragments" applied to code is destructive. The generated
artifact states its scope in its first section, always.

## 3. Keep the artifact short

40-60 lines, hard limit. This file loads on every session. Input tokens spent here must stay
smaller than the output tokens saved, or the feature is a net loss. Rationale belongs in
`references/`, which loads only while this skill runs.

## 4. Isolate model-specific content

Only the banned-phrase layer may name a model. Every other rule must survive a model switch
untouched. If changing models requires editing anything else, the layering has failed.

## 5. Never impose the style on the repository

A ruleset is a personal preference. Committing one makes everyone who clones the repo
inherit how one person likes to be spoken to. Ask about tracking before writing anything and
default to personal, excluded via `.git/info/exclude` so `git status` stays clean.

## 6. Write no import line

Files in `.claude/rules/` auto-load. An `@` import on top of an auto-loaded file loads the
content twice and doubles its token cost. Verify load paths against the installed binary,
never against prose - see `references/mechanisms.md` `<rejected>` for three separate
sources that got this wrong.

## 7. Never overwrite silently

An existing install routes to review, not to setup. Two communication files in
`.claude/rules/` both load, applying the rules twice.

</essential_principles>

<intake>

**First: detect state.**

```bash
if [ -f .claude/rules/communication.local.md ]; then
    STATE=installed          # personal, git-excluded
elif [ -f .claude/rules/communication.md ]; then
    STATE=installed          # shared, committed
elif [ -f "$HOME/.claude/rules/communication.md" ]; then
    STATE=user-installed
else
    STATE=none
fi
```

**If STATE is `installed` and the user says review, show, check, or what's active:**
→ Go directly to `workflows/review.md`. Do not show the menu.

**If STATE is `installed` and the user asks to set up or install:**
→ Route to `workflows/review.md` first, then offer `workflows/tweak.md`. Setup does not
overwrite an existing install.

**If STATE is `none`, or the user explicitly asks for the menu:**

What would you like to do?

1. Set up communication style for this project
2. Review the installed style
3. Tweak the installed style
4. Remove the installed style
5. Install at user level (all projects)

**Wait for response before proceeding.**

</intake>

<routing>

| Response | Workflow |
|----------|----------|
| 1, "setup", "set up", "install", "apply", "update communication style" | `workflows/setup.md` |
| 2, "review", "show", "check", "what's active" | `workflows/review.md` |
| 3, "tweak", "change", "adjust", "edit" | `workflows/tweak.md` |
| 4, "remove", "uninstall", "delete" | `workflows/remove.md` |
| 5, "user level", "global", "all projects" | `workflows/setup.md` with scope=user |

**After reading the workflow, follow it exactly.**

</routing>

<layer_model>

The artifact is assembled from four layers that vary independently. Knowing which layer a
change belongs to is most of the work.

| Layer | Content | Varies by |
|-------|---------|-----------|
| L1 Core style | Most-important-last, plain language, facts once, detail matched to request, no flattery, no analogies, no preamble | nothing |
| L2 Reading level | high-school-senior (default), peer-engineer, mixed | wizard answer |
| L3 Model tics | Banned-phrase list | model, extensible |
| L4 Project bindings | Scope exclusions, evidence gates, ticket reservation, mandated-work carve-outs | repo, detected |

Orthogonal to the layers is **tracking**, which decides only where the file goes. All three
paths auto-load; none needs an import line.

| Choice | Path | Tracked |
|--------|------|---------|
| Personal (default) | `.claude/rules/communication.local.md` | No, `.git/info/exclude` |
| Shared | `.claude/rules/communication.md` | Yes, committed |
| Every repo on this machine | `~/.claude/rules/communication.md` | Touches nothing here |

</layer_model>

<reference_index>

All in `references/`:

- `base-ruleset.md` - canonical L1 and L2 text, the reference-code legend, and the four
  aliases. Names no model, by design.
- `model-tics.md` - the L3 layer. Neutral phrase list plus per-model overlays and the merge
  rule. The only file that may name a model.
- `conflict-resolution.md` - the T1-T5 conflict catalogue with detection commands and
  resolutions, plus the four pre-install questions.
- `mechanisms.md` - how `.claude/rules/*.md` auto-loading works (verified against the CLI
  binary), the personal-vs-shared tracking split, and why output styles and
  `.claude.local.md` were rejected.

</reference_index>

<workflows_index>

All in `workflows/`:

| File | Purpose | When to Use |
|------|---------|-------------|
| `setup.md` | Detect, ask, generate, install | First install in a repo |
| `review.md` | Report what is active, check drift. Writes nothing. | Anything already installed |
| `tweak.md` | Amend one section in place, or move across the tracking boundary | Changing level, overlays, gates, or tracking |
| `remove.md` | Delete the rule file and its ignore entry | Uninstalling |

</workflows_index>

<templates_index>

All in `templates/`:

| File | Purpose |
|------|---------|
| `communication-style.md.template` | The rule file written into target repos. Carries the generator contract and the 40-60 line budget. |

</templates_index>

<success_criteria>

- [ ] The tracking question was asked before anything was written, defaulting to personal
- [ ] The file landed in `.claude/rules/` and NO import line was written anywhere
- [ ] A personal install left `git status` completely empty
- [ ] Detection ran before any question was asked
- [ ] No existing install was overwritten by setup
- [ ] The rendered artifact is 40-60 lines with the generator comment stripped
- [ ] The artifact states its scope in its first section
- [ ] No model is named outside the "Phrases to avoid" section
- [ ] Exactly one communication file exists in `.claude/rules/`
- [ ] The user was told the change applies next session, not this one

</success_criteria>

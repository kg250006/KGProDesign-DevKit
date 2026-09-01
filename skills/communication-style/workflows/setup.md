<required_reading>
Read `references/base-ruleset.md` for L1 and L2 text.
Read `references/model-tics.md` for L3 overlays and the merge rule.
Read `references/conflict-resolution.md` for the T1-T5 detection procedure.
Read `references/mechanisms.md` before writing anything, especially `<tracking>`.
</required_reading>

<process>

## Step 1: Detect existing install

```bash
test -f .claude/rules/communication.local.md && echo "PROJECT=personal"
test -f .claude/rules/communication.md       && echo "PROJECT=shared"
test -f "$HOME/.claude/rules/communication.md" && echo "USER=yes"
```

If either project file exists, **route to `workflows/review.md` and stop.** Do not
overwrite. Setup is for first install; changing one is `workflows/tweak.md`.

If a user-level install exists, continue but warn: user and project rules load *together*,
not one overriding the other. Two active rulesets is usually not what the user wants.

## Step 2: Detect repo context

```bash
for f in CLAUDE.md .claude/CLAUDE.md; do [ -f "$f" ] && echo "CLAUDE_MD=$f" && break; done
test -d PRPs && echo "HAS_PRPS=yes"

# Ticket prefix (T4)
git log --oneline -200 2>/dev/null | grep -oE '[A-Z]{2,6}-[0-9]+' | head -1 | cut -d- -f1
ls .github/ISSUE_TEMPLATE 2>/dev/null

# Gates (T5)
test -f package.json && grep -oE '"(test|lint|typecheck|build)"' package.json
test -f pyproject.toml && echo "python project"
test -f Makefile && grep -oE '^[a-z-]+:' Makefile | head -5
test -f Cargo.toml && echo "rust project"

# Does the user own this repo? Informs the ignore-file choice in step 6.
git remote -v 2>/dev/null | head -2
```

Record `PLUGIN_VERSION` from the installed plugin's `plugin.json`.

**No ticket prefix found is a valid result.** Repos using conventional commits have none.
Omit the reservation line rather than writing "none reserved".

## Step 3: Detect conflicts

Apply the Detection column from `references/conflict-resolution.md` against `CLAUDE_MD`.

```bash
grep -riE "co-authored-by|commit message|conventional commit" CLAUDE.md .claude/ 2>/dev/null
grep -nE "(must|always|never|required)" CLAUDE.md 2>/dev/null
```

For T2, filter to lines that mandate work taken *alongside* the request: updating docs,
deleting replaced code, logging lessons, auto-committing. Ignore lines constraining how code
is written; those never conflict with a reply-scope rule.

An empty result set is normal for a small repo.

## Step 4: Ask

At most five questions via AskUserQuestion. Ask only what detection could not settle.

1. **Tracking - ask this first, it decides where the file goes.**

   > Should this communication style be tracked by the repository?

   | Choice | Path | Tracked |
   |--------|------|---------|
   | **Personal (recommended, and the default)** | `.claude/rules/communication.local.md` | No - `.git/info/exclude` |
   | Shared | `.claude/rules/communication.md` | Yes - committed, reviewed in a PR |
   | Every repo on this machine | `~/.claude/rules/communication.md` | Touches nothing here |

   **Default to personal.** A communication ruleset is a preference, and committing one
   makes every teammate inherit how one person likes to be spoken to. Choose shared only
   when the team has actually agreed to it.

   Say plainly that this is reversible: `tweak` moves it between modes later.

2. **Reading level** - high-school senior (default) / peer engineer / mixed.
3. **Model overlays** - neutral only, or neutral plus named overlays. Show what each adds.
4. **Confirm gates** - present what step 2 found and let the user correct it.
5. **Resolve conflicts** - one option per conflict found in step 3. Skip entirely if none.

**Wait for response before proceeding.**

If the user does not resolve a detected conflict, report it and stop. Do not install a
ruleset that contradicts a rule the repo already enforces.

## Step 5: Generate

Render `templates/communication-style.md.template` with the collected values.

- Merge L3 as `neutral` + selected overlays, deduplicated, first-seen order.
- Compress the phrase list to one wrapped paragraph, not one bullet per phrase.
- Strip the generator-contract comment block.

**Count lines. The rendered file must be 40-60.** If over, trim in the order the template
specifies: drop examples, compress phrases, compress the code legend. If still over 60,
report the count and stop rather than shipping a bloated artifact. If under 40, check the
module flags were actually applied.

## Step 6: Install

Files in `.claude/rules/` auto-load. **Write no import line anywhere** - there is nothing to
wire up, and an import on top of an auto-loaded file would load the content twice.

**Personal (default):**

```bash
mkdir -p .claude/rules .git/info
# write .claude/rules/communication.local.md

grep -qxF ".claude/rules/communication.local.md" .git/info/exclude 2>/dev/null   || printf '%s
' ".claude/rules/communication.local.md" >> .git/info/exclude
```

`.git/info/exclude` is local-only and never committed, so `git status` stays completely
clean. Say the trade-off once: it does not survive a fresh clone and no teammate sees it.

If the user owns the repo and wants the guard to persist and be visible, offer `.gitignore`
instead. Same entry, but it produces a tracked diff.

**Shared:**

```bash
mkdir -p .claude/rules
# write .claude/rules/communication.md
```

Add nothing to any ignore file. The file is meant to be committed and reviewed in a PR.

**Every repo on this machine:**

```bash
mkdir -p "$HOME/.claude/rules"
# write ~/.claude/rules/communication.md
```

Touch nothing inside the repo, including ignore files.

## Step 7: Report

Show the generated file and its line count.

```bash
# personal
test -f .claude/rules/communication.local.md
git check-ignore -q .claude/rules/communication.local.md && echo ignored-OK
git status --short          # expect completely empty

# shared
test -f .claude/rules/communication.md
git status --short          # expect exactly this one new file
```

For a personal install, an empty `git status` is the proof that matters. Report it.

State plainly that rules load at session start, so this takes effect in the **next** session,
and that whether it loaded cannot be confirmed from inside the session that wrote it. Tell
the user to ask next session what communication rules are active.

</process>

<success_criteria>
- [ ] The tracking question was asked BEFORE anything was written, and defaulted to personal
- [ ] No existing install was overwritten
- [ ] Ticket prefix, gates, and conflicts were detected before any question was asked
- [ ] At most five questions were asked
- [ ] Every detected conflict was resolved by the user or reported as blocking
- [ ] The rendered file is 40-60 lines with the generator comment stripped
- [ ] The file sits in `.claude/rules/` and NO import line was written anywhere
- [ ] A personal install left `git status` completely empty
- [ ] A user-scope install touched nothing inside the repo
- [ ] The report states it takes effect next session and that loading was not verified
</success_criteria>

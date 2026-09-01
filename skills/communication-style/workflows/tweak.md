<required_reading>
Read `references/base-ruleset.md` for replacement L1 and L2 text.
Read `references/model-tics.md` for the overlay merge rule.
Read `references/mechanisms.md` if tracking is changing.
</required_reading>

<process>

## Step 1: Locate and parse

Same as `workflows/review.md` steps 1 and 2. Halt if nothing is installed and offer
`workflows/setup.md` instead.

**Before touching anything, capture the current "Phrases to avoid" section verbatim.** It
may contain entries the user added by hand from observation, and those are the most valuable
lines in the file.

## Step 2: Ask what to change

One AskUserQuestion round. Offer:

1. **Tracking** — move between personal, shared, and user scope. This is the only option
   that moves files, so handle it before the content edits.
2. **Reading level** — high-school-senior, peer-engineer, mixed.
3. **Model overlays** — add or remove overlays, typically after a model switch.
4. **Gates** — rebind evidence to different commands.
5. **Banned phrases** — add phrases the user has observed.
6. **Toggle a module** — turn reference-codes or aliases off.

## Step 3: Apply

**If tracking changed, move the file first.** Both project filenames match the `rules/*.md`
glob and auto-load either way, so only the filename and the ignore state change.

Personal to shared:

```bash
git mv .claude/rules/communication.local.md .claude/rules/communication.md 2>/dev/null \
  || mv .claude/rules/communication.local.md .claude/rules/communication.md
grep -v "communication.local.md" .git/info/exclude > t && mv t .git/info/exclude
```

Shared to personal:

```bash
git rm --cached -q .claude/rules/communication.md 2>/dev/null || true
mv .claude/rules/communication.md .claude/rules/communication.local.md
grep -qxF ".claude/rules/communication.local.md" .git/info/exclude 2>/dev/null \
  || printf '%s\n' ".claude/rules/communication.local.md" >> .git/info/exclude
```

Moving a previously committed file to personal needs `git rm --cached`, and the user must be
told the file **stays in git history**. Excluding it going forward does not erase what was
already pushed.

Project to user scope: move it to `~/.claude/rules/communication.md` and clean the repo-side
ignore entry. Warn that it now applies to every repo on the machine.

**Then re-render only the affected section.** Do not regenerate the whole file from the
template; that discards hand edits everywhere, not just in the phrase list.

**Preserve user-added banned phrases.** Diff the captured section from step 1 against
`references/model-tics.md`. Any phrase not in the reference was added from observation.
Re-add every one after the merge.

Update the frontmatter: `tracked`, `scope`, `reading_level`, `model_overlays`, `gates`, and
`modules` as changed, plus `kgp_plugin_version` to current. Leave `installed` at the original
date; it records first install, not last edit.

## Step 4: Verify and report

Re-count lines against the 40-60 window. A tweak that pushes the file over 60 must be
trimmed using the template's trim order before it is written.

```bash
ls .claude/rules/                  # exactly one communication file
git status --short                 # empty for personal, one file for shared
grep -rn "communication" CLAUDE.md CLAUDE.local.md 2>/dev/null   # expect nothing
```

Show a diff, not the whole file. State that it applies in the next session.

</process>

<success_criteria>
- [ ] The pre-edit phrase section was captured before any change
- [ ] If tracking changed, the file moved BEFORE content was re-rendered
- [ ] Exactly one communication file exists in `.claude/rules/` afterwards
- [ ] A shared-to-personal move used `git rm --cached` and warned about git history
- [ ] The ignore state matches the new mode
- [ ] No `@` import line was introduced anywhere
- [ ] Only the affected section was re-rendered
- [ ] Every hand-added phrase survived the edit
- [ ] Frontmatter matches the new state, and `installed` was not overwritten
- [ ] Line count is still between 40 and 60
</success_criteria>

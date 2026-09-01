<required_reading>
Read `references/mechanisms.md` for what was written at install time, so that exactly that
much is removed and nothing more.
</required_reading>

<process>

## Step 1: Locate

```bash
test -f .claude/rules/communication.local.md && echo "MODE=personal"
test -f .claude/rules/communication.md       && echo "MODE=shared"
test -f "$HOME/.claude/rules/communication.md" && echo "MODE=user"
grep -n "communication" .git/info/exclude .gitignore 2>/dev/null
grep -n "communication" CLAUDE.md CLAUDE.local.md 2>/dev/null
```

If more than one is installed, ask which to remove. Do not assume all.

The last grep catches a stray `@` import from an earlier version of this skill. If the rule
file is already gone but an import line remains, removing that line is the whole job.

## Step 2: Confirm

Show exactly what will be deleted: the file path, its line count, and any ignore-file entry
that goes with it. Ask once. Deleting is not reversible from here.

## Step 3: Remove

**Personal:**

```bash
rm .claude/rules/communication.local.md
grep -v "communication.local.md" .git/info/exclude > t && mv t .git/info/exclude
```

**Shared:**

```bash
git rm -q .claude/rules/communication.md 2>/dev/null || rm .claude/rules/communication.md
```

**User:**

```bash
rm "$HOME/.claude/rules/communication.md"
```

Also remove any stray `@` import found in step 1, taking exactly that line and nothing
around it, then collapse any doubled blank line left behind.

Never delete silently:

- **`.claude/rules/`** may hold other rule files. Remove only the communication file. Delete
  the directory itself only if it is now empty, and say so.
- **`.git/info/exclude`** and **`.gitignore`** may hold other entries. Remove only the
  matching line, and leave the file in place even if it becomes empty.
- **`CLAUDE.md`** may have been created by an earlier version of this skill. If it now has
  no other content, say so and ask before deleting it.

If the file was ever committed, note that removing it now does not remove it from git
history.

## Step 4: Verify

```bash
test ! -f .claude/rules/communication.local.md
test ! -f .claude/rules/communication.md
ls .claude/rules/ 2>/dev/null
grep -c "communication" .git/info/exclude .gitignore CLAUDE.md CLAUDE.local.md 2>/dev/null
```

All counts zero. Then confirm the reverse: every other rule file, and every pre-existing line
in the files that were touched, is still there. Removing this ruleset must not remove
anything else.

Report in one or two lines. State that replies return to default behavior next session.

</process>

<success_criteria>
- [ ] The mode was determined before anything was touched
- [ ] The user confirmed before any deletion
- [ ] The rule file is gone
- [ ] The matching ignore entry was removed
- [ ] Any stray `@` import from an earlier version was removed
- [ ] Other files in `.claude/rules/` were left untouched
- [ ] No pre-existing content was removed from any ignore file or CLAUDE.md
- [ ] A previously committed file carried a note that git history still holds it
- [ ] The import-only and file-only cases were both handled without erroring
</success_criteria>

<required_reading>
Read `references/mechanisms.md` for the tracking modes and precedence rules.
No other reference is needed. This workflow writes nothing.
</required_reading>

<process>

## Step 1: Locate

```bash
test -f .claude/rules/communication.local.md && echo "PROJECT=personal"
test -f .claude/rules/communication.md       && echo "PROJECT=shared"
test -f "$HOME/.claude/rules/communication.md" && echo "USER=yes"
ls .claude/rules/ 2>/dev/null
```

If none exist, say so in one line and offer `workflows/setup.md`. Stop.

If both project variants exist, that is a broken state from a half-finished mode switch.
Both are auto-loading right now, so the rules are applied twice. Report it and offer to
remove one.

If a project and a user install both exist, say plainly that **both are loading together**.
The project file does not override the user file. Offer to remove one.

## Step 2: Parse frontmatter

Read the YAML block between the first two `---` lines. Report:

| Field | Meaning |
|-------|---------|
| `scope` | project or user |
| `tracked` | personal (excluded) or shared (committed) |
| `reading_level` | which L2 variant is active |
| `model_overlays` | which L3 lists were merged |
| `ticket_prefix` | reserved prefix, or none |
| `gates` | what "evidence" is bound to |
| `modules` | which blocks are enabled |
| `installed` | when it was generated |
| `kgp_plugin_version` | which plugin version generated it |

## Step 3: Check drift

**Tracking drift, check this first.** The damaging failure is a personal ruleset that is
actually committed, because it silently imposes one person's preference on the team.

```bash
git check-ignore -q .claude/rules/communication.local.md && echo excluded
git ls-files --error-unmatch .claude/rules/communication.local.md 2>/dev/null && echo TRACKED-should-not-be
git status --short .claude/rules/ 2>/dev/null
```

| `tracked:` says | Reality | Verdict |
|---|---|---|
| personal | not tracked, and excluded | correct |
| personal | tracked, or showing in `git status` | **problem**, being shared without consent; offer to fix |
| shared | tracked | correct |
| shared | excluded or untracked | it is not reaching the team; report it |

**Stray import.** Earlier versions of this skill wrote an `@` import line. Files in
`.claude/rules/` auto-load, so an import is now redundant and loads the content twice:

```bash
grep -n "communication" CLAUDE.md CLAUDE.local.md .claude.local.md 2>/dev/null
```

Any hit is a leftover. Report it as doubling the token cost and offer to remove it.

**Version drift.** Compare `kgp_plugin_version` against the installed plugin version. If the
file is older, note that regenerating may pick up newer base rules. Do not regenerate
automatically.

**Gate drift.** Check each command in `gates` still exists. A gate naming a deleted script
makes the evidence rule unenforceable.

**Hand edits.** Note any phrase not present in `references/model-tics.md`. Those are user
observations and must survive any future tweak.

## Step 4: Report

A short table of what is active, followed by any drift found. If nothing is wrong, say so in
one line rather than restating the table as a conclusion.

**This workflow performs no writes.** If a fix is needed, name it and route to
`workflows/tweak.md`.

</process>

<success_criteria>
- [ ] Both project variants and the user scope were checked
- [ ] Concurrent installs were reported as loading together, not one overriding the other
- [ ] Every frontmatter field was reported, including `tracked`
- [ ] Tracking reality was checked against the declared mode
- [ ] A personal ruleset found to be committed was reported as a problem, not a detail
- [ ] Leftover `@` imports from earlier versions were detected
- [ ] Gate commands were checked for continued existence
- [ ] Hand-added phrases were identified as user observations
- [ ] Nothing was written to disk
</success_criteria>

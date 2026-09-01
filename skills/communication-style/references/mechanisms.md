# Mechanisms — how the ruleset reaches a session

Verified against the installed Claude Code binary (v2.1.234), not against documentation or
research summaries. Both were wrong once each in this skill's history; the binary is the
authority.

<supported>

**`.claude/rules/*.md` — the mechanism this skill uses.**

Files in `.claude/rules/` are auto-loaded at session start. No import line is needed
anywhere. Evidence from the CLI binary:

- The literal glob `rules/*.md` appears in the loader.
- A prompt string lists what is always loaded: "the root file and `.claude/CLAUDE.md`
  (always loaded), nested-directory CLAUDE.md files ... and `.claude/rules/*.md`".
- The settings schema offers path exclusions with the example `"**/some-dir/.claude/rules/**"`.
  An exclusion setting only exists because these load by default.
- `.claude/rules/` appears in the list of Claude Code config surfaces alongside
  `CLAUDE.md`, `.claude/hooks/`, `.claude/commands/`, `.claude/agents/`, `.claude/skills/`.

**User scope works the same way.** The binary contains
`function vCt(){return join(claudeHome(),"rules")}`, using the same home-directory function
that resolves `~/.claude/CLAUDE.md`, and lists `rules` among the known `~/.claude`
subdirectories. So `~/.claude/rules/*.md` loads for every project on the machine.

**`paths` frontmatter is real.** The binary references a "`rules/*.md` file with `paths`
frontmatter". A rule file can scope itself to a glob so it loads only when Claude touches
matching files. This skill does not use it — a communication rule applies to every reply,
not to a file subset — but it is available.

**Because rules auto-load, this skill writes no import line at all.** That deletes an entire
class of bug: there is no way to leave an import pointing at a file that is not there, and
no way to split the artifact and its loader across the tracking boundary.

</supported>

<tracking>

**Default to personal. Never impose a communication style on a repository.**

A communication ruleset is a preference. Committing one makes every teammate who clones the
repo inherit how one person likes to be spoken to. Ask before tracking, default to not
tracking.

| Mode | Path | Tracked |
|------|------|---------|
| **personal (DEFAULT)** | `.claude/rules/communication.local.md` | No, via `.git/info/exclude` |
| shared | `.claude/rules/communication.md` | Yes, committed and reviewed in a PR |
| user | `~/.claude/rules/communication.md` | Touches nothing in the repo |

Both project filenames match the `rules/*.md` glob, so both auto-load. The `.local` segment
carries no meaning to Claude Code; it is a signal to human readers and the hook the ignore
rule matches on.

**Personal mode uses `.git/info/exclude`, not `.gitignore`.**

`.gitignore` is itself a tracked file, so writing to it still produces a diff in a repo you
may not own. `.git/info/exclude` has identical syntax and effect but is local-only and never
committed. A personal install therefore leaves `git status` completely clean — zero modified
files, zero untracked files.

```bash
mkdir -p .git/info
grep -qxF ".claude/rules/communication.local.md" .git/info/exclude 2>/dev/null   || printf '%s
' ".claude/rules/communication.local.md" >> .git/info/exclude
```

The trade-off, which the user should be told once: `.git/info/exclude` does not survive a
fresh clone, and no teammate can see the rule. Offer `.gitignore` instead when the user owns
the repo and wants the guard to persist and be visible.

</tracking>

<rejected>

**Output styles — DEPRECATED. Do not use.**

Anthropic ships a plugin, `explanatory-output-style`, whose stated purpose is to "recreate
the deprecated Explanatory output style as a SessionStart hook". Its README gives the
replacement guidance directly:

> this SessionStart hook pattern is roughly equivalent to CLAUDE.md, but it is more flexible
> and allows for distribution through plugins.

**`.claude.local.md` (leading dot) — DOES NOT EXIST. Do not use.**

Anthropic's `claude-md-management` plugin documents `./.claude.local.md` as "Personal/local
settings (gitignored, not shared)" in two separate files. That plugin is wrong, or stale.
The dotted form has **zero** occurrences in the CLI binary and is never loaded.

The real file is `CLAUDE.local.md`, uppercase, at the project root — 27 occurrences, and a
first-class memory type in the loader:

```js
case "User":    return join(homedir(), "CLAUDE.md");
case "Local":   return join(cwd, "CLAUDE.local.md");
case "Project": return join(cwd, "CLAUDE.md");
```

This skill does not use `CLAUDE.local.md` either, because `.claude/rules/` is cleaner and
needs no import line. It is recorded here only so nobody re-derives the wrong filename.

**Lesson worth keeping.** Two research passes and one official Anthropic plugin each gave a
wrong answer about these paths. Grepping the installed binary settled all of them in
minutes. Verify load paths against the binary, not against prose.

</rejected>

<precedence>

User-level rules load alongside project rules. A project file does not replace a user file;
both are in context. Installing at both scopes means two communication rulesets are active
at once, which is usually not what the user wants.

Warn when installing at project scope while `~/.claude/rules/communication.md` already
exists, and offer to remove one.

</precedence>

<verification>

After any install, confirm placement rather than assuming it:

```bash
# personal
test -f .claude/rules/communication.local.md
git check-ignore -q .claude/rules/communication.local.md && echo ignored
git status --short                      # expect no communication files at all

# shared
test -f .claude/rules/communication.md
git status --short                      # expect the file as a new tracked addition
```

Whether the file is actually being loaded cannot be confirmed from inside the session that
writes it. Rules load at session start. Tell the user to confirm next session by asking what
communication rules are active, and do not report the install as verified on file existence
alone.

</verification>

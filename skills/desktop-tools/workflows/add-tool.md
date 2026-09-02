# Workflow: Add a new tool

Everything a third tool touches. Work down in order; the checklist at the end makes a partial
addition visible.

A tool here is a standalone desktop program that ships with the plugin. It is not an agent, a
skill, or a command. See CLAUDE.md: `tools/` is exempt from the plugin's Execution Philosophy.

## 1. Scaffold `tools/<Name>/`

Copy the shape of the two existing tools:

```
tools/<Name>/
├── <entry>.py            the tray application and CLI
├── requirements.txt
├── README.md             usage, flags, the status contract, platform notes
├── icon.ico
├── install.bat  install.sh
├── run-<Name>.vbs        Windows, pythonw, no console
├── run-<Name>.command    macOS, nohup
└── run-debug.bat         Windows, python, console kept open
```

Every launcher cds to its own directory first. That is not cosmetic: both existing tools use
flat imports.

## 2. Implement the four-point contract

From `../references/tool-registry.md`. A tool meeting all four needs **no special-casing
anywhere in `toolctl.sh`**:

1. A PID lockfile under `~/.<name>/`, with stale-lock takeover.
2. `--status` printing the one-line `key=value` grammar, exit 0 either way.
3. `--stop` returning 0 when it stopped something, 1 when nothing ran, clearing the lockfile
   after confirming the process is gone.
4. Flat imports tolerating a cd-to-script-dir launch.

Copy the lock implementation from `tools/CronLike/cronlike.py` rather than writing a new one.
The Windows liveness check needs `GetExitCodeProcess` against `STILL_ACTIVE`, because a PID
stays openable while any handle to it is held; the naive `OpenProcess`-succeeded version is
wrong.

Point 3 is the one people skip. Without it, a terminated process leaves a lock naming a PID
Windows will eventually recycle, and `--status` then reports a stopped tool as running.

## 3. Add the registry row in BOTH places

- `skills/desktop-tools/references/tool-registry.md` — the table
- `scripts/tools/toolctl.sh` — the `REGISTRY` block near the top

**They are two copies of one fact.** Changing one without the other is a defect, and section 9
of the static-validation suite asserts that every directory under `tools/` has a row.

## 4. Write the reference file

Copy `../templates/tool-reference.md.template` to `../references/<toolkey>.md` and fill every
section, including "Honest limits". A reference that only lists capabilities makes Claude claim
things the tool cannot do.

If the tool owns a contract document of its own, the way CronLike owns `SCHEDULE.md`, point at
it and do not repeat it.

## 5. Wire it into the skill

- Add trigger phrases to `SKILL.md`'s `description`. Concrete phrasings, not an abstract
  summary, or it never auto-invokes.
- Add a row to `SKILL.md`'s `<tool_registry>` table and its `<reference_index>`.
- Add routing signals to `<routing>` if the tool introduces a new intent.
- Add a branch to `scripts/hooks/suggest-skill.sh` only if the existing desktop-tools branch
  does not already cover the phrasing.

## 6. Update the plugin docs

- `CLAUDE.md` — the Tools table
- `README.md` — the Tools table, and the skill/command counts if either changed

## 7. Update the static-validation suite

`scripts/tests/test-static-validation.sh`:

- New files into `REQUIRED`
- Any new markdown with frontmatter into `YAML_TARGETS`
- If the tool owns a contract document, add it to the section 9 pointer assertion

## 8. Decide whether it needs a command

**It probably does not.** `/KGP:tools:status` covers any registered tool, and
`toolctl.sh start|stop <key>` works the moment the row exists. Add a dedicated
`/KGP:tools:<name>` command only when the tool has configuration worth a guided workflow, the
way CronLike's schedule does.

If you do add one, follow `commands/tools/jiggler.md` for the minimal shape, and register it in
`YAML_TARGETS` and `REQUIRED` too.

## Checklist

```
[ ] tools/<Name>/ scaffolded, launchers cd to the script directory
[ ] Lockfile under ~/.<name>/ with stale takeover
[ ] --status prints the one-line grammar, exit 0 either way
[ ] --stop returns 0/1 correctly AND clears the lockfile
[ ] Registry row in references/tool-registry.md
[ ] Registry row in scripts/tools/toolctl.sh
[ ] references/<toolkey>.md written from the template, all sections filled
[ ] SKILL.md: description triggers, tool_registry row, reference_index entry
[ ] CLAUDE.md Tools table
[ ] README.md Tools table (+ counts if changed)
[ ] test-static-validation.sh: REQUIRED, YAML_TARGETS, section 9 if applicable
[ ] Command added, or a deliberate decision recorded that none is needed
[ ] bash scripts/tests/test-static-validation.sh reports Failed 0
[ ] toolctl.sh start/status/stop round trip verified on the new tool
```

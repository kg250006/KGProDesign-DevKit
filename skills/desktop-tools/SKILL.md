---
name: desktop-tools
description: Operate, configure, troubleshoot, and extend the standalone desktop tools shipped with KGProDesign-DevKit - CronLike (a human-readable job scheduler) and MouseJiggler (keeps the machine awake). Covers starting and stopping them, autostart at login, scheduling a command scoped to the repository you are working in, reading job logs, and adding a new tool. Use when asked to schedule something to run every morning, run a command daily in this repo, add a cron job, set up a recurring task on this machine, keep the machine awake or stop the screen locking, check whether the scheduler is running, find out why a job did not fire or did not run, start or stop the tray, or make a tool launch at login.
---

<essential_principles>

## S1. Never restate SCHEDULE.md

`tools/CronLike/SCHEDULE.md` is the field-and-error contract. It declares itself as such and
ties its error table to all 48 `raise` sites in `schedule_config.py`. Read it before any config
edit. Point at it; never copy a field definition into this skill.

A duplicated field table drifts from the parser silently, and the drift surfaces months later
as a job that quietly stopped firing. That is the exact failure CronLike was built to end.
`references/scheduling-patterns.md` is a recipe book, not a second reference. The boundary is
stated in that file and enforced by section 9 of `scripts/tests/test-static-validation.sh`.

## S2. These are programs, not agents

No PRP semantics, no retries, no job chaining, no orchestration. CronLike omits all of that
deliberately and documents the omission under "Not supported, deliberately". Respect it rather
than inventing a workaround. A user who wants retries wants a different tool, and saying so is
more useful than building a retry loop out of two scheduled jobs.

## S3. Config lives outside the plugin

`~/.cronlike/`, `~/.mousejiggler/`, `~/.kgp-tools/`. The plugin cache is version-stamped
(`~/.claude/plugins/cache/KGP/KGP/<version>/`) and disposable. Nothing the user cares about is
ever written inside it. See `references/install-and-update.md`.

## S4. `--check` is the gate

Every config change ends by running `python cronlike.py --check` and reporting the next fire
times. Nothing is called done on visual inspection. On failure, restore the backup and show
the parser's error verbatim rather than guessing at a second edit.

## S5. `toolctl.sh` is the only implementation of process control

`scripts/tools/toolctl.sh` owns start, stop, restart, status, logs, and autostart. This skill
and the four `/KGP:tools:*` commands are two front doors to one implementation. Never
reimplement a kill, a launch, or a status probe in a workflow.

</essential_principles>

<intake>

**First: detect state. Do not ask what you can observe.**

```bash
ROOT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/tools/plugin-root.sh")
bash "$ROOT/scripts/tools/toolctl.sh" status all
```

That one call answers whether each tool is installed, whether its dependencies are importable,
whether it is running, and what CronLike fires next.

**Then route on intent.** Show a menu only when the intent is genuinely ambiguous:

1. Start, stop, or check a tool
2. Schedule a job, or change one
3. Work out why something did not run
4. Add a new tool to the plugin

</intake>

<routing>

| Intent signals | Workflow |
|----------------|----------|
| start, stop, restart, status, "is it running", autostart, launch at login | `workflows/operate.md` |
| schedule, add a job, daily, every morning, weekdays, change a job, disable a job | `workflows/configure-schedule.md` |
| "did not run", "did it fire", failed, missed, logs, hung, timed out | `workflows/diagnose.md` |
| add a tool, new tool, register a tool, third tool | `workflows/add-tool.md` |

**After reading the workflow, follow it exactly.**

</routing>

<tool_registry>

Two tools ship today. The authoritative table, with the contract a new tool must satisfy, is
`references/tool-registry.md`. It and the registry block inside `scripts/tools/toolctl.sh` are
two copies of one fact and must be changed together.

| Tool | Key | Config | Reference |
|------|-----|--------|-----------|
| CronLike | `cronlike` | `~/.cronlike/` | `references/cronlike.md` |
| Mouse Jiggler | `jiggler` | `~/.mousejiggler/` | `references/mousejiggler.md` |

</tool_registry>

<reference_index>

All in `references/`:

- `tool-registry.md` - the extension point. One row per tool, plus the four-point contract a
  tool must meet to need no special-casing in `toolctl.sh`.
- `cronlike.md` - what lives in `~/.cronlike/`, hot reload, first-run seeding, the CLI verbs,
  and CronLike's real gotchas. Points at SCHEDULE.md for every field question.
- `mousejiggler.md` - operation, the single-instance lock, platform notes, and the honest
  limits of its CLI.
- `scheduling-patterns.md` - the recipe book. How to schedule the thing you actually want, as
  opposed to what the parser accepts.
- `install-and-update.md` - the version-stamped plugin cache, what survives an update, and
  what to check when autostart stops working.
- `troubleshooting.md` - symptom to cause to fix, across both tools. Every row names a command
  you can run or a file you can read.

</reference_index>

<workflows_index>

All in `workflows/`:

| File | Purpose | When to Use |
|------|---------|-------------|
| `operate.md` | start / stop / restart / status / logs / autostart | Any lifecycle request |
| `configure-schedule.md` | Add, edit, enable, disable, or remove a job | Any schedule change |
| `diagnose.md` | Ordered investigation of a job that did not run | "It did not fire" |
| `add-tool.md` | Every file a third tool touches, ending in a checklist | Adding a tool |

</workflows_index>

<templates_index>

| File | Purpose |
|------|---------|
| `templates/tool-reference.md.template` | The skeleton a new tool's reference file must fill, so tool three is documented like tools one and two. |

</templates_index>

<success_criteria>

- [ ] State was detected with `toolctl.sh status` before anything was asked
- [ ] SCHEDULE.md was read before any edit to `schedule.json`
- [ ] No field definition was restated in a reply or written into a skill file
- [ ] The config was backed up before editing and restored if `--check` failed
- [ ] `--check` was run after every config change and its next-fire times were reported
- [ ] The user was NOT told to restart CronLike after a config edit
- [ ] Process control went through `toolctl.sh`, never through an inline kill or launch
- [ ] A reported state was observed, not assumed
- [ ] `state=unavailable` was reported as a dependency problem, never as `stopped`

</success_criteria>

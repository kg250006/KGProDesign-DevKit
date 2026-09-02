---
description: "[KGP] List, add, edit, enable, disable, or remove CronLike jobs, scoped to the current project"
argument-hint: "[list|add|edit|enable|disable|remove|check] [job]"
allowed-tools: [Bash, Read, Edit, Glob, AskUserQuestion]
---

Manage CronLike scheduled jobs for: $ARGUMENTS

The live config is `~/.cronlike/schedule.json`. It is outside the plugin, so it survives every
plugin update.

## MANDATORY FIRST STEP for any verb that writes

Before touching the JSON, read the field contract:

```bash
ROOT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/tools/plugin-root.sh")
```

Then `Read "$ROOT/tools/CronLike/SCHEDULE.md"`.

It is the complete field reference, the three `when` composition rules, and every one of the
48 error messages the parser can raise. **Never restate a field definition in this command,
and never infer a field from an example.** A second copy of that reference drifts from the
parser, and the drift only surfaces months later as a job that quietly stopped firing.

## Read-only verbs

`list`, `check`, or no argument:

```bash
cd "$ROOT/tools/CronLike" && python cronlike.py --check
```

That prints every job, its schedule in plain English, and its next five fire times. Present it
as-is. Do not paraphrase the fire times.

## add

1. **Back up first.**
   ```bash
   cp ~/.cronlike/schedule.json ~/.cronlike/schedule.json.bak
   ```

2. **Derive what you can from the invoking directory.** Do not ask for these:
   - `cwd` — the project root you were invoked from. Write it in `~/...` form when it is under
     `$HOME`, absolute otherwise.
   - `name` — prefix with the repository's directory name, for example
     `"KGProDesign-DevKit regression"`. The name is the identity key for run state, so two
     repos sharing a job name would silently share catch-up history, and a duplicate name is
     a hard validation error.

3. **Ask only what cannot be derived:** the schedule, and the command to run. Use
   AskUserQuestion when the schedule is ambiguous.

4. **Edit `~/.cronlike/schedule.json`.** Preserve the existing formatting, including the blank
   lines between job objects. Use Edit, not Write: you are amending a config the user owns,
   not replacing it.

5. **Gate on `--check`.**
   ```bash
   cd "$ROOT/tools/CronLike" && python cronlike.py --check
   ```
   - **Fails** → restore the backup, print the parser's error verbatim, and stop. Do not
     attempt a second fix without showing the user what went wrong.
     ```bash
     cp ~/.cronlike/schedule.json.bak ~/.cronlike/schedule.json
     ```
   - **Passes** → show the new job's next five fire times.

6. **Say it is already live.** The scheduler reloads on mtime change within `check_every`.
   No restart. Do not tell the user to restart.

7. **Offer to prove it now** rather than at 08:00:
   ```bash
   /KGP:tools:cron run "<the new job name>"
   ```

## edit, enable, disable, remove

Same loop: back up, edit, `--check`, restore on failure. `enable` and `disable` flip the
`enabled` field. Point out that `enabled: false` keeps the job visible and greyed in the tray
and preserves its run history, whereas `remove` discards that history permanently.

## Warn when scheduling a Claude Code command

`runner.execute()` passes `stdin=subprocess.DEVNULL`. A scheduled `claude -p ...` job that hits
an interactive permission prompt cannot answer it and will hang until its `timeout` fires,
logging a timeout rather than a result. Say so at write time. The fix is to pre-approve the
tools the job needs, or to set an explicit permission mode in the command.

## Worked shape

Invoked from `~/PROJECTS/KGProDesign-DevKit`, "run the regression suite every weekday at 7":

```json
{ "name": "KGProDesign-DevKit regression",
  "when": { "days": "weekdays", "at": "07:00" },
  "run": "claude -p /KGP:run-regression",
  "cwd": "~/PROJECTS/KGProDesign-DevKit",
  "catch_up_within": "2 hours", "timeout": "20 minutes" }
```

`catch_up_within` defaults to zero, meaning a slot missed while the machine was asleep is
simply skipped. Set it deliberately on any job that matters. See SCHEDULE.md for what the
field accepts.

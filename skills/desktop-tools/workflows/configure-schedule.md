# Workflow: Configure a CronLike schedule

Add, edit, enable, disable, or remove a job in `~/.cronlike/schedule.json`.

## Step 0 — Read the contract. Mandatory, and first.

```bash
ROOT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/tools/plugin-root.sh")
```

Then `Read "$ROOT/tools/CronLike/SCHEDULE.md"`.

**Do not proceed to any edit without it.** It is the complete field reference, the three `when`
composition rules, and every one of the 48 error messages. Never restate a field definition and
never infer a field from an example: a second copy drifts from the parser and the drift only
surfaces as a job that quietly stopped firing.

For recipes rather than field definitions, read `../references/scheduling-patterns.md`.

## Step 1 — Back up

```bash
cp ~/.cronlike/schedule.json ~/.cronlike/schedule.json.bak
```

Every write verb does this first. It is what makes step 5's failure path safe.

## Step 2 — Derive what you can. Do not ask for these.

| Field | Derived from |
|-------|--------------|
| `cwd` | The directory you were invoked from. Write it in `~/...` form when under `$HOME`, absolute otherwise. |
| `name` | Prefix with the invoking repository's directory name, e.g. `"KGProDesign-DevKit regression"`. |

The name prefix is not cosmetic. `name` is the identity key for run state, so two repositories
scheduling a job called "regression" would share catch-up history, and the duplicate name is a
hard validation error anyway.

## Step 3 — Ask only what cannot be derived

The schedule, and the command to run. Use AskUserQuestion when the schedule is genuinely
ambiguous ("every morning" could be daily or weekdays). Do not ask about anything step 2
already answered.

## Step 4 — Edit

Use **Edit**, not Write. You are amending a config the user owns. Preserve the existing
formatting, including the blank lines between job objects.

## Step 5 — Gate on `--check`

```bash
cd "$ROOT/tools/CronLike" && python cronlike.py --check
```

**On failure:** restore the backup, print the parser's error verbatim, and stop.

```bash
cp ~/.cronlike/schedule.json.bak ~/.cronlike/schedule.json
```

Do not attempt a second fix without showing the user what went wrong. The error names the job
and the field, and SCHEDULE.md documents what it means. Silently iterating hides a
misunderstanding that will come back.

**On success:** show the new or changed job's next five fire times, from `--check`'s own
output. Do not paraphrase them.

## Step 6 — Say it is already live

The scheduler reloads `schedule.json` when its modification time changes, within `check_every`
(30 seconds by default). **Never tell the user to restart.**

## Step 7 — Offer to prove it now

```bash
cd "$ROOT/tools/CronLike" && python cronlike.py --run "<the job name>"
```

This fires the job immediately, outside its schedule, whether or not the tray is running. It is
the difference between knowing the command works and finding out tomorrow morning that it had a
typo. Always offer it after an `add`.

## Warn when the command is `claude -p ...`

`runner.execute()` passes `stdin=subprocess.DEVNULL`. A scheduled Claude Code command that hits
an interactive permission prompt cannot answer it and will hang until `timeout` fires, logging
a timeout instead of a result. Say this at write time, not after it happens. The fix is to
pre-approve the tools the job needs, or to set an explicit permission mode.

## Two things worth saying unprompted

**`catch_up_within` defaults to zero.** A slot missed while the machine was asleep is skipped
silently. Worse, `check_every` is 30 seconds, so a tick landing a few seconds after the slot
marks a zero-window job MISSED even on a machine that was awake. Any job that matters wants a
window of at least a minute.

**A job's first scheduled run is its next one.** Startup seeds `last_run` to now for any job
with no history, so a job added at 09:00 with an 08:00 slot does not fire until tomorrow. Say
so rather than letting the user think it failed.

## enable, disable, remove

Same backup, edit, `--check`, restore-on-failure loop. Point out the difference: `enabled:
false` keeps the job visible and greyed in the tray and preserves its run history, while
removing the object discards that history permanently. When someone says "turn this off", they
almost always mean disable.

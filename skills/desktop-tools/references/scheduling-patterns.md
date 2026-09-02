# Scheduling patterns

**The boundary, stated once so it does not blur:** `tools/CronLike/SCHEDULE.md` answers *what
the parser accepts*. This file answers *how to schedule the thing you actually want*. No field
definitions live here. When a field needs explaining, name it and point at SCHEDULE.md.

Every snippet below is a job object that goes in the `jobs` array of
`~/.cronlike/schedule.json`.

---

## Run a Claude Code command inside a specific repository

The most common thing anyone schedules, and the one with the most ways to go wrong.

```json
{ "name": "KGProDesign-DevKit regression",
  "when": { "days": "weekdays", "at": "07:00" },
  "run": "claude -p /KGP:run-regression",
  "cwd": "~/PROJECTS/KGProDesign-DevKit",
  "catch_up_within": "2 hours", "timeout": "20 minutes" }
```

Three things matter here and none are obvious.

**`cwd` is what makes it project-scoped.** Without it the command runs in CronLike's own
directory and the slash command resolves against the wrong project. Derive it from the
directory the user is sitting in rather than asking.

**Prefix the name with the repository.** `name` is the identity key for run state. Two repos
that both schedule "regression" would share catch-up history and, worse, the second one is a
hard validation error for duplicate names.

**Warn about the permission prompt.** `runner.execute()` passes `stdin=DEVNULL`. A headless
`claude -p` that hits an interactive approval cannot answer it and hangs until `timeout` fires,
logging a timeout instead of a result. Either pre-approve the tools the job needs, or give the
command an explicit permission mode.

## A job that must survive the machine being asleep

```json
{ "name": "Daily briefing",
  "when": { "days": "weekdays", "at": "08:00" },
  "run": "claude -p /pm:daily-briefing",
  "cwd": "~/PROJECTS/_ProjectManagement",
  "catch_up_within": "3 hours", "timeout": "20 minutes" }
```

`catch_up_within` defaults to **zero**, which means a slot missed while the laptop was closed
is skipped silently. That default is safe but rarely what someone wants for a job that
matters.

Pick the window from how long the output stays useful. A briefing is still worth reading at
11:00, so three hours. A "start of business" trigger is not worth firing at noon, so leave it
at zero and accept the skip.

Note the tick resolution too: `check_every` is 30 seconds, so a job with a zero window can be
marked MISSED simply because the tick landed a few seconds after the slot. Any job you actually
want to fire should have a window of at least a minute.

## Poll something during working hours

```json
{ "name": "WO poll",
  "when": { "days": "weekdays", "every": "30 minutes",
            "between": ["09:00", "17:00"] },
  "run": "claude -p /pm:wo-list",
  "cwd": "~/PROJECTS/_ProjectManagement" }
```

`every` with `between` narrows an interval to a daily window. Slots are anchored at the window
start, not at process start, so a 30-minute job lands on :00 and :30 rather than drifting to
:07 and :37 after a restart.

Windows do not wrap past midnight. An overnight poll is two jobs, not one.

## A job that sometimes runs long

```json
{ "name": "Board rebuild",
  "when": { "days": ["mon","fri"], "at": ["09:00", "16:30"] },
  "run": "python .scratch/kanban/build_kanban.py",
  "cwd": "~/PROJECTS/_ProjectManagement",
  "timeout": "30 minutes" }
```

`timeout` defaults to 15 minutes and a job that exceeds it is killed and logged as a failure.
Set it above the worst run you have actually seen, not the typical one.

If a slot arrives while the previous run is still going, the new dispatch is skipped and logged
as `SKIP: previous run still in progress`, and **the slot is consumed**. It does not fire late.
For a job that regularly overruns its interval, lengthen the interval rather than hoping.

## Prove a new job works now instead of at 08:00

```bash
python cronlike.py --run "KGProDesign-DevKit regression"
```

Fires immediately, outside the schedule, whether or not the tray is running. Prints the exit
code, duration, and log path. Always offer this after adding a job: the alternative is finding
out tomorrow morning that the command had a typo.

## Retire a job without losing its history

```json
{ "name": "Retired report", "enabled": false,
  "when": { "days": "weekdays", "at": "17:00" },
  "run": "python old_report.py" }
```

`enabled: false` keeps the job visible and greyed in the tray and preserves its run state.
Deleting the object discards that history permanently. When someone says "turn this off", they
usually mean disable.

## Use an argv array when quoting gets awkward

```json
{ "name": "Argv example",
  "when": { "days": "daily", "at": "12:00" },
  "run": ["python", "-c", "print('hello world')"] }
```

A `run` string is split on whitespace with quote handling. An array is used verbatim. Any
command containing quotes, or a path with spaces, is less trouble as an array.

## Check what actually happened

```bash
python cronlike.py --check          # every job, next 5 fire times
```

Per-run output is at `~/.cronlike/logs/<job-slug>-<date>.log`. The one-line-per-run summary
across all jobs is `~/.cronlike/logs/cronlike.log`, and its verdict column is the fastest way
to see whether a job ran, failed, was skipped, or was missed. `diagnose.md` walks that.

# CronLike schedule reference

The complete configuration reference. Every field the parser accepts and every error it raises is documented here.

Config lives at `~/.cronlike/schedule.json`. Create it with `python cronlike.py --init` and validate any edit with `python cronlike.py --check`, which prints each job's next 5 fire times so you can confirm the schedule resolves to what you meant.

Validation stops at the **first** problem found. Fix one error, re-run `--check`, and you may find another.

## Top-level shape

```json
{
  "version": 1,
  "settings": { },
  "jobs": [ ]
}
```

| Field | Type | Required | Meaning |
|-------|------|----------|---------|
| `version` | number | no | Format version. Accepted and carried, but not currently checked against anything. |
| `settings` | object | no | Scheduler-wide settings. Defaults apply when absent. |
| `jobs` | array | **yes** | The job list. May be empty. |

Any other top-level key is a hard error, never a silent no-op.

## settings

| Field | Type | Default | Meaning |
|-------|------|---------|---------|
| `check_every` | duration | `"30 seconds"` | How often the scheduler wakes to look for due jobs. This is the resolution of the whole tool. |
| `notify_on_failure` | bool | `true` | Raise a desktop notification when a job fails or the config breaks. |

## job fields

| Field | Type | Required | Default | Meaning |
|-------|------|----------|---------|---------|
| `name` | string | **yes** | - | Non-empty and unique. It keys the run history, so renaming a job resets its catch-up state. |
| `when` | object | **yes** | - | The schedule. See [The `when` object](#the-when-object). |
| `run` | string or array | **yes** | - | The command. A string is split on whitespace with quote handling; an array is used verbatim and avoids every quoting question. |
| `enabled` | bool | no | `true` | `false` keeps the job visible in the tray, greyed, but never fires it. |
| `cwd` | path string | no | CronLike's own directory | Working directory for the command. `~` is expanded. |
| `catch_up_within` | duration | no | `"0 seconds"` | How late a missed run may still fire. See [Catch-up](#catch-up). |
| `timeout` | duration | no | `"15 minutes"` | Kill the command after this long and log a failure. |

Any other job key is a hard error.

## The `when` object

| Key | Accepts | Default |
|-----|---------|---------|
| `days` | `"daily"`, `"weekdays"`, `"weekends"`, or a list from `["mon","tue","wed","thu","fri","sat","sun"]` | `"daily"` |
| `at` | `"08:00"` or `["09:00","16:30"]` - 24-hour, local wall-clock time | - |
| `every` | a duration, for example `"30 minutes"` or `"2 hours"` | - |
| `between` | a two-element list, `["09:00","17:00"]` - only valid with `every` | `["00:00","23:59"]` |
| `day_of_month` | a number or list of numbers, 1 to 31 - intersects with `days` | - |

### Three composition rules

1. **`at` and `every` are mutually exclusive.** Use one, never both.
2. **Exactly one of `at` or `every` is required.** A `when` with neither is an error.
3. **`between` requires `every`.** It narrows an interval to a daily window and means nothing without one.

A fourth rule lives outside `when`: **`name` must be unique across all jobs**, because it is the identity key for run state.

`day_of_month` intersects with `days` rather than replacing it. `{"days": "weekdays", "day_of_month": [1]}` fires only when the 1st falls on a weekday.

## Durations

`"<whole number> <unit>"`, one space between them.

| Unit | Accepted spellings |
|------|--------------------|
| second | `second`, `seconds` |
| minute | `minute`, `minutes` |
| hour | `hour`, `hours` |

`"1 minute"` and `"1 minutes"` are both accepted. There is no day or week unit; use `"24 hours"`. Negative amounts are rejected.

## Times

`"HH:MM"`, 24-hour, zero-padded or not, hour 0 to 23 and minute 0 to 59. Local wall-clock time. There is no seconds field.

## Worked examples

**A fixed time on weekdays.** The most common shape.

```json
{ "name": "Daily briefing",
  "when": { "days": "weekdays", "at": "08:00" },
  "run": "claude -p /pm:daily-briefing",
  "cwd": "~/PROJECTS/_ProjectManagement",
  "catch_up_within": "3 hours", "timeout": "20 minutes" }
```

**Several times a day.** `at` takes a list.

```json
{ "name": "Board rebuild",
  "when": { "days": "daily", "at": ["09:00", "13:00", "16:30"] },
  "run": "python build_kanban.py",
  "cwd": "~/PROJECTS/_ProjectManagement" }
```

**Specific weekdays.** Give `days` a list of three-letter names.

```json
{ "name": "Twice-weekly summary",
  "when": { "days": ["tue", "thu"], "at": "06:30" },
  "run": "claude -p /pm:weekly-summary",
  "cwd": "~/PROJECTS/_ProjectManagement",
  "catch_up_within": "1 hour" }
```

**An interval inside a window.** `every` with `between`, so it does not run all night.

```json
{ "name": "WO poll",
  "when": { "days": "weekdays", "every": "30 minutes",
            "between": ["09:00", "17:00"] },
  "run": "claude -p /pm:wo-list",
  "cwd": "~/PROJECTS/_ProjectManagement" }
```

**An interval with no window.** Drop `between` and it runs around the clock on the days you name.

```json
{ "name": "Heartbeat",
  "when": { "days": "daily", "every": "2 hours" },
  "run": "python heartbeat.py" }
```

**Day of month.** Intersected with `days`, which defaults to `"daily"`.

```json
{ "name": "Month-start archive",
  "when": { "day_of_month": [1, 15], "at": "08:30" },
  "run": "claude -p /pm:archive --dry-run",
  "cwd": "~/PROJECTS/_ProjectManagement" }
```

**A disabled job.** Stays in the tray, greyed, and never fires.

```json
{ "name": "Retired report", "enabled": false,
  "when": { "days": "weekdays", "at": "17:00" },
  "run": "python old_report.py" }
```

**An argv array.** Use this whenever the command contains quotes, spaces in paths, or anything else you would rather not reason about.

```json
{ "name": "Argv example",
  "when": { "days": "daily", "at": "12:00" },
  "run": ["python", "-c", "print('hello world')"] }
```

A complete multi-job config is shipped as `schedule.example.json`, which is also what `--init` copies.

## Catch-up

A slot is **outstanding** when the job has no recorded run, or its recorded run predates the slot. On each tick, every outstanding slot gets one of three verdicts:

| Verdict | When | What happens |
|---------|------|--------------|
| FIRE | lateness is within `catch_up_within` | The command runs, logged as `catch-up for HH:MM` if it was late |
| MISSED | lateness exceeds `catch_up_within` | Nothing runs. Logged as `slot HH:MM older than <window> window` |
| IDLE | no outstanding slot, or the job is disabled | Nothing happens |

**`catch_up_within` defaults to 0 seconds**, meaning no catch-up: a slot missed because the machine was asleep is simply skipped. Set it deliberately on any job that matters.

**First-run seeding.** At startup every job with no recorded run is given a `last_run` of *now*. Without this, launching at 16:00 would treat the whole day's earlier slots as outstanding and fire a backlog at once. The cost is that a job's very first scheduled run is its next one, never a retroactive one.

**State advances on MISSED too.** Both verdicts record the slot before anything is dispatched, so the same slot is never evaluated twice. This is what makes double-firing impossible, including for a job that takes longer than one tick.

**A job already running is not started again.** If its next slot arrives mid-run, the new dispatch is skipped and logged as `SKIP: previous run still in progress`. The slot is still consumed.

## Not supported, deliberately

- **Cron expressions.** The format is meant to be readable and writable without knowing cron.
- **Seconds granularity.** Times are `HH:MM`. The practical floor is `check_every`, 30 seconds by default.
- **Timezones.** Everything is local wall-clock time. A job scheduled inside the hour skipped by a spring-forward does not fire that day.
- **Job chaining and dependencies.** Jobs do not know about each other and run in parallel threads.
- **Retries.** A failed job is logged and, if `notify_on_failure` is on, notified. It is not retried; the next scheduled slot is its next chance.
- **Anything beyond the fields in this document.** Unknown keys are rejected rather than ignored, at the top level, in `settings`, in a job, and in `when`.

## Every error message

`--check` prints these prefixed with `Invalid config:`. The tray shows them in the menu and turns the icon red.

In the Message column, `{job}` is the job name (or `jobs[N]` when the name itself is missing or unusable), `{field}` is the field name, and `{value}` is what you wrote.

### Loading

| Message | Cause | Fix |
|---------|-------|-----|
| `No schedule file at {path}. Run: python cronlike.py --init` | No config exists yet | Run `--init` |
| `Could not read {path}: {os error}` | Permissions, or the file vanished mid-read | Check file permissions on `~/.cronlike/` |
| `{path} is not valid JSON: {reason} at line {n} column {n}` | JSON syntax error, usually a trailing comma or an unquoted key | Fix the JSON at the line and column given |

### Top level

| Message | Cause | Fix |
|---------|-------|-----|
| `Top level of schedule.json must be an object` | The file's root is an array or a scalar | Wrap it in `{ }` |
| `unknown top-level field "{k}". Valid fields: jobs, settings, version` | Typo or an invented key at the root | Use only the three listed |
| `schedule.json must contain a "jobs" array` | No `jobs` key | Add `"jobs": []` |
| `"jobs" must be an array` | `jobs` is an object or a scalar | Wrap the jobs in `[ ]` |

### settings

| Message | Cause | Fix |
|---------|-------|-----|
| `"settings" must be an object` | `settings` is not `{ }` | Make it an object |
| `settings: unknown field "{k}". Valid fields: check_every, notify_on_failure` | Typo or an invented setting | Use one of the two listed |
| `settings: "notify_on_failure" must be true or false` | A string or number was given | Use the JSON literal `true` or `false`, unquoted |

### Job structure

| Message | Cause | Fix |
|---------|-------|-----|
| `jobs[{i}]: each job must be an object` | An array entry is a string or number | Make every entry `{ }` |
| `jobs[{i}]: missing required field "name"` | No `name` key | Add one |
| `jobs[{i}]: "name" must be a non-empty string` | `name` is blank, whitespace, or not a string | Give it real text |
| `job "{job}": missing required field "run"` | No `run` key | Add the command |
| `job "{job}": missing required field "when"` | No `when` key | Add the schedule |
| `duplicate job name "{name}". Names must be unique; they key the run history.` | Two jobs share a name | Rename one. Renaming resets that job's catch-up state |
| `job "{job}": unknown field "{k}". Valid fields: catch_up_within, cwd, enabled, name, run, timeout, when` | Typo, or a field that belongs inside `when` | Use a listed field. `days`, `at`, `every`, `between`, and `day_of_month` go inside `when`, not beside it |

### Job field values

| Message | Cause | Fix |
|---------|-------|-----|
| `job "{job}": "enabled" must be true or false` | Quoted `"true"`, or a number | Use the unquoted JSON literal |
| `job "{job}": "run" must be a command string or an argv list` | `run` is a number or an object | Use a string or an array of strings |
| `job "{job}": "run" must not be empty` | `run` is `""` or whitespace | Give it a command |
| `job "{job}": "run" argv list must not be empty` | `run` is `[]` | Add at least the executable |
| `job "{job}": every entry in the "run" argv list must be a string` | An array entry is a number or nested array | Quote every element, including numeric arguments |
| `job "{job}": "cwd" must be a path string` | `cwd` is not a string | Quote the path |

### The `when` object

| Message | Cause | Fix |
|---------|-------|-----|
| `job "{job}": "when" must be an object` | `when` is a string or array | Make it `{ }` |
| `job "{job}": unknown "when" field "{k}". Valid: at, between, day_of_month, days, every` | Typo, or a job field placed inside `when` | Use a listed key. `catch_up_within`, `timeout`, `cwd`, and `run` belong beside `when`, not inside it |
| `job "{job}": "at" and "every" are mutually exclusive. Use one.` | Both keys present | Delete one. Use `at` for fixed times, `every` for intervals |
| `job "{job}": "when" needs either "at" or "every".` | Neither key present | Add one |
| `job "{job}": "between" requires "every".` | `between` without `every` | Add `every`, or drop `between` |

### `days`

| Message | Cause | Fix |
|---------|-------|-----|
| `job "{job}": "days" value "{value}" is not a known group. Valid groups: daily, weekdays, weekends, or a list of fri, mon, sat, sun, thu, tue, wed` | A string that is not one of the three groups, such as `"monday"` or `"mon"` | Use a group name, or a **list** for individual days: `["mon"]` |
| `job "{job}": "days" must be a group name or a list of day names` | `days` is a number or an object | Use a string or an array |
| `job "{job}": "days" list must not be empty` | `days` is `[]` | List at least one day, or omit `days` for the `"daily"` default |
| `job "{job}": "days" entry "{d}" is not a day name. Valid: fri, mon, sat, sun, thu, tue, wed` | A full name, a capital, or a typo | Use lowercase three-letter names |
| `unknown day group "{spec}". Valid groups: daily, weekdays, weekends` | Normalization-stage guard on a group name | Should not be reachable through `--check`; report it if you see it |
| `unknown day name "{name}". Valid: fri, mon, sat, sun, thu, tue, wed` | Normalization-stage guard on a day name | Should not be reachable through `--check`; report it if you see it |

### Times: `at`, `between`

| Message | Cause | Fix |
|---------|-------|-----|
| `job "{job}": "at" must not be empty` | `at` is `[]` | Give at least one time |
| `"{field}" must be a "HH:MM" string, got {type}` | A number such as `800`, or `null` | Quote it: `"08:00"` |
| `"{field}" value "{value}" is not a "HH:MM" 24-hour time` | Missing colon, extra parts, or non-digits, such as `"8am"` or `"09:00:00"` | Use exactly `HH:MM` |
| `"{field}" value "{value}" has hour {h}; must be 0-23` | 12-hour thinking, such as `"25:00"` | Use 24-hour time |
| `"{field}" value "{value}" has minute {m}; must be 0-59` | Minute out of range | Correct the minute |
| `job "{job}": "between" must be a two-element list, for example ["09:00", "17:00"]` | A string, or the wrong number of elements | Give exactly two times |
| `job "{job}": "between" start "{a}" must be earlier than end "{b}"` | Start at or after end, such as an overnight window | Windows do not wrap past midnight. Use two jobs |

### Durations: `check_every`, `every`, `catch_up_within`, `timeout`

| Message | Cause | Fix |
|---------|-------|-----|
| `"{field}" must be a duration string like "30 minutes", got {type}` | A bare number such as `30` | Quote it with a unit: `"30 minutes"` |
| `"{field}" value "{value}" is not a duration like "30 minutes"` | Missing space, missing unit, or a non-numeric amount, such as `"30m"` or `"half an hour"` | Use `"<number> <unit>"` |
| `"{field}" has unrecognised unit "{unit}". Valid units: hour, hours, minute, minutes, second, seconds` | A day, week, or abbreviated unit | Use seconds, minutes, or hours. For a day, write `"24 hours"` |
| `"{field}" value "{value}" must not be negative` | A negative amount | Use zero or more |
| `job "{job}": "every" must be greater than zero` | `"0 seconds"` | An interval must be positive |

### `day_of_month`

| Message | Cause | Fix |
|---------|-------|-----|
| `job "{job}": "day_of_month" entry "{d}" must be a whole number 1-31` | A string such as `"1"`, a float, or a bool | Use unquoted integers |
| `job "{job}": "day_of_month" entry {d} is out of range; must be 1-31` | `0`, `32`, or a negative | Use 1 to 31. A job on the 31st simply does not fire in shorter months |

**Maintenance rule:** this table is the contract. `schedule_config.py` must not raise a `ConfigError` whose message is absent from it, and no message here may be absent from the parser. There are 48 raise sites; every one is covered above.

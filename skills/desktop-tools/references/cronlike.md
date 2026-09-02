# CronLike

A scheduler with a human-readable JSON config and a tray icon. Runs commands on a clock.

> **Field definitions, the three `when` composition rules, durations, times, catch-up
> semantics, and every one of the 48 error messages live in `tools/CronLike/SCHEDULE.md`.**
> Read that file before editing config. This one does not repeat any of it, deliberately: a
> second copy would drift from the parser and the drift would only show up as a job that
> quietly stopped firing.

For recipes rather than field definitions, see `scheduling-patterns.md`.

## What lives in `~/.cronlike/`

| Path | What it is | Safe to delete? |
|------|------------|-----------------|
| `schedule.json` | Your jobs. The only file you edit. | No. Back it up first. |
| `state.json` | Last-run timestamp per job, keyed by job name. Drives catch-up. | Yes, but every job is re-seeded to "now", so the next run is the next scheduled slot. |
| `cronlike.lock` | PID of the running scheduler. | Yes when the scheduler is stopped. A lock naming a dead PID is taken over automatically. |
| `logs/` | One file per job per day, plus `cronlike.log`, the run summary. | Yes. Recreated on demand. |

None of this is inside the plugin, so it all survives a plugin update. See
`install-and-update.md`.

## Editing the schedule never requires a restart

The tick loop compares `schedule.json`'s modification time on every pass and reloads when it
moves (`_check_config_changed`, `tools/CronLike/cronlike.py`). A change is live within
`check_every`, 30 seconds by default.

**Never tell the user to restart after a config edit.** If they just saved the file, it is
already live or will be within half a minute.

A half-written or invalid file is also safe. `load_config()` never raises: the previously
loaded jobs keep running, the error is surfaced in the tray menu, and the icon turns red. That
is why a typo cannot take the scheduler down.

## First-run seeding

At startup every job with no recorded run gets a `last_run` of *now*. Without this, launching
at 16:00 would treat the whole day's earlier slots as outstanding and fire a backlog at once.

The cost, worth saying out loud to a user who expects otherwise: **a job's very first
scheduled run is its next one, never a retroactive one.** A job added at 09:00 with an 08:00
slot does not fire until tomorrow.

## Command line

Run from `tools/CronLike/`. `toolctl.sh` and the `/KGP:tools:cron` command wrap all of these.

| Flag | What it is for |
|------|----------------|
| `--init` | Seed `~/.cronlike/schedule.json` from the shipped example. Never overwrites. |
| `--check` | Validate and print every job with its next 5 fire times. **The gate after every edit.** |
| `--run "<name>"` | Fire one job now, outside its schedule. Works whether or not the tray is running. |
| `--status` | One status line. See the contract in `tool-registry.md`. |
| `--stop` | Stop the running scheduler. Exit 1 when nothing was running. |
| `--generate-ico` | Regenerate `icon.ico`. |

No flag starts the tray.

## Gotchas

**stdin is `/dev/null`.** `runner.execute()` passes `stdin=subprocess.DEVNULL`, because Claude
Code headless print mode has crashed on Windows when stdin is unreadable, and a
pythonw-launched tray has no console stdin anyway. A scheduled `claude -p ...` job that hits an
interactive permission prompt cannot answer it and hangs until `timeout` fires. Warn about this
whenever a job's command starts with `claude`.

**The job name is the identity key for run state.** Renaming a job resets its catch-up history,
because `state.json` is keyed by name. Two jobs sharing a name is a hard validation error. Job
names created from inside a repository should be prefixed with the repository name so two
projects cannot collide.

**A job already running is skipped, not queued.** If the next slot arrives mid-run, the new
dispatch is logged as `SKIP: previous run still in progress` and **the slot is consumed**. It
does not fire late.

**Run state advances before dispatch, for both FIRE and MISSED.** That is what makes
double-firing impossible, including for a job that takes longer than one tick.

**`catch_up_within` defaults to zero.** A slot missed because the machine was asleep is simply
skipped, silently. Set it deliberately on any job that matters.

**Everything is local wall-clock time.** No timezones. A job scheduled inside the hour skipped
by a spring-forward does not fire that day.

## What it deliberately does not do

Cron expressions, seconds granularity, timezones, job chaining or dependencies, and retries. A
failed job is logged and notified, not retried; its next scheduled slot is its next chance.
These are documented omissions, not gaps to work around. See SCHEDULE.md, "Not supported,
deliberately".


---
description: "[KGP] Start, stop, inspect, autostart, or hand-fire jobs on the CronLike scheduler"
argument-hint: "[start|stop|restart|status|run <job>|logs [job]|autostart on|off]"
allowed-tools: [Bash, Read]
---

Control the CronLike scheduler for: $ARGUMENTS

Resolve the plugin root once and reuse it:

```bash
ROOT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/tools/plugin-root.sh")
TOOLCTL="$ROOT/scripts/tools/toolctl.sh"
```

## Smart Routing

| Argument | Action |
|----------|--------|
| *(none)*, `status` | `bash "$TOOLCTL" status cronlike` |
| `start` | `bash "$TOOLCTL" start cronlike` |
| `stop` | `bash "$TOOLCTL" stop cronlike` |
| `restart` | `bash "$TOOLCTL" restart cronlike` |
| `run <job>` | `cd "$ROOT/tools/CronLike" && python cronlike.py --run "<job>"` |
| `logs`, `logs <job>` | `bash "$TOOLCTL" logs ["<job>"]` |
| `autostart on\|off\|status` | `bash "$TOOLCTL" autostart <action> cronlike` |

Anything else: show this table rather than guessing.

## What each verb actually does

**start** is idempotent. If the scheduler is already running it reports the existing PID and
exits 0. Starting something already started is success, not an error. The launch is verified
by a follow-up status query, so what you report is observed, not assumed.

**stop** exits 1 when nothing was running. That is information, not a failure: say "it was
not running" rather than reporting an error.

**run `<job>`** fires one job immediately, outside its schedule. **It works whether or not the
tray is running**, because it executes the command directly rather than asking the scheduler
to. Use it to prove a new job works now instead of finding out at 08:00. Report the exit code,
the duration, and the log path from the command's own output.

**logs** with no job lists the ten most recent log files. With a job name it tails today's log
for that job. A job that has not fired today has no log, and that is reported as a fact with
exit 0, not as an error.

**autostart** writes a stable launcher to `~/.kgp-tools/` and a Startup entry (Windows) or a
LaunchAgent (macOS) that points at it. Nothing outside `~/.kgp-tools/` stores a plugin path,
so a `/plugin update` does not break it. Report the paths the command prints.

## Editing the schedule never needs a restart

CronLike reloads `schedule.json` whenever its modification time changes, within `check_every`
(30 seconds by default). **Never tell the user to restart after a config change.** If they
just edited the schedule, the correct answer is that it is already live, or will be within
half a minute.

To change jobs, use `/KGP:tools:schedule`, not this command.

## Common Invocations

```bash
/KGP:tools:cron                      # is it running, and what fires next
/KGP:tools:cron start                # bring the tray up
/KGP:tools:cron run "Daily briefing" # fire one job now, tray or no tray
/KGP:tools:cron logs "Daily briefing"
/KGP:tools:cron autostart on         # launch at login
```

# CronLike

A system tray scheduler that runs commands on a human-readable JSON schedule. Works on both **Windows** and **macOS**. As long as it is running, it fires what you tell it to fire.

CronLike is an ordinary desktop program. It has no notion of agents, tasks, or retries: it runs whatever command string you put in a config field, on a clock.

## Quick start

```bash
pip install -r requirements.txt
python cronlike.py --init      # creates ~/.cronlike/schedule.json
# edit that file
python cronlike.py --check     # confirm it parses and see the next fire times
```

Then start the tray: double-click `run-CronLike.vbs` on Windows, or `run-CronLike.command` on macOS.

The complete configuration reference is in [SCHEDULE.md](SCHEDULE.md). Read that before editing `schedule.json`.

## Installation

1. Ensure Python 3.8+ is installed
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
   On Windows you can run `install.bat` instead, and on macOS `install.sh`. Both do the same `pip install` from this directory.

> **macOS note:** desktop notifications may require permission on first use. If a failed job never produces a notification, see Troubleshooting.

## Usage

### Standard Launch

```bash
python cronlike.py
```

A green clock icon appears in your system tray (Windows) or menu bar (macOS). The scheduler is now live. See [The tray menu](#the-tray-menu) for what the icon offers.

### Windows: Hidden Launch (No Console Window)

For a clean launch with no console window, use the VBScript launcher:

```bash
wscript run-CronLike.vbs
```

Or double-click `run-CronLike.vbs` in Windows Explorer. It sets the working directory, installs dependencies if they are missing, and starts the scheduler under `pythonw.exe`, the windowless Python interpreter. The tray icon stays visible for control.

**Tip:** put `run-CronLike.vbs` in your Windows Startup folder so the scheduler starts when you log in. This is the launcher that belongs there. `run-debug.bat` keeps a console window open and is for troubleshooting, not for startup.

### macOS: Background Launch

```bash
./run-CronLike.command
```

It installs missing dependencies, starts the scheduler under `nohup`, and closes the Terminal window it came from.

**Tip:** add `run-CronLike.command` to your Login Items (System Settings > General > Login Items) to start it automatically.

### Command line

| Flag | What it does |
|------|--------------|
| `--init` | Create `~/.cronlike/schedule.json` from `schedule.example.json` if it does not exist. Never overwrites an existing config. |
| `--check` | Validate the config and print each job with its next 5 fire times. Exit 0 when valid, exit 1 with the error message when not. |
| `--run "Job Name"` | Run one job immediately, outside its schedule. For testing. Prints the exit code, duration, and log path. |
| `--generate-ico` | Regenerate `icon.ico` at seven sizes from the active icon design. |

With no flag, CronLike starts the tray application.

## The tray menu

| Item | Behaviour |
|------|-----------|
| Next: ... | Informational, not clickable. The next enabled job due and when. Reads "No jobs scheduled" when nothing is due. |
| ! ... | Informational. Appears only when there is an error, showing the config or job failure message. |
| Jobs > | One entry per job, labelled with its name and a plain-English schedule. Each opens a submenu with **Run now** and a **Disabled** toggle. |
| Pause all | Suspends scheduling passes. The worker thread stays alive and nothing fires. Shows a checkmark while paused. |
| Reload config | Re-reads `schedule.json` immediately. The scheduler also reloads on its own whenever the file's modification time changes. |
| Open config file | Opens `schedule.json` in your default editor. |
| Open log folder | Opens `~/.cronlike/logs/`. |
| Exit | Stops the scheduler and releases the single-instance lock. |

**Icon colours**, in order of precedence:

| Colour | Meaning |
|--------|---------|
| Red | The config is invalid, or the last job run failed |
| Gray | Paused |
| Blue | A job is running right now |
| Green | Active and idle |

A **Disabled** toggle set from the tray lasts until the next config reload. To disable a job permanently, set `"enabled": false` in `schedule.json`.

## How It Works

A worker thread wakes on a fixed tick (`check_every`, 30 seconds by default), asks each job whether a slot is due, and dispatches what is. The tick sleeps in 0.1-second slices rather than one long sleep, so Exit stays responsive instead of stalling for a full interval.

Each dispatched job runs in its own thread, so a slow job never delays the tick loop or another job. A job that is still running when its next slot arrives is skipped rather than started twice, and that skip is logged.

**Run state is advanced before the command starts**, for both a fired and a missed slot. That is what makes double-firing impossible: once a slot is recorded, it is never re-evaluated.

**Catch-up.** If the machine was asleep or CronLike was closed when a slot came due, the job fires late as long as the delay is inside its `catch_up_within` window. Outside the window the slot is recorded as MISSED and nothing runs. A job that has never run is seeded at first launch, so a fresh install does not fire a whole day's backlog at once.

**Config errors do not stop the scheduler.** A bad edit turns the icon red, surfaces the message in the menu, and leaves the previously loaded jobs running. Fix the file and it reloads on its own.

**Command resolution is explicit, not shell-delegated.** A command string is split with `shlex` and `argv[0]` is resolved on PATH; an argv array is used verbatim, which avoids every quoting question. On Windows a target that resolves to a `.cmd` or `.bat` shim, which is how npm-installed tools like `claude` appear, is wrapped as `[COMSPEC, /c, ...]`, because `CreateProcess` cannot execute those directly.

Jobs run with `stdin` closed, with `CREATE_NO_WINDOW` on Windows so nothing flashes at fire time, and with `CRONLIKE_JOB` set to the job name in their environment.

### Logs

Two kinds, both under `~/.cronlike/logs/`:

- `cronlike.log` — one line per run, the whole history at a glance:
  ```
  [2026-09-02 07:45:03] [OK]     Pull Linear (12.4s, exit 0)
  [2026-09-02 08:31:10] [OK]     Daily briefing (catch-up for 08:00, 94.1s, exit 0)
  [2026-09-02 11:02:00] [FAIL]   WO poll (exit 1) see wo-poll-2026-09-02.log
  [2026-09-02 09:00:00] [MISSED] Daily briefing (slot 08:00 older than 1h window)
  ```
- `<job-name>-<date>.log` — the command's own stdout and stderr, appended per run under a timestamped header.

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| A job never fires | Run `python cronlike.py --check`. Confirm the job is enabled and that today matches its `days`. The command prints the next 5 fire times per job, so a schedule that resolves to something you did not intend is visible there. |
| `%1 is not a valid Win32 application` | A `.cmd` or `.bat` shim was invoked directly. CronLike wraps these through `COMSPEC` automatically, so if you see this, the command resolved to something unexpected. Check the output of `--run "Job Name"`. |
| `command not found on PATH: "x"` | `argv[0]` does not resolve. Use an absolute path, or an argv array, in `run`. |
| Job runs but appears to do nothing | Read `~/.cronlike/logs/<job-name>-<date>.log`. The command's own output is there, including anything it wrote to stderr. |
| A job is stuck | It is killed at its `timeout`, 15 minutes by default, and logged as `timed out after Ns`. Raise `timeout` for genuinely long jobs. |
| Two icons in the tray | Should be impossible: the lockfile prevents a second instance, which exits with `CronLike is already running (PID n)`. Delete `~/.cronlike/cronlike.lock` only if no CronLike process is running. |
| No notifications on macOS | Grant notification permission to your terminal or to Python in System Settings. Notification delivery is best-effort by design and a missing notifier never stops a scheduled run. |
| Config edits ignored | The icon turns red on a config error and the menu shows the message. Run `--check` to see it in full. |
| A missed run never fired | Its delay exceeded `catch_up_within`, which defaults to 0. Look for a `[MISSED]` line in `cronlike.log` naming the window. |

## Features

- Cross-platform: Windows and macOS
- Human-readable JSON schedule, no cron expressions
- System tray / menu bar icon with four-state colour: green active, blue running, gray paused, red error
- Run any job on demand from the tray or with `--run`
- Catch-up windows for runs missed while the machine was asleep or the app was closed
- Automatic config reload on file change, and a config error that never takes the scheduler down
- Per-job logs plus a single rolling summary log
- Per-job working directory and timeout
- Single-instance locking
- Hidden launch with no console window on Windows

## Requirements

- Python 3.8+
- Windows or macOS
- Dependencies:
  - pystray >= 0.19.0
  - Pillow >= 10.0.0

  pystray declares its own darwin-gated pyobjc requirement, so nothing extra is needed on macOS.

## Files

| File | Description |
|------|-------------|
| `cronlike.py` | Main application: icon rendering, worker loop, tray interface, and CLI |
| `schedule_config.py` | Config loading, validation, and normalization |
| `scheduler.py` | Schedule arithmetic: next fire time, due-job selection, run state |
| `runner.py` | Command resolution, execution, and logging |
| `schedule.example.json` | Worked example config, and the seed for `--init` |
| `SCHEDULE.md` | Complete configuration reference |
| `README.md` | This file |
| `requirements.txt` | Python package dependencies |
| `install.bat` | Windows dependency installer |
| `install.sh` | macOS dependency installer |
| `run-CronLike.vbs` | Windows hidden launcher (no console window) |
| `run-CronLike.command` | macOS background launcher |
| `run-debug.bat` | Windows launcher that keeps a console window open |
| `icon.ico` | Windows icon, seven sizes |

Runtime files live in `~/.cronlike/`: `schedule.json`, `state.json`, `cronlike.lock`, and `logs/`.

## License

MIT

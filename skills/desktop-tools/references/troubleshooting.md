# Troubleshooting

Every row names a command you can run or a file you can read. Nothing here is a guess.

`$ROOT` is the resolved plugin root, `$T` is `$ROOT/scripts/tools/toolctl.sh`.

## CronLike: a job did not run

| Symptom | Cause | Check | Fix |
|---------|-------|-------|-----|
| No log line at all for the slot | The scheduler was not running when the slot passed | `bash "$T" status cronlike` | `bash "$T" start cronlike`, then `autostart on` so it survives a reboot |
| No log line, scheduler was running | The job was added after the slot, and first-run seeding set `last_run` to now | `python cronlike.py --check` shows the next slot | Expected. A job's first scheduled run is its next one, never retroactive |
| `[MISSED] ... older than <window> window` | Lateness exceeded `catch_up_within`, which defaults to 0 seconds | The `cronlike.log` line names the window | Raise `catch_up_within`. Anything you actually want to fire needs at least a minute, because `check_every` is 30s |
| `[SKIP] previous run still in progress` | The prior run had not finished. The slot is consumed, not queued | `cronlike.log` | Raise `timeout`, or lengthen the interval so runs cannot overlap |
| `[FAIL] ... exit N` | The command itself failed | `bash "$T" logs "<job name>"` for the command's own output | Fix the command. Test with `python cronlike.py --run "<job>"` |
| Job hangs until `timeout`, log ends mid-run | A `claude -p` job hit an interactive permission prompt. stdin is `DEVNULL`, so it cannot answer | The log stops with no output after the command line | Pre-approve the tools, or set an explicit permission mode in the command |
| Job runs but in the wrong project | `cwd` is missing, so it ran in CronLike's own directory | The job object in `~/.cronlike/schedule.json` | Add `cwd` |
| A renamed job lost its catch-up history | `state.json` is keyed by job name | `~/.cronlike/state.json` | Expected. Renaming is a new identity |

## CronLike: config and state

| Symptom | Cause | Check | Fix |
|---------|-------|-------|-----|
| Tray icon is red | The config is invalid, or the last run failed | `python cronlike.py --check` | Fix the field the error names. SCHEDULE.md documents every message |
| An edit seems to have no effect | Waiting on the tick | Up to `check_every`, 30s by default | Wait. **Never restart.** Reload is automatic on mtime change |
| `duplicate job name` | Two jobs share a name, which is the run-state key | `python cronlike.py --check` | Rename one. Prefix repo-scoped jobs with the repo name |
| `"between" requires "every"` | `between` used with `at` | `python cronlike.py --check` | `between` narrows an interval, so it needs `every`. See SCHEDULE.md |
| Nothing scheduled at all | The scheduler is not running | `bash "$T" status cronlike` | `bash "$T" start cronlike` |

## Both tools: lifecycle

| Symptom | Cause | Check | Fix |
|---------|-------|-------|-----|
| `state=unavailable reason=missing-deps` | `pystray` or `Pillow` is not importable. **Not the same as stopped** | `python -c "import pystray, PIL"` | `pip install -r "$ROOT/tools/<Tool>/requirements.txt"` |
| `toolctl.sh` exits 2 naming python | No interpreter on PATH | `command -v python3 python` | Install Python 3.8+, or fix PATH |
| `toolctl.sh` exits 2 naming the plugin root | The resolver found no install containing `tools/` | `bash "$ROOT/scripts/tools/plugin-root.sh"; echo $?` | Update the plugin, or set `KGP_PLUGIN_ROOT` |
| `... is already running (PID N)` on start | A live instance holds the lock | `bash "$T" status <tool>` | Nothing to do, or stop it first |
| Start says it did not come up within 5s | The process exited immediately | Run it in the foreground from its own directory to see the error | Usually a missing dependency or an import error |

## Autostart

| Symptom | Cause | Check | Fix |
|---------|-------|-------|-----|
| Nothing starts at login | The shim could not resolve the plugin | `~/.kgp-tools/launch.log` | Update the plugin. Every failure is logged with a timestamp |
| Stopped working after a plugin update | Should not happen; the shim re-resolves every launch | `~/.kgp-tools/launch.log` | Re-run `bash "$T" autostart on <tool>` and read the log |
| macOS: plist exists but nothing runs | `launchctl load` did not take | `launchctl list \| grep com.kgprodesign` | `bash "$T" autostart off <tool>` then `on`. The command reports the verified load state |

## Mouse Jiggler

| Symptom | Cause | Check | Fix |
|---------|-------|-------|-----|
| Running, but the cursor never moves | macOS Accessibility permission not granted | System Settings, Privacy and Security, Accessibility | Grant it, then restart the tool. Status correctly says `running`, because it is |
| Two tray icons | An instance predating the single-instance lock | Task Manager or Activity Monitor | End the extra one, then start through `toolctl.sh` |
| No `--pause` flag | Pause is a tray-menu action only | `mousejiggler.md` | Right-click the icon, or use `stop` |
| `toolctl.sh logs jiggler` returns nothing useful | It keeps no logs | The command says so | Expected |

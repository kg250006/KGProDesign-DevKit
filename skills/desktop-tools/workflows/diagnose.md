# Workflow: Why did it not run?

An ordered investigation. Each step is cheaper than the next and rules out a whole class of
cause, so work down and stop at the first one that explains the symptom.

```bash
ROOT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/tools/plugin-root.sh")
T="$ROOT/scripts/tools/toolctl.sh"
```

## 1. Is the scheduler even running?

```bash
bash "$T" status cronlike
```

`state=stopped` explains everything downstream: nothing evaluates slots when nothing is
running. Start it, then offer `autostart on` so a reboot does not silently end automation
again.

`state=unavailable` is a dependency problem, not a stopped tool. Go to
`../references/troubleshooting.md`.

## 2. Is the config valid?

```bash
cd "$ROOT/tools/CronLike" && python cronlike.py --check
```

A red tray icon means the same thing. An invalid config does not stop the scheduler: the
previously loaded jobs keep running and the error surfaces in the tray. So a job added into a
file that later broke will never have loaded at all.

## 3. Is the job enabled, and does its next fire time match what the user expects?

`--check` prints every job with `(disabled)` where applicable, its schedule in plain English,
and its next five fire times. A schedule that resolves to something other than what the user
meant is visible right here, and this is where most "it did not run" reports actually end.

## 4. What verdict did the slot get?

```bash
tail -20 ~/.cronlike/logs/cronlike.log
```

One line per run across all jobs. Four verdicts are possible, and each has a different cause:

| Verdict | Means | Where to go |
|---------|-------|-------------|
| `OK` | It ran, exit 0 | Step 7. The job ran; the complaint is about what it did |
| `FAIL` | It ran, non-zero exit or it timed out | Step 7 |
| `MISSED` | Step 5 | The slot was outstanding but too late to fire |
| `SKIP` | Step 6 | The previous run was still going |

**No line at all for the slot:** step 8.

## 5. MISSED

```
[MISSED] <job> (slot HH:MM older than <window> window)
```

Lateness exceeded `catch_up_within`, which **defaults to zero seconds**. The machine was
probably asleep. But note the tick resolution too: `check_every` is 30 seconds, so a job with a
zero window is marked MISSED even on an awake machine when the tick lands a few seconds after
the slot.

Fix: raise `catch_up_within` to something matching how long the output stays useful. Anything
you actually want to fire needs at least a minute.

## 6. SKIP

```
[SKIP] <job>: previous run still in progress
```

The prior run had not finished when the next slot arrived. The dispatch was skipped and **the
slot was consumed** — it does not fire late.

Fix: raise `timeout` if runs are legitimately long, or lengthen the interval so two runs cannot
overlap. Do not try to make them queue; CronLike deliberately does not do that.

## 7. FAIL, or OK but wrong output

```bash
bash "$T" logs "<job name>"
```

That is the job's own stdout and stderr for today. Read what the command actually said.

Two failure shapes are worth recognising on sight:

- **The log ends mid-run with no output, and the verdict is a timeout.** A `claude -p` job hit
  an interactive permission prompt. stdin is `DEVNULL`, so it could not answer. Pre-approve the
  tools, or set an explicit permission mode.
- **The command ran but against the wrong project.** `cwd` is missing, so it ran in CronLike's
  own directory.

## 8. No log line at all

Two causes, and `--check` distinguishes them.

**The scheduler was not running when the slot passed.** Back to step 1. Check whether the
process start time postdates the slot.

**The job was added after the slot, and first-run seeding applies.** At startup every job with
no recorded run is given a `last_run` of now, so it never fires retroactively. A job added at
09:00 with an 08:00 slot does not run until tomorrow. This is correct behaviour and the most
common surprise with a brand-new job.

## Then

Map the finding onto `../references/troubleshooting.md` for the fix. Do not restate the fixes
here; that table is the single place they live.

Verify any change with `--check`, and offer `--run "<job>"` to prove the fix now rather than at
the next slot.

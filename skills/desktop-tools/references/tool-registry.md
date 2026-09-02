# Tool registry

The extension point. Adding a tool to this plugin costs one row here, one row in
`scripts/tools/toolctl.sh`, and one reference file. The skill router's logic never changes.

## The tools

| Tool | Key | Dir | Entry | Config | Lifecycle verbs | Reference | Routes on |
|------|-----|-----|-------|--------|-----------------|-----------|-----------|
| CronLike | `cronlike` | `tools/CronLike/` | `cronlike.py` | `~/.cronlike/` | start, stop, restart, status, autostart, run, logs | `cronlike.md` | schedule, cron, job, daily, every morning, "did not run" |
| Mouse Jiggler | `jiggler` | `tools/MouseJiggler/` | `mouse_jiggler.py` | `~/.mousejiggler/` | start, stop, status, autostart | `mousejiggler.md` | awake, screen lock, idle, jiggle, sleep timer |

`Dir` is relative to the plugin root, which is resolved at run time by
`scripts/tools/plugin-root.sh`. Never write it out as an absolute path: the plugin cache is
version-stamped and any absolute path goes stale on the next update.

## Maintenance rule

**This table and the `REGISTRY` block in `scripts/tools/toolctl.sh` are two copies of one
fact.** Changing either without the other is a defect. Section 9 of
`scripts/tests/test-static-validation.sh` asserts that every directory under `tools/` appears
here, so a tool added without a row is caught mechanically.

## The contract a tool must satisfy

A tool meeting all four points needs no special-casing anywhere in `toolctl.sh`. It is
registered, and everything works.

**1. A PID lockfile under its own `~/.<name>/` directory.**
Written at startup, removed on clean exit. A lock naming a process that is no longer alive is
stale and gets taken over automatically, so a crash never needs manual cleanup. Copy the
implementation from `tools/CronLike/cronlike.py`; the Windows liveness check is subtle and the
naive version is wrong.

**2. `--status` printing the one-line grammar.**
Exactly one line to stdout, exit 0, whether or not the tool is running. Space-separated
`key=value` pairs. `state` is always present and is `running` or `stopped`. `pid` appears only
when running. A value containing a space is double-quoted. A tool may add its own keys, as
CronLike adds `next` and `at`.

```
state=running pid=24180
state=running pid=24180 next="Daily briefing" at=2026-09-02T08:00
state=stopped
```

**3. `--stop` returning 0 when it stopped something, 1 when nothing was running.**
It must clear the lockfile after confirming the process is gone. A terminated process never
reaches its own cleanup, and Windows recycles PIDs, so a stale lock makes `--status` report a
stopped tool as running and makes the next `start` refuse.

**4. Flat imports with a cd-to-script-dir launcher.**
Both existing tools import their siblings without a package, so the working directory must be
the tool's own directory. `toolctl.sh` and `launch.py` both cd before launching. A tool that
uses a proper package layout is fine too, but must still tolerate being launched that way.

## Deciding whether a new tool needs a command

It probably does not. `/KGP:tools:status` already covers any registered tool, and
`toolctl.sh start|stop <key>` works the moment the row exists. Add a dedicated
`/KGP:tools:<name>` command only when the tool has configuration worth a guided workflow, the
way CronLike's schedule does. A tool with no config is served by `status` plus the generic
verbs.

See `../workflows/add-tool.md` for the full procedure and its closing checklist.

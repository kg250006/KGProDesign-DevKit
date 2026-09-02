# Workflow: Operate a desktop tool

Start, stop, restart, inspect, read logs, or set a tool to launch at login.

## Step 0 — Resolve the root once

```bash
ROOT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/tools/plugin-root.sh")
T="$ROOT/scripts/tools/toolctl.sh"
```

Reuse `$T` for every step. Never hardcode a plugin path: the cache is version-stamped and any
literal path breaks on the next update.

## Step 1 — Observe before acting

```bash
bash "$T" status all
```

Report state that was observed, never state that was assumed. If the user asks to start
something that is already running, say so instead of starting it again.

## Step 2 — Dispatch the verb

| Intent | Command |
|--------|---------|
| start | `bash "$T" start <tool>` |
| stop | `bash "$T" stop <tool>` |
| restart | `bash "$T" restart <tool>` |
| logs | `bash "$T" logs ["<job name>"]` |
| autostart | `bash "$T" autostart <on\|off\|status> <tool>` |

`<tool>` is `cronlike` or `jiggler`. See `../references/tool-registry.md`.

**Never inline a kill or a launch.** No `taskkill`, no `kill`, no `pythonw`, no `nohup` in this
workflow. `toolctl.sh` is the only implementation of process control, and a second one would
diverge from it. If a verb you need is missing, that is a change to `toolctl.sh`, not a
workaround here.

## Step 3 — Re-verify and report

`toolctl.sh` already re-queries after `start` and `restart` and prints the verified line. Pass
that through rather than paraphrasing it. For anything else that changes state, query again:

```bash
bash "$T" status <tool>
```

## Reading exit codes

| Exit | Meaning | What to do |
|------|---------|------------|
| 0 | Succeeded | Report the result |
| 1 | Tool-level: nothing was running to stop, or a launch did not come up | Report it as information, not as an error. "It was not running" is an answer |
| 2 | **Environment problem.** No plugin root, no interpreter, or missing dependencies | **Stop.** Do not try to start anything |

### The exit-2 stop condition

Exit 2 means the tool could not be asked, not that it is stopped. Report which of the three it
is, from the message:

- **No plugin root** → the resolver found no install containing `tools/`. Update the plugin, or
  set `KGP_PLUGIN_ROOT`.
- **No interpreter** → Python 3.8+ is not on PATH.
- **`state=unavailable reason=missing-deps`** → `pystray` or `Pillow` is not importable. Give
  the install command:
  ```bash
  pip install -r "$ROOT/tools/CronLike/requirements.txt"
  ```

Never report any of these as `stopped`. That sends the user hunting for a tray icon when the
real problem is an import. See `../references/troubleshooting.md`.

## Autostart specifics

`autostart on` installs `~/.kgp-tools/launch.py` and writes a Startup entry (Windows) or a
LaunchAgent (macOS) pointing at it. On macOS the command confirms with `launchctl list` and
reports the **verified** load state; a plist written but not loaded is autostart that never
fires, and the command says so rather than claiming success.

Report the paths the command prints. Tell the user that a plugin update does not break it,
because the shim resolves at launch time, and that `~/.kgp-tools/launch.log` is where to look
if it ever stops working.

`autostart off` removes the entry but leaves `~/.kgp-tools/` in place, since the other tool may
still use the shim. That is intentional, not an incomplete uninstall.

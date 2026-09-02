---
description: "[KGP] Start, stop, inspect, or autostart the Mouse Jiggler tray tool"
argument-hint: "[start|stop|status|autostart on|off]"
allowed-tools: [Bash, Read]
---

Control the Mouse Jiggler for: $ARGUMENTS

Resolve the plugin root once and reuse it:

```bash
ROOT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/tools/plugin-root.sh")
TOOLCTL="$ROOT/scripts/tools/toolctl.sh"
```

## Smart Routing

| Argument | Action |
|----------|--------|
| *(none)*, `status` | `bash "$TOOLCTL" status jiggler` |
| `start` | `bash "$TOOLCTL" start jiggler` |
| `stop` | `bash "$TOOLCTL" stop jiggler` |
| `autostart on\|off\|status` | `bash "$TOOLCTL" autostart <action> jiggler` |

Anything else: show this table rather than guessing.

## What it does

Moves the cursor four pixels and back every 60 seconds, alternating direction, so the screen
does not lock and sleep timers do not fire. The movement uses `SendInput` on Windows and
CoreGraphics on macOS, at the OS input layer.

## Notes worth giving the user

**Only one runs at a time.** A PID is recorded in `~/.mousejiggler/mousejiggler.lock`. A second
launch refuses rather than starting a duplicate. `start` on an already-running jiggler reports
the existing PID and exits 0.

**Pause is a tray-menu action only.** There is no `--pause` flag and this command does not add
one. Stopping and starting is the command-line equivalent. If the user asks to pause, tell
them to right-click the tray icon, or offer `stop`.

**stop exits 1 when nothing was running.** That is information, not a failure.

**macOS needs Accessibility permission.** Without it the process runs and the icon appears, but
the cursor never moves. If a macOS user reports it doing nothing, that is the first thing to
check: System Settings, Privacy and Security, Accessibility.

## Common Invocations

```bash
/KGP:tools:jiggler                # is it running
/KGP:tools:jiggler start          # keep this machine awake
/KGP:tools:jiggler stop
/KGP:tools:jiggler autostart on   # launch at login
```

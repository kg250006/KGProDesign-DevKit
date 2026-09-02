# Mouse Jiggler

Keeps the machine awake by moving the cursor imperceptibly. Tray icon, Windows and macOS.

## What it does

Moves the cursor four pixels diagonally and back every 60 seconds, alternating direction each
cycle. Small enough to be invisible during normal use, large enough that the OS counts it as
input and does not lock the screen or start a sleep timer.

The movement goes in at the OS input layer, not through a higher-level automation library:
`SendInput` via `user32.dll` on Windows (`win32_input.py`), `CGEventCreateMouseEvent` and
`CGEventPost` via Quartz on macOS (`macos_input.py`). `mouse_input.py` picks the backend at
import time. Both inject *relative* movement, so the cursor never teleports.

## Single instance

A PID is written to `~/.mousejiggler/mousejiggler.lock` at startup and removed on clean exit.
A second launch prints `Mouse Jiggler is already running (PID N).` to stderr and exits 1 rather
than starting a duplicate.

Before this existed, nothing stopped several jigglers running at once and nothing could tell
which one was live. If a user reports two tray icons, one predates the lock and has to be ended
from Task Manager or Activity Monitor.

A lock naming a process that is no longer alive is stale and is taken over automatically, so a
crash never needs manual cleanup.

## Command line

Run from `tools/MouseJiggler/`. `toolctl.sh` and `/KGP:tools:jiggler` wrap all of these.

| Flag | What it is for |
|------|----------------|
| `--status` | One status line. See the contract in `tool-registry.md`. |
| `--stop` | Stop the running jiggler. Exit 1 when nothing was running. |
| `--generate-ico` | Regenerate `icon.ico`. |

No flag starts the tray.

## Honest limits

**There is no `--pause`.** Pause is a tray-menu action only, and this is deliberate: pausing is
a live toggle on a running process, and a CLI flag would have to signal it somehow. Stopping
and starting is the command-line equivalent. If a user asks to pause from the command line,
say so and offer `stop` rather than pretending.

**No configurable interval.** 60 seconds is hardcoded in `MouseJiggler.__init__`. Changing it
means editing the source.

**No logs.** Nothing is recorded. `toolctl.sh logs jiggler` says so rather than failing.

## Platform notes

**macOS Accessibility permission.** On first run macOS prompts to grant Accessibility to the
terminal or to Python. Without it the process starts, the menu-bar icon appears, and the cursor
never moves. This is the most common "it does nothing" report on macOS, and status will
correctly say `running`, because the process genuinely is. Point the user at System Settings,
Privacy and Security, Accessibility.

**Windows console.** Launching with `pythonw` (which `toolctl.sh` does) gives no console
window. `python` would leave one open.

**Corporate machines.** Some managed environments treat synthetic input as a policy violation.
That is a question for the user's IT policy, not a bug to fix here.


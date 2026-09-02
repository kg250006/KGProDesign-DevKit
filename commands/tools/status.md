---
description: "[KGP] Report install path, dependency health, and running state for the plugin's desktop tools"
argument-hint: ""
allowed-tools: [Bash, Read]
---

Report the state of every standalone desktop tool shipped with this plugin. Read-only: this
command never starts, stops, or configures anything.

## Run

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/tools/toolctl.sh" status all
```

If `${CLAUDE_PLUGIN_ROOT}` is not set in this context, resolve it first and use the result:

```bash
ROOT=$(bash "${CLAUDE_PLUGIN_ROOT:-.}/scripts/tools/plugin-root.sh") || \
  ROOT=$(bash ./scripts/tools/plugin-root.sh)
bash "$ROOT/scripts/tools/toolctl.sh" status all
```

## Present

Turn the raw status lines into a short table:

| Tool | State | PID | Detail |
|------|-------|-----|--------|

For CronLike, put the `next` job and its `at` time in Detail. For a stopped tool, leave PID
and Detail empty rather than inventing a value.

## Reading the exit code

| Exit | Meaning | What to say |
|------|---------|-------------|
| 0 | The query succeeded | Report the table |
| 2 | Environment problem | Report what is missing, not a tool state |

**`state=unavailable` is not `state=stopped`.** Unavailable means python or a dependency is
missing, so the tool could not be asked. Say which dependency, and give the install command
from that tool's own directory:

```bash
pip install -r "$ROOT/tools/CronLike/requirements.txt"
```

Conflating the two sends the user to debug the wrong thing: they will go looking for a stopped
tray when the real problem is that `pystray` is not importable.

## Follow-ups worth offering

- A stopped tool the user expects to be running: `/KGP:tools:cron start` or `/KGP:tools:jiggler start`
- CronLike running but a job did not fire: `/KGP:tools:cron logs "<job name>"`
- Neither tool set to launch at login: `/KGP:tools:cron autostart on`

Do not run any of these. Offer them and stop.

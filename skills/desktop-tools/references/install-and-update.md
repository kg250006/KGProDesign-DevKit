# Install layout, and what survives an update

The single most important fact about this plugin's layout: **the install path carries a version
number**, so every path into the plugin goes stale on the next update.

## Where the plugin actually lives

```
~/.claude/plugins/
├── installed_plugins.json          <- names the live version
└── cache/KGP/KGP/
    ├── 2.4.0/                      <- old installs are kept
    ├── 2.7.0/
    └── <next version>/             <- a new directory every update
```

`installed_plugins.json` maps `KGP@KGP` to an array of entries, each with an `installPath` and
a `version`. The array is not ordered, so **resolve by highest version, never by index 0.**

## Why this matters

Anything that records an absolute plugin path once, and reads it back later, breaks silently
the next time the plugin updates. Silent breakage of scheduled automation is the exact failure
CronLike was built to end, so the plugin resolves the root at run time instead:

| Resolver | Used by | How it resolves |
|----------|---------|-----------------|
| `scripts/tools/plugin-root.sh` | The four commands and `toolctl.sh` | `$CLAUDE_PLUGIN_ROOT`, then the manifest, then its own location for a source checkout |
| `~/.kgp-tools/launch.py` | Autostart entries | `$KGP_PLUGIN_ROOT`, then the manifest. Carries its own copy, because resolving the plugin is the thing it does. |

Both check that the candidate directory actually contains `tools/CronLike/cronlike.py`. A path
that merely exists is not proof it is usable: an installed version older than the one that
first shipped `tools/` has no tools directory at all, and the resolver must skip it rather than
hand back a broken root.

## Survives an update

- `~/.cronlike/` - schedule, run state, lock, logs
- `~/.mousejiggler/` - lock
- `~/.kgp-tools/` - the autostart shim and its log
- The Windows Startup `.vbs` and the macOS LaunchAgent plist, because they point at the shim
  and never at a versioned path

## Does not survive an update

Anything written inside the plugin directory. It is a cache: treat it as read-only and
disposable. Never write config, state, or user data there.

## After a plugin update

Nothing to do. The shim re-resolves on every launch, so the next login picks up the new
version automatically. There is no re-run of `autostart on` needed.

## When autostart stops working

`~/.kgp-tools/launch.log` is the first place to look. Every failure path in the shim writes a
timestamped line there, precisely so a failure is never silent. The two lines you are likely to
see:

```
could not resolve the plugin root for 'cronlike'; set KGP_PLUGIN_ROOT or reinstall the plugin
resolved root <path> but <path>/tools/CronLike/cronlike.py is missing
```

Both mean the manifest names no install that contains `tools/`. Reinstall or update the plugin.
As an escape hatch, setting `KGP_PLUGIN_ROOT` in the environment overrides resolution entirely,
which is also how a source checkout is used instead of an install.

## Dependencies

`pystray` and `Pillow` (plus `pyobjc-framework-Quartz` on macOS) are installed globally by pip,
not vendored into the plugin. They survive an update, and an update does not reinstall them. If
`toolctl.sh status` reports `state=unavailable reason=missing-deps`, install from the tool's own
directory:

```bash
pip install -r "$ROOT/tools/CronLike/requirements.txt"
```

That is a dependency problem, not a stopped tool. Saying "stopped" sends the user to look for a
tray icon when the real problem is an import.

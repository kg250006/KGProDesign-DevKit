#!/usr/bin/env python3
"""Stable launcher for the KGProDesign-DevKit desktop tools.

Copied to ~/.kgp-tools/launch.py by `toolctl.sh autostart on`. Autostart
entries (a Windows Startup .vbs, a macOS LaunchAgent plist) point at that copy
and never at the plugin itself.

This file must never contain a version-stamped path. The plugin cache is
version-stamped, so anything that captures a plugin path once goes stale on the
next update. This launcher survives updates precisely because it resolves the
plugin root at launch time, every time.

Usage: launch.py {cronlike|jiggler}
"""

import json
import os
import sys

from datetime import datetime
from pathlib import Path


TOOLS = {
    'cronlike': ('tools/CronLike', 'cronlike.py'),
    'jiggler': ('tools/MouseJiggler', 'mouse_jiggler.py'),
}

MARKER = 'tools/CronLike/cronlike.py'


def log_dir():
    """Return ~/.kgp-tools/, creating it if absent."""
    d = Path.home() / '.kgp-tools'
    try:
        d.mkdir(parents=True, exist_ok=True)
    except OSError:
        pass
    return d


def log(message):
    """Append a timestamped line to ~/.kgp-tools/launch.log.

    A silent autostart failure is the exact defect this whole feature exists to
    prevent, so every failure path leaves a trace. Logging itself never raises.
    """
    try:
        path = log_dir() / 'launch.log'
        with open(path, 'a', encoding='utf-8') as fh:
            fh.write("%s %s\n" % (datetime.now().strftime('%Y-%m-%d %H:%M:%S'), message))
    except OSError:
        pass


def _valid(root):
    """Return True when this directory is a usable plugin root.

    The content check matters: an installed plugin version older than the one
    that first shipped tools/ has no tools directory, so a path that merely
    exists is not proof it is usable.
    """
    return bool(root) and (Path(root) / MARKER).is_file()


def _version_key(value):
    """Sort key for a dotted version string. Unparseable parts sort as zero."""
    parts = []
    for chunk in str(value or '0').split('.'):
        digits = ''.join(c for c in chunk if c.isdigit())
        parts.append(int(digits) if digits else 0)
    return parts


def resolve_root():
    """Return the live plugin root, or None.

    Order: the KGP_PLUGIN_ROOT escape hatch, then the installed-plugin
    manifest. The manifest entry with the highest version wins rather than the
    first one, because the array is not ordered and a stale entry must not win.
    """
    env = os.environ.get('KGP_PLUGIN_ROOT')
    if _valid(env):
        return env

    manifest = Path.home() / '.claude' / 'plugins' / 'installed_plugins.json'
    try:
        with open(manifest, encoding='utf-8') as fh:
            data = json.load(fh)
    except (OSError, ValueError):
        return None

    entries = (data.get('plugins') or {}).get('KGP@KGP') or []
    for entry in sorted(entries, key=lambda e: _version_key(e.get('version')), reverse=True):
        candidate = (entry.get('installPath') or '').replace('\\', '/')
        if _valid(candidate):
            return candidate
    return None


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in TOOLS:
        given = sys.argv[1] if len(sys.argv) > 1 else '(none)'
        message = 'bad tool name %r; valid names: %s' % (given, ', '.join(sorted(TOOLS)))
        log(message)
        print('launch.py: %s' % message, file=sys.stderr)
        return 1

    key = sys.argv[1]
    root = resolve_root()
    if root is None:
        log('could not resolve the plugin root for %r; set KGP_PLUGIN_ROOT or '
            'reinstall the plugin' % key)
        print('launch.py: could not resolve the plugin root', file=sys.stderr)
        return 1

    subdir, entry = TOOLS[key]
    target = Path(root) / subdir / entry
    if not target.is_file():
        log('resolved root %s but %s is missing' % (root, target))
        print('launch.py: %s is missing' % target, file=sys.stderr)
        return 1

    # Flat imports: both tools expect their own directory to be the cwd, which
    # is why every launcher shipped with them cds first.
    try:
        os.chdir(str(target.parent))
    except OSError as exc:
        log('could not enter %s: %s' % (target.parent, exc))
        return 1

    # sys.executable inherits whatever launched this shim, so a pythonw-driven
    # autostart stays windowless without naming an interpreter here.
    try:
        os.execv(sys.executable, [sys.executable, entry])
    except OSError as exc:
        log('could not exec %s %s: %s' % (sys.executable, entry, exc))
        print('launch.py: could not start %s' % entry, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

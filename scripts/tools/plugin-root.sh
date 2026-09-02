#!/bin/bash
# Print the live KGProDesign-DevKit plugin root on stdout and exit 0.
# Print nothing and exit 1 when no valid root can be found.
#
# Resolution order:
#   1. $CLAUDE_PLUGIN_ROOT, when set and valid
#   2. ~/.claude/plugins/installed_plugins.json -> plugins["KGP@KGP"] installPath
#   3. this script's own location, walking up two levels (source checkout)
#
# "Valid" means the directory exists AND contains tools/CronLike/cronlike.py.
# The content check matters: the plugin cache is version-stamped, and an
# installed version older than 2.8.0 has no tools/ directory at all. A path
# that merely exists is not proof it is usable.
#
# Output never contains a backslash, so callers can use it directly in bash
# paths on Windows.

set -u

_norm() {
  # Normalise a Windows path to forward slashes and strip any trailing slash.
  printf '%s' "$1" | tr '\\' '/' | sed 's:/*$::'
}

_valid() {
  [ -n "${1:-}" ] && [ -d "$1" ] && [ -f "$1/tools/CronLike/cronlike.py" ]
}

# --- 1. Environment ---------------------------------------------------------

if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  candidate="$(_norm "$CLAUDE_PLUGIN_ROOT")"
  if _valid "$candidate"; then
    printf '%s\n' "$candidate"
    exit 0
  fi
fi

# --- 2. Installed-plugin manifest ------------------------------------------

_py() {
  command -v python3 2>/dev/null || command -v python 2>/dev/null || true
}

manifest="$HOME/.claude/plugins/installed_plugins.json"
py="$(_py)"

if [ -n "$py" ] && [ -f "$manifest" ]; then
  # Pick the highest version, not index 0: the array is not ordered and a
  # stale first entry must not win over the current install.
  candidate="$("$py" - "$manifest" <<'PYEOF' 2>/dev/null
import json, sys

def key(v):
    parts = []
    for chunk in str(v or "0").split("."):
        digits = "".join(c for c in chunk if c.isdigit())
        parts.append(int(digits) if digits else 0)
    return parts

try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        data = json.load(fh)
except Exception:
    sys.exit(0)

entries = (data.get("plugins") or {}).get("KGP@KGP") or []
paths = [e.get("installPath") for e in entries if e.get("installPath")]
if not paths:
    sys.exit(0)
best = max(entries, key=lambda e: key(e.get("version")))
print((best.get("installPath") or "").replace("\\", "/"))
PYEOF
)"
  candidate="$(_norm "$candidate")"
  if _valid "$candidate"; then
    printf '%s\n' "$candidate"
    exit 0
  fi
fi

# --- 3. Source checkout -----------------------------------------------------

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || here=""
if [ -n "$here" ]; then
  candidate="$(_norm "$(cd "$here/../.." 2>/dev/null && pwd)")"
  if _valid "$candidate"; then
    printf '%s\n' "$candidate"
    exit 0
  fi
fi

exit 1

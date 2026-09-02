#!/bin/bash
# Single implementation of desktop-tool process control for KGProDesign-DevKit.
#
# Usage: toolctl.sh <verb> [tool] [args]
#
#   status    [cronlike|jiggler|all]     default: all
#   start     <tool>
#   stop      <tool>
#   restart   <tool>
#   logs      [job name | jiggler]       CronLike only
#   autostart <on|off|status> <tool>
#
# Exit codes:
#   0  the verb succeeded
#   1  a tool-level failure (nothing was running to stop, launch never came up)
#   2  an environment problem (no plugin root, no interpreter, missing deps)
#
# Exit 2 is deliberately distinct from "stopped": reporting a tool as stopped
# when the real problem is a missing interpreter sends the user to debug the
# wrong thing.
#
# The four /KGP:tools:* commands and the desktop-tools skill both call this
# script. Neither reimplements process control.

set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Registry ---------------------------------------------------------------
#
# Adding a tool is adding one row here plus a reference file in the
# desktop-tools skill. Keep this in step with
# skills/desktop-tools/references/tool-registry.md: they are two copies of one
# fact.
#
#   <key>|<dir under the plugin root>|<entry point>|<label>

REGISTRY="cronlike|tools/CronLike|cronlike.py|CronLike
jiggler|tools/MouseJiggler|mouse_jiggler.py|Mouse Jiggler"

TOOL_KEYS="cronlike jiggler"

_row() { printf '%s\n' "$REGISTRY" | grep "^$1|"; }
_field() { _row "$1" | cut -d'|' -f"$2"; }

_known() {
  case " $TOOL_KEYS " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

_die_unknown() {
  echo "Unknown tool \"$1\". Valid names: $TOOL_KEYS all" >&2
  exit 2
}

# --- Environment ------------------------------------------------------------

ROOT="$(bash "$SELF_DIR/plugin-root.sh")" || {
  echo "Could not locate the KGProDesign-DevKit plugin root." >&2
  echo "Set CLAUDE_PLUGIN_ROOT, or reinstall the plugin." >&2
  exit 2
}

PY="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
if [ -z "$PY" ]; then
  echo "python not found on PATH. Both desktop tools require Python 3.8+." >&2
  exit 2
fi

case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*) PLATFORM=windows ;;
  Darwin)               PLATFORM=macos ;;
  *)                    PLATFORM=other ;;
esac

# Windowless interpreter, so a launched tray shows no console.
if [ "$PLATFORM" = windows ]; then
  PYW="$(command -v pythonw 2>/dev/null || echo "$PY")"
else
  PYW="$PY"
fi

DEPS_OK=1
"$PY" -c "import pystray, PIL" >/dev/null 2>&1 || DEPS_OK=0

# --- Helpers ----------------------------------------------------------------

_status_line() {
  # Print the raw status line for one tool. Never fails.
  local key="$1" dir entry
  dir="$(_field "$key" 2)"; entry="$(_field "$key" 3)"
  if [ "$DEPS_OK" -eq 0 ]; then
    echo "state=unavailable reason=missing-deps"
    return 0
  fi
  ( cd "$ROOT/$dir" && "$PY" "$entry" --status 2>/dev/null ) || echo "state=unknown reason=query-failed"
}

_is_running() {
  _status_line "$1" | grep -q '^state=running'
}

_report() {
  printf '%-15s %s\n' "$(_field "$1" 4):" "$(_status_line "$1")"
}

_resolve_targets() {
  # Echo the tool keys a command applies to. Validate BEFORE calling this:
  # an exit from inside a command substitution only kills the subshell, so
  # this function cannot reject anything on the caller's behalf.
  local arg="${1:-all}"
  if [ "$arg" = all ]; then
    printf '%s\n' $TOOL_KEYS
  else
    printf '%s\n' "$arg"
  fi
}

# --- Verbs ------------------------------------------------------------------

cmd_status() {
  local arg="${1:-all}" rc=0
  [ "$arg" = all ] || _known "$arg" || _die_unknown "$arg"
  for key in $(_resolve_targets "$arg"); do
    _report "$key"
  done
  [ "$DEPS_OK" -eq 0 ] && rc=2
  return $rc
}

cmd_start() {
  local key="$1" dir entry label
  _known "$key" || _die_unknown "$key"
  [ "$DEPS_OK" -eq 0 ] && { echo "Cannot start: pystray or Pillow is not importable." >&2; exit 2; }
  dir="$(_field "$key" 2)"; entry="$(_field "$key" 3)"; label="$(_field "$key" 4)"

  if _is_running "$key"; then
    # Starting something already started is success, not an error.
    echo "$label is already running. $(_status_line "$key")"
    return 0
  fi

  # The cd is required, not cosmetic: both tools use flat imports and every
  # launcher shipped with them cds to the script directory first.
  ( cd "$ROOT/$dir" && nohup "$PYW" "$entry" >/dev/null 2>&1 & ) >/dev/null 2>&1

  # Report the state we verified, never the state we intended.
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.5
    if _is_running "$key"; then
      echo "Started $label. $(_status_line "$key")"
      return 0
    fi
  done
  echo "$label did not come up within 5s. $(_status_line "$key")" >&2
  return 1
}

cmd_stop() {
  local key="$1" dir entry
  _known "$key" || _die_unknown "$key"
  dir="$(_field "$key" 2)"; entry="$(_field "$key" 3)"
  ( cd "$ROOT/$dir" && "$PY" "$entry" --stop )
}

cmd_restart() {
  local key="$1"
  _known "$key" || _die_unknown "$key"
  cmd_stop "$key" || true   # nothing running is a fine starting point
  cmd_start "$key"
}

cmd_logs() {
  local arg="${1:-}" logdir slug today file
  logdir="$HOME/.cronlike/logs"

  if [ "$arg" = jiggler ]; then
    echo "Mouse Jiggler keeps no logs. It has no scheduled work to record."
    return 0
  fi

  if [ ! -d "$logdir" ]; then
    echo "No log directory yet at $logdir. CronLike creates it on its first run."
    return 0
  fi

  if [ -z "$arg" ] || [ "$arg" = cronlike ]; then
    if ! ls "$logdir"/*.log >/dev/null 2>&1; then
      echo "No logs yet in $logdir."
      return 0
    fi
    echo "Recent logs in $logdir (newest first):"
    ls -t "$logdir"/*.log | head -10 | while read -r f; do
      printf '  %s  %s\n' "$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null || echo '                ')" "$(basename "$f")"
    done
    return 0
  fi

  # Named job: derive the slug from runner._slugify itself rather than
  # reimplementing it here, so the two can never disagree.
  slug="$(cd "$ROOT/tools/CronLike" && "$PY" -c "import runner,sys; print(runner._slugify(sys.argv[1]))" "$arg" 2>/dev/null)"
  if [ -z "$slug" ]; then
    echo "Could not derive a log name for \"$arg\"." >&2
    return 1
  fi
  today="$(date '+%Y-%m-%d')"
  file="$logdir/$slug-$today.log"
  if [ ! -f "$file" ]; then
    # A job that has not fired today legitimately has no log. Not an error.
    echo "No log for \"$arg\" on $today (looked for $file)."
    return 0
  fi
  echo "== $file =="
  tail -50 "$file"
}

# --- Autostart --------------------------------------------------------------

SHIM_DIR="$HOME/.kgp-tools"
SHIM="$SHIM_DIR/launch.py"

_install_shim() {
  mkdir -p "$SHIM_DIR" || return 1
  # Always overwrite: the shim is plugin-owned, and a stale copy is worse than
  # a fresh one.
  cp "$ROOT/scripts/tools/launch.py" "$SHIM" || return 1
}

_win_startup_dir() {
  printf '%s\n' "${APPDATA:-$HOME/AppData/Roaming}/Microsoft/Windows/Start Menu/Programs/Startup"
}

_win_vbs_path() { printf '%s\n' "$(_win_startup_dir)/kgp-$1-autostart.vbs"; }
_mac_plist_path() { printf '%s\n' "$HOME/Library/LaunchAgents/com.kgprodesign.$1.plist"; }
_mac_label() { printf '%s\n' "com.kgprodesign.$1"; }

_win_home() {
  # Native Windows form of $HOME, for a path VBScript can open.
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$HOME"; else printf '%s\n' "$HOME"; fi
}

autostart_on() {
  local key="$1"
  _install_shim || { echo "Could not install the launcher shim into $SHIM_DIR" >&2; return 1; }

  if [ "$PLATFORM" = windows ]; then
    local dir vbs winhome
    dir="$(_win_startup_dir)"; vbs="$(_win_vbs_path "$key")"
    mkdir -p "$dir" || { echo "Could not create $dir" >&2; return 1; }
    winhome="$(_win_home)"
    # No version number reaches this file. The shim resolves the plugin root
    # at launch time, which is what lets autostart survive a plugin update.
    cat > "$vbs" <<VBSEOF
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "pythonw """ & "${winhome}\\.kgp-tools\\launch.py" & """ ${key}", 0, False
VBSEOF
    [ -f "$vbs" ] || { echo "Failed to write $vbs" >&2; return 1; }
    echo "Autostart enabled for $(_field "$key" 4)."
    echo "  shim:    $SHIM"
    echo "  startup: $vbs"
    return 0
  fi

  if [ "$PLATFORM" = macos ]; then
    local plist label
    plist="$(_mac_plist_path "$key")"; label="$(_mac_label "$key")"
    mkdir -p "$(dirname "$plist")" || return 1
    # KeepAlive is deliberately absent: the user exiting the tray must not be
    # fought by launchd.
    cat > "$plist" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/env</string>
    <string>python3</string>
    <string>${SHIM}</string>
    <string>${key}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLISTEOF
    launchctl unload "$plist" >/dev/null 2>&1 || true
    launchctl load "$plist" >/dev/null 2>&1
    # A plist on disk that failed to load is autostart that never fires, so
    # confirm rather than assume.
    if launchctl list 2>/dev/null | grep -q "$label"; then
      echo "Autostart enabled for $(_field "$key" 4)."
      echo "  shim:  $SHIM"
      echo "  agent: $plist (loaded)"
      return 0
    fi
    echo "Wrote $plist but launchctl did not load it. Autostart is NOT active." >&2
    return 1
  fi

  echo "Autostart is implemented for Windows and macOS only (detected: $PLATFORM)." >&2
  return 1
}

autostart_off() {
  local key="$1"
  if [ "$PLATFORM" = windows ]; then
    local vbs; vbs="$(_win_vbs_path "$key")"
    if [ -f "$vbs" ]; then rm -f "$vbs" && echo "Autostart disabled. Removed $vbs"
    else echo "Autostart was not enabled for $(_field "$key" 4)."; fi
    # ~/.kgp-tools/ stays: the other tool may still use the shim.
    return 0
  fi
  if [ "$PLATFORM" = macos ]; then
    local plist; plist="$(_mac_plist_path "$key")"
    if [ -f "$plist" ]; then
      launchctl unload "$plist" >/dev/null 2>&1 || true
      rm -f "$plist" && echo "Autostart disabled. Unloaded and removed $plist"
    else
      echo "Autostart was not enabled for $(_field "$key" 4)."
    fi
    return 0
  fi
  echo "Autostart is implemented for Windows and macOS only (detected: $PLATFORM)." >&2
  return 1
}

autostart_status() {
  local key="$1"
  if [ "$PLATFORM" = windows ]; then
    local vbs; vbs="$(_win_vbs_path "$key")"
    if [ -f "$vbs" ]; then echo "$(_field "$key" 4): autostart ENABLED -> $vbs (target: $SHIM $key)"
    else echo "$(_field "$key" 4): autostart disabled"; fi
    return 0
  fi
  if [ "$PLATFORM" = macos ]; then
    local plist label; plist="$(_mac_plist_path "$key")"; label="$(_mac_label "$key")"
    if [ -f "$plist" ]; then
      if launchctl list 2>/dev/null | grep -q "$label"; then
        echo "$(_field "$key" 4): autostart ENABLED and loaded -> $plist"
      else
        echo "$(_field "$key" 4): plist present but NOT loaded -> $plist"
      fi
    else
      echo "$(_field "$key" 4): autostart disabled"
    fi
    return 0
  fi
  echo "Autostart is implemented for Windows and macOS only (detected: $PLATFORM)." >&2
  return 1
}

cmd_autostart() {
  local action="${1:-status}" key="${2:-}"
  [ -n "$key" ] || { echo "autostart needs a tool name: $TOOL_KEYS" >&2; exit 2; }
  _known "$key" || _die_unknown "$key"
  case "$action" in
    on)     autostart_on "$key" ;;
    off)    autostart_off "$key" ;;
    status) autostart_status "$key" ;;
    *) echo "autostart takes on, off, or status (got \"$action\")." >&2; exit 2 ;;
  esac
}

# --- Dispatch ---------------------------------------------------------------

usage() {
  cat >&2 <<'USAGE'
Usage: toolctl.sh <verb> [tool] [args]

  status    [cronlike|jiggler|all]
  start     <cronlike|jiggler>
  stop      <cronlike|jiggler>
  restart   <cronlike|jiggler>
  logs      [job name|cronlike|jiggler]
  autostart <on|off|status> <cronlike|jiggler>
USAGE
  exit 2
}

VERB="${1:-status}"
shift || true

case "$VERB" in
  status)    cmd_status "${1:-all}" ;;
  start)     [ $# -ge 1 ] || usage; cmd_start "$1" ;;
  stop)      [ $# -ge 1 ] || usage; cmd_stop "$1" ;;
  restart)   [ $# -ge 1 ] || usage; cmd_restart "$1" ;;
  logs)      cmd_logs "${1:-}" ;;
  autostart) cmd_autostart "${1:-status}" "${2:-}" ;;
  -h|--help|help) usage ;;
  *) echo "Unknown verb \"$VERB\"." >&2; usage ;;
esac

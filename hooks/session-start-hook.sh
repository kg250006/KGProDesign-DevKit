#!/bin/bash

# Ralph Loop SessionStart Hook
# Auto-injects --resume command when continuation is detected
# This hook fires when a new Claude Code session starts

set -euo pipefail

# Get plugin name dynamically
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"

PLUGIN_NAME="KGP"
if [[ -f "$PLUGIN_JSON" ]]; then
  EXTRACTED_NAME=$(jq -r '.name // empty' "$PLUGIN_JSON" 2>/dev/null || true)
  if [[ -n "$EXTRACTED_NAME" ]]; then
    PLUGIN_NAME="$EXTRACTED_NAME"
  fi
fi

STATE_FILE=".claude/${PLUGIN_NAME}:ralph-loop.local.md"

# Check if Ralph loop state exists and needs continuation
if [[ ! -f "$STATE_FILE" ]]; then
  # No active loop - nothing to do
  exit 0
fi

# Read state file
STATE_CONTENT=$(cat "$STATE_FILE")

# Extract values from frontmatter
CONTINUE_NEXT=$(echo "$STATE_CONTENT" | grep '^continue_next:' | sed 's/continue_next: *//' || echo "false")
ACTIVE=$(echo "$STATE_CONTENT" | grep '^active:' | sed 's/active: *//' || echo "false")
ITERATION=$(echo "$STATE_CONTENT" | grep '^iteration:' | sed 's/iteration: *//' || echo "1")

# Check if continuation is needed
if [[ "$CONTINUE_NEXT" == "true" ]] && [[ "$ACTIVE" == "true" ]]; then
  # Reset continue_next marker to prevent infinite detection
  TEMP_FILE="${STATE_FILE}.tmp.$$"
  sed 's/^continue_next: true/continue_next: false/' "$STATE_FILE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$STATE_FILE"

  # Output hook response to inject context
  jq -n \
    --arg iteration "$ITERATION" \
    --arg pluginName "$PLUGIN_NAME" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": ("RALPH LOOP CONTINUATION DETECTED (iteration " + $iteration + "). Execute: /" + $pluginName + ":ralph-loop --resume")
      }
    }'
fi

exit 0

#!/bin/bash

# Ralph Auto - Automatic respawn wrapper for Ralph Loop with fresh-context mode
# This script wraps the claude CLI and automatically restarts sessions
# when the Ralph loop's continue_next flag is set to true.

set -euo pipefail

echo "Ralph Auto: Starting session..."
echo ""

# Run the initial claude session with any provided arguments
claude "$@"

# Check for continuation flag in state file
STATE_FILE=".claude/ralph-loop.local.md"

while [[ -f "$STATE_FILE" ]]; do
  # Extract values from state file
  CONTINUE_NEXT=$(grep '^continue_next:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' || echo "false")
  ACTIVE=$(grep '^active:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' || echo "false")
  ITERATION=$(grep '^iteration:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' || echo "?")

  if [[ "$CONTINUE_NEXT" == "true" ]] && [[ "$ACTIVE" == "true" ]]; then
    echo ""
    echo "==============================================================="
    echo "Ralph Auto: Fresh context restart detected (iteration $ITERATION)"
    echo "==============================================================="
    echo ""
    echo "Waiting 2 seconds before restarting..."
    sleep 2

    # Reset continue_next flag before starting new session
    TEMP_FILE="${STATE_FILE}.tmp.$$"
    sed 's/^continue_next: true/continue_next: false/' "$STATE_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$STATE_FILE"

    echo "Starting fresh Claude session..."
    echo ""

    # Start new Claude session - SessionStart hook will auto-inject --resume
    claude
  else
    break
  fi
done

echo ""
echo "Ralph Auto: Loop complete."
echo ""

# Show final status if progress file exists
PROGRESS_FILE=".claude/ralph-progress.md"
if [[ -f "$PROGRESS_FILE" ]]; then
  SUCCESS_COUNT=$(grep -c 'Status: SUCCESS' "$PROGRESS_FILE" 2>/dev/null || echo 0)
  FAILED_COUNT=$(grep -c 'Status: FAILED' "$PROGRESS_FILE" 2>/dev/null || echo 0)
  BLOCKED_COUNT=$(grep -c 'Status: BLOCKED' "$PROGRESS_FILE" 2>/dev/null || echo 0)

  echo "Final Progress Summary:"
  echo "  Completed: $SUCCESS_COUNT"
  echo "  Failed: $FAILED_COUNT"
  echo "  Blocked: $BLOCKED_COUNT"
  echo ""
  echo "Full progress: $PROGRESS_FILE"
fi

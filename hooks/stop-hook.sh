#!/bin/bash

# Ralph Loop Stop Hook
# Prevents session exit when a ralph-loop is active
# Feeds Claude's output back as input to continue the loop

set -euo pipefail

# Read hook input from stdin (advanced stop hook API)
HOOK_INPUT=$(cat)

# Check if ralph-loop is active
RALPH_STATE_FILE=".claude/\$PLUGIN_NAME:ralph-loop.local.md"

if [[ ! -f "$RALPH_STATE_FILE" ]]; then
  # No active loop - allow exit
  exit 0
fi

# Parse markdown frontmatter (YAML between ---) and extract values
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$RALPH_STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
# Extract completion_promise and strip surrounding quotes if present
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

# Validate numeric fields before arithmetic operations
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "Warning: Ralph loop: State file corrupted" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: 'iteration' field is not a valid number (got: '$ITERATION')" >&2
  echo "" >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   Ralph loop is stopping. Run /\$PLUGIN_NAME:ralph-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "Warning: Ralph loop: State file corrupted" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: 'max_iterations' field is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "" >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   Ralph loop is stopping. Run /\$PLUGIN_NAME:ralph-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Ralph loop: Max iterations ($MAX_ITERATIONS) reached."
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "Warning: Ralph loop: Transcript file not found" >&2
  echo "   Expected: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a Claude Code internal issue." >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Read last assistant message from transcript (JSONL format - one JSON per line)
# First check if there are any assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "Warning: Ralph loop: No assistant messages found in transcript" >&2
  echo "   Transcript: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a transcript format issue" >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Extract last assistant message with explicit error handling
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "Warning: Ralph loop: Failed to extract last assistant message" >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Parse JSON with error handling
LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>&1)

# Check if jq succeeded
if [[ $? -ne 0 ]]; then
  echo "Warning: Ralph loop: Failed to parse assistant message JSON" >&2
  echo "   Error: $LAST_OUTPUT" >&2
  echo "   This may indicate a transcript format issue" >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "Warning: Ralph loop: Assistant message contained no text content" >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Extract additional fields from frontmatter for progress tracking
MAX_RETRIES=$(echo "$FRONTMATTER" | grep '^max_retries:' | sed 's/max_retries: *//' || echo "0")
ISOLATION_MODE=$(echo "$FRONTMATTER" | grep '^isolation_mode:' | sed 's/isolation_mode: *//' || echo "false")

# Detect task status from output
TASK_STATUS="IN_PROGRESS"
TASK_NOTES=""

if echo "$LAST_OUTPUT" | grep -qi "completed\|success\|done\|finished"; then
  TASK_STATUS="SUCCESS"
fi

if echo "$LAST_OUTPUT" | grep -qi "error\|failed\|exception\|cannot"; then
  TASK_STATUS="FAILED"
  # Extract error context (first line mentioning error)
  TASK_NOTES=$(echo "$LAST_OUTPUT" | grep -i "error\|failed\|exception" | head -1 | cut -c1-100)
fi

# Retry tracking - if task failed and max_retries is set
if [[ ! "$MAX_RETRIES" =~ ^[0-9]+$ ]]; then
  MAX_RETRIES=0
fi

CONSECUTIVE_FAILURES=$(echo "$FRONTMATTER" | grep '^consecutive_failures:' | sed 's/consecutive_failures: *//' || echo "0")
if [[ ! "$CONSECUTIVE_FAILURES" =~ ^[0-9]+$ ]]; then
  CONSECUTIVE_FAILURES=0
fi

# Track consecutive failures for retry logic
if [[ "$TASK_STATUS" == "FAILED" ]]; then
  CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))

  # Check if max retries exceeded
  if [[ $MAX_RETRIES -gt 0 ]] && [[ $CONSECUTIVE_FAILURES -ge $MAX_RETRIES ]]; then
    echo "Ralph loop: Max retries ($MAX_RETRIES) reached after consecutive failures"
    TASK_STATUS="BLOCKED"
    # Reset consecutive failures after blocking
    CONSECUTIVE_FAILURES=0
  fi
else
  # Reset consecutive failures on success
  CONSECUTIVE_FAILURES=0
fi

# Update consecutive_failures in state file
TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
if grep -q '^consecutive_failures:' "$RALPH_STATE_FILE"; then
  sed "s/^consecutive_failures: .*/consecutive_failures: $CONSECUTIVE_FAILURES/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
else
  # Add consecutive_failures field after max_retries if not present
  sed "/^max_retries:/a\\
consecutive_failures: $CONSECUTIVE_FAILURES" "$RALPH_STATE_FILE" > "$TEMP_FILE"
fi
mv "$TEMP_FILE" "$RALPH_STATE_FILE"

# Update progress file with iteration results
PROGRESS_FILE=".claude/ralph-progress.md"
PROGRESS_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [[ -f "$PROGRESS_FILE" ]]; then
  cat >> "$PROGRESS_FILE" <<EOF

### Iteration $ITERATION
- Timestamp: $PROGRESS_TIMESTAMP
- Status: $TASK_STATUS
$(if [[ -n "$TASK_NOTES" ]]; then echo "- Notes: $TASK_NOTES"; fi)
$(if [[ "$TASK_STATUS" == "FAILED" ]] && [[ $MAX_RETRIES -gt 0 ]]; then echo "- Retries: $CONSECUTIVE_FAILURES/$MAX_RETRIES"; fi)

EOF
fi

# Check for completion promise (only if set)
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  # Extract text from <promise> tags using Perl for multiline support
  # -0777 slurps entire input, s flag makes . match newlines
  # .*? is non-greedy (takes FIRST tag), whitespace normalized
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

  # Use = for literal string comparison (not pattern matching)
  # == in [[ ]] does glob pattern matching which breaks with *, ?, [ characters
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "Ralph loop: Detected <promise>$COMPLETION_PROMISE</promise>"
    rm "$RALPH_STATE_FILE"
    exit 0
  fi
fi

# Not complete - continue loop with SAME PROMPT
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt (everything after the closing ---)
# Skip first --- line, skip until second --- line, then print everything after
# Use i>=2 instead of i==2 to handle --- in prompt content
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$RALPH_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "Warning: Ralph loop: State file corrupted or incomplete" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: No prompt text found" >&2
  echo "" >&2
  echo "   This usually means:" >&2
  echo "     - State file was manually edited" >&2
  echo "     - File was corrupted during writing" >&2
  echo "" >&2
  echo "   Ralph loop is stopping. Run /\$PLUGIN_NAME:ralph-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Update iteration in frontmatter (portable across macOS and Linux)
# Create temp file, then atomically replace
TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$RALPH_STATE_FILE"

# Handle isolation mode (fresh context per iteration)
if [[ "$ISOLATION_MODE" == "true" ]]; then
  # In isolation mode, we allow the session to exit cleanly
  # Set continue_next: true so wrapper script or SessionStart hook knows to resume
  TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
  sed 's/^continue_next: false/continue_next: true/' "$RALPH_STATE_FILE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$RALPH_STATE_FILE"

  echo ""
  echo "==============================================================="
  echo "Ralph Loop - Fresh Context Mode (Iteration $ITERATION complete)"
  echo "==============================================================="
  echo ""
  echo "Session will now exit cleanly for fresh context."
  echo ""
  echo "To continue: /\$PLUGIN_NAME:ralph-loop --resume"
  echo "   or use ralph-auto.sh for automatic continuation"
  echo ""
  echo "Progress: .claude/ralph-progress.md"
  echo "Next iteration: $NEXT_ITERATION"
  echo "==============================================================="

  # Allow exit - wrapper script will detect continue_next: true and restart
  exit 0
fi

# In-session mode: Block exit and continue in same session
# Build system message with iteration count and completion promise info
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="Ralph iteration $NEXT_ITERATION | To stop: output <promise>$COMPLETION_PROMISE</promise> (ONLY when statement is TRUE - do not lie to exit!)"
else
  SYSTEM_MSG="Ralph iteration $NEXT_ITERATION | No completion promise set - loop runs infinitely"
fi

# Output JSON to block the stop and feed prompt back
# The "reason" field contains the prompt that will be sent back to Claude
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

# Exit 0 for successful hook execution
exit 0

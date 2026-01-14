#!/bin/bash
# PRP Orchestrator - External task executor with hard session boundaries
# Usage: ./prp-orchestrator.sh <prp-file.md> [--max-retries N] [--timeout M]
#
# PATTERN: Follow scripts/setup-ralph-loop.sh conventions
# Each PRP task runs in a completely fresh Claude session.
# Claude sees ONLY the current task - never the full PRP.

set -euo pipefail

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# macOS compatibility: use gtimeout if available, otherwise use bash fallback
if command -v timeout &> /dev/null; then
  TIMEOUT_CMD="timeout"
elif command -v gtimeout &> /dev/null; then
  TIMEOUT_CMD="gtimeout"
else
  TIMEOUT_CMD="bash_timeout"
fi

# Pure bash timeout function for macOS without coreutils
bash_timeout() {
  local timeout_seconds="$1"
  shift

  # Run command in background
  "$@" &
  local pid=$!

  # Start a watchdog in background
  (
    sleep "$timeout_seconds"
    kill -TERM "$pid" 2>/dev/null
  ) &
  local watchdog=$!

  # Wait for command to finish
  wait "$pid" 2>/dev/null
  local exit_code=$?

  # Kill watchdog if command finished before timeout
  kill "$watchdog" 2>/dev/null
  wait "$watchdog" 2>/dev/null

  return $exit_code
}

# Default values
MAX_RETRIES=3
TIMEOUT=300  # 5 minutes per task
DRY_RUN=false

# Show help function
show_help() {
  cat <<EOF
PRP Isolated Orchestrator - Execute PRPs with hard session boundaries

USAGE:
  ./prp-orchestrator.sh <prp-file.md> [OPTIONS]

ARGUMENTS:
  prp-file.md    Path to PRP file with XML task structure

OPTIONS:
  --max-retries N   Max retry attempts per task (default: 3)
  --timeout M       Timeout in seconds per task (default: 300)
  --dry-run         Test mode - echo commands instead of running Claude
  --help, -h        Show this help message

DESCRIPTION:
  Executes each PRP task in a completely separate Claude session.
  Claude sees ONLY the current task - never the full PRP.

  This enforces hard session isolation at the process level.
  Claude cannot "optimize" by combining tasks.

EXAMPLE:
  ./prp-orchestrator.sh PRPs/my-feature.md
  ./prp-orchestrator.sh PRPs/my-feature.md --max-retries 5 --timeout 600

OUTPUT:
  Progress logged to: .claude/prp-progress.md
  Current task file: .claude/current-task.md

EOF
}

# Parse arguments
PRP_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-retries)
      MAX_RETRIES="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      if [[ -z "$PRP_FILE" ]]; then
        PRP_FILE="$1"
      fi
      shift
      ;;
  esac
done

# CRITICAL: Validate PRP file exists
if [[ -z "$PRP_FILE" ]] || [[ ! -f "$PRP_FILE" ]]; then
  echo "Error: PRP file not found: $PRP_FILE"
  echo ""
  echo "Usage: ./prp-orchestrator.sh <prp-file.md> [OPTIONS]"
  echo "Run with --help for more information."
  exit 1
fi

# Create .claude directory if needed
mkdir -p .claude

# Files
TASK_FILE=".claude/current-task.md"
PROGRESS_FILE=".claude/prp-progress.md"

# Extract tasks using Node.js script
echo "Extracting tasks from PRP..."
TASKS_JSON=$("$SCRIPT_DIR/prp-to-tasks.js" "$PRP_FILE" 2>/dev/null || node "$SCRIPT_DIR/prp-to-tasks.js" "$PRP_FILE")

# Parse JSON - use jq if available, else Node.js fallback
if command -v jq &> /dev/null; then
  TOTAL=$(echo "$TASKS_JSON" | jq '.total')
  PRP_NAME=$(echo "$TASKS_JSON" | jq -r '.name')
  PRP_GOAL=$(echo "$TASKS_JSON" | jq -r '.goal')
else
  # Fallback: use node for JSON parsing
  TOTAL=$(echo "$TASKS_JSON" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).total)")
  PRP_NAME=$(echo "$TASKS_JSON" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).name)")
  PRP_GOAL=""
fi

# Initialize progress file
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$PROGRESS_FILE" <<EOF
# PRP Execution Progress (Isolated Mode)

## Session Info
- PRP: $PRP_FILE
- Name: $PRP_NAME
- Started: $TIMESTAMP
- Total Tasks: $TOTAL
- Max Retries: $MAX_RETRIES
- Timeout: ${TIMEOUT}s

## Task Log

EOF

# Banner
echo ""
echo "=========================================="
echo "  PRP ISOLATED EXECUTION"
echo "=========================================="
echo "PRP File: $PRP_FILE"
echo "PRP Name: $PRP_NAME"
echo "Total Tasks: $TOTAL"
echo "Max Retries: $MAX_RETRIES"
echo "Timeout: ${TIMEOUT}s per task"
echo "Progress: $PROGRESS_FILE"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "Mode: DRY RUN (no Claude sessions)"
fi
echo "=========================================="
echo ""

# Track stats
SUCCEEDED=0
FAILED=0

# Main loop - iterate through tasks
for i in $(seq 0 $((TOTAL - 1))); do
  TASK_NUM=$((i + 1))

  # Extract task details using jq or Node.js fallback
  if command -v jq &> /dev/null; then
    TASK_ID=$(echo "$TASKS_JSON" | jq -r ".tasks[$i].id")
    TASK_AGENT=$(echo "$TASKS_JSON" | jq -r ".tasks[$i].agent")
    TASK_DESC=$(echo "$TASKS_JSON" | jq -r ".tasks[$i].description")
    TASK_CRITERIA=$(echo "$TASKS_JSON" | jq -r ".tasks[$i].acceptance_criteria")
    TASK_FILES=$(echo "$TASKS_JSON" | jq -r ".tasks[$i].files")
    TASK_PSEUDO=$(echo "$TASKS_JSON" | jq -r ".tasks[$i].pseudocode")
  else
    # Node.js fallback
    TASK_ID=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.tasks[$i].id)")
    TASK_AGENT=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.tasks[$i].agent)")
    TASK_DESC=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.tasks[$i].description)")
    TASK_CRITERIA=""
    TASK_FILES=""
    TASK_PSEUDO=""
  fi

  echo ""
  echo "=========================================="
  echo "TASK $TASK_NUM / $TOTAL: $TASK_ID"
  echo "Agent: $TASK_AGENT"
  echo "Description: $TASK_DESC"
  echo "=========================================="

  # Write ONLY this task to file (Claude sees nothing else)
  cat > "$TASK_FILE" <<EOF
# Current Task: $TASK_ID

You are executing a single task from a PRP. Focus ONLY on this task.

## Task Description
$TASK_DESC

## Files to Modify
$TASK_FILES

## Implementation Guide
\`\`\`
$TASK_PSEUDO
\`\`\`

## Acceptance Criteria
$TASK_CRITERIA

## Instructions
1. Complete this task fully
2. Validate your work (run tests if applicable)
3. Exit when done - the orchestrator handles the next task

## CRITICAL CONSTRAINTS
- DO NOT read the full PRP file
- DO NOT ask about other tasks
- DO NOT try to optimize by combining tasks
- Focus ONLY on this single task
EOF

  # Retry loop
  RETRIES=0
  SUCCESS=false

  while [[ $RETRIES -lt $MAX_RETRIES ]] && [[ "$SUCCESS" == "false" ]]; do
    ATTEMPT=$((RETRIES + 1))
    echo "Attempt $ATTEMPT of $MAX_RETRIES..."

    # Log attempt start
    echo "### Task $TASK_ID - Attempt $ATTEMPT - $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROGRESS_FILE"

    # Spawn fresh Claude session for THIS task only
    # Using -p for print mode (non-interactive)
    if [[ "$DRY_RUN" == "true" ]]; then
      # Dry run mode - simulate success
      echo "[DRY RUN] Would execute: claude -p \"Read .claude/current-task.md and execute task $TASK_ID\""
      echo "[DRY RUN] Task file contents:"
      head -10 "$TASK_FILE" | sed 's/^/  /'
      echo "  ..."
      sleep 0.5  # Brief pause to simulate work
      SUCCESS=true
      SUCCEEDED=$((SUCCEEDED + 1))
      echo "Status: SUCCESS (dry-run)" >> "$PROGRESS_FILE"
      echo "Task $TASK_ID: SUCCESS (dry-run)"
    elif $TIMEOUT_CMD "$TIMEOUT" claude -p "Read .claude/current-task.md and execute the task described. When complete, simply exit." 2>&1; then
      SUCCESS=true
      SUCCEEDED=$((SUCCEEDED + 1))
      echo "Status: SUCCESS" >> "$PROGRESS_FILE"
      echo "Task $TASK_ID: SUCCESS"
    else
      EXIT_CODE=$?
      RETRIES=$((RETRIES + 1))
      echo "Status: FAILED (exit code $EXIT_CODE)" >> "$PROGRESS_FILE"
      echo "Task $TASK_ID: FAILED (attempt $ATTEMPT)"

      if [[ $RETRIES -lt $MAX_RETRIES ]]; then
        echo "Retrying in 2 seconds..."
        sleep 2
      fi
    fi
  done

  # Handle final failure
  if [[ "$SUCCESS" == "false" ]]; then
    FAILED=$((FAILED + 1))
    echo "Status: FAILED PERMANENTLY after $MAX_RETRIES attempts" >> "$PROGRESS_FILE"
    echo "Task $TASK_ID: FAILED permanently - continuing to next task"
  fi

  echo "" >> "$PROGRESS_FILE"

  # Brief pause between tasks
  sleep 1
done

# Final summary
echo ""
echo "=========================================="
echo "  EXECUTION COMPLETE"
echo "=========================================="
echo "Total: $TOTAL"
echo "Succeeded: $SUCCEEDED"
echo "Failed: $FAILED"
echo "=========================================="

# Append summary to progress file
cat >> "$PROGRESS_FILE" <<EOF

## Summary
- Completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Succeeded: $SUCCEEDED / $TOTAL
- Failed: $FAILED
EOF

# Exit with appropriate code
if [[ $FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi

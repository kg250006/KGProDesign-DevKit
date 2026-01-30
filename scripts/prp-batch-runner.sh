#!/bin/bash
# PRP Batch Runner - Execute multiple PRPs sequentially via /KGP:prp-execute-isolated
# Usage: ./prp-batch-runner.sh <prp1.md> <prp2.md> ... [OPTIONS]
#    OR: ./prp-batch-runner.sh --batch-file PRPs/batch.txt [OPTIONS]
#
# Each PRP runs via the /KGP:prp-execute-isolated command in its own tmux session.
# This ensures complete isolation between PRPs and consistent execution path.

set -euo pipefail

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
MAX_RETRIES=3
TIMEOUT=300
ITERATIONS=2
DRY_RUN=false
NO_SAFETY=false
SKIP_VALIDATION=false
BATCH_FILE=""
PRP_FILES=()

# Show help
show_help() {
  cat <<EOF
PRP Batch Runner - Execute multiple PRPs sequentially with tmux isolation

USAGE:
  ./prp-batch-runner.sh <prp1.md> <prp2.md> ... [OPTIONS]
  ./prp-batch-runner.sh --batch-file PRPs/batch.txt [OPTIONS]

ARGUMENTS:
  prp1.md prp2.md ...   One or more PRP files to execute sequentially

OPTIONS:
  --batch-file FILE     Read PRP paths from a file (one per line)
  --max-retries N       Max retry attempts per task within each PRP (default: 3)
  --timeout M           Timeout in seconds per task (default: 300)
  --iterations N        Min successful iterations per task (default: 2)
  --dry-run             Test mode - simulate execution without running Claude
  --no-safety           Disable safety mode (use standard permissions)
  --skip-validation     Skip acceptance criteria validation
  --help, -h            Show this help message

DESCRIPTION:
  Executes multiple PRPs sequentially, each via /KGP:prp-execute-isolated.

  The workflow is:
  1. Parse list of PRPs from arguments or batch file
  2. For each PRP:
     a. Spawn tmux session running: claude -p "/KGP:prp-execute-isolated <prp>"
     b. Wait until tmux session completes
     c. Capture exit status and log results
     d. Brief pause, then proceed to next PRP
  3. Aggregate results and generate summary

  This ensures complete isolation between PRPs AND consistent execution path
  through the /KGP:prp-execute-isolated command.

BATCH FILE FORMAT:
  # Comments start with #
  PRPs/feature-auth.md
  PRPs/feature-payments.md
  PRPs/refactor-db.md

EXAMPLE:
  # Execute three PRPs in sequence
  ./prp-batch-runner.sh PRPs/step1.md PRPs/step2.md PRPs/step3.md

  # Use a batch file
  ./prp-batch-runner.sh --batch-file PRPs/release-1.0.txt

  # With options
  ./prp-batch-runner.sh PRPs/*.md --timeout 600 --max-retries 5

OUTPUT:
  Batch progress: .claude/prp-batch-progress.md
  Individual PRP logs: .claude/prp-progress.md (overwritten per PRP)

ARCHITECTURE:
  prp-batch-runner.sh
    └─► For each PRP:
         └─► tmux session: prp-orchestrator.sh <prp>
              └─► Fresh Claude session per task

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --batch-file)
      BATCH_FILE="$2"
      shift 2
      ;;
    --max-retries)
      MAX_RETRIES="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --iterations)
      ITERATIONS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --no-safety)
      NO_SAFETY=true
      shift
      ;;
    --skip-validation)
      SKIP_VALIDATION=true
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Run with --help for usage information." >&2
      exit 1
      ;;
    *)
      # Treat as PRP file
      PRP_FILES+=("$1")
      shift
      ;;
  esac
done

# Load PRPs from batch file if specified
if [[ -n "$BATCH_FILE" ]]; then
  if [[ ! -f "$BATCH_FILE" ]]; then
    echo -e "${RED}Error: Batch file not found: $BATCH_FILE${NC}" >&2
    exit 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
      PRP_FILES+=("$line")
    fi
  done < "$BATCH_FILE"
fi

# Validate we have PRPs to run
if [[ ${#PRP_FILES[@]} -eq 0 ]]; then
  echo -e "${RED}Error: No PRP files specified${NC}" >&2
  echo "Usage: ./prp-batch-runner.sh <prp1.md> <prp2.md> ... [OPTIONS]" >&2
  echo "Run with --help for more information." >&2
  exit 1
fi

# Validate all PRP files exist
for prp in "${PRP_FILES[@]}"; do
  if [[ ! -f "$prp" ]]; then
    echo -e "${RED}Error: PRP file not found: $prp${NC}" >&2
    exit 1
  fi
done

# Check prerequisites
check_prerequisites() {
  local missing=()

  if ! command -v tmux &> /dev/null; then
    missing+=("tmux (required for session isolation)")
  fi

  if ! command -v node &> /dev/null; then
    missing+=("node (required for PRP parsing)")
  fi

  if ! command -v claude &> /dev/null; then
    missing+=("claude (Claude CLI)")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Error: Missing prerequisites:${NC}" >&2
    for item in "${missing[@]}"; do
      echo "  - $item" >&2
    done
    exit 1
  fi
}

# Map exit codes to human-readable status messages (for PRP-level reporting)
get_status_message() {
  local exit_code="$1"

  case "$exit_code" in
    0)   echo "SUCCESS" ;;
    124) echo "TIMED OUT" ;;
    1)   echo "FAILED (task failures)" ;;
    *)   echo "FAILED (exit code $exit_code)" ;;
  esac
}

check_prerequisites

# Create .claude directory
mkdir -p .claude

# Progress file for batch execution
BATCH_PROGRESS=".claude/prp-batch-progress.md"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Initialize batch progress file
cat > "$BATCH_PROGRESS" <<EOF
# PRP Batch Execution Progress

## Batch Info
- Started: $TIMESTAMP
- Total PRPs: ${#PRP_FILES[@]}
- Max Retries: $MAX_RETRIES
- Timeout: ${TIMEOUT}s per task
- Iterations: $ITERATIONS per task

## PRPs to Execute
EOF

for prp in "${PRP_FILES[@]}"; do
  echo "- [ ] $prp" >> "$BATCH_PROGRESS"
done

echo "" >> "$BATCH_PROGRESS"
echo "## Execution Log" >> "$BATCH_PROGRESS"
echo "" >> "$BATCH_PROGRESS"

# Banner
echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  PRP BATCH RUNNER${NC}"
echo -e "${BLUE}==========================================${NC}"
echo "Total PRPs: ${#PRP_FILES[@]}"
echo "Max Retries: $MAX_RETRIES"
echo "Timeout: ${TIMEOUT}s per task"
echo "Iterations: $ITERATIONS (per task)"
if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}Mode: DRY RUN${NC}"
fi
echo -e "${BLUE}==========================================${NC}"
echo ""

# Stats
BATCH_SUCCEEDED=0
BATCH_FAILED=0

# Build options string for prp-execute-isolated command
ISOLATED_OPTS="--iterations $ITERATIONS --max-retries $MAX_RETRIES --timeout $TIMEOUT"
if [[ "$DRY_RUN" == "true" ]]; then
  ISOLATED_OPTS="$ISOLATED_OPTS --dry-run"
fi
if [[ "$NO_SAFETY" == "true" ]]; then
  ISOLATED_OPTS="$ISOLATED_OPTS --no-safety"
fi
if [[ "$SKIP_VALIDATION" == "true" ]]; then
  ISOLATED_OPTS="$ISOLATED_OPTS --skip-validation"
fi

# Main batch loop
for i in "${!PRP_FILES[@]}"; do
  PRP_FILE="${PRP_FILES[$i]}"
  PRP_NUM=$((i + 1))

  echo ""
  echo -e "${BLUE}==========================================${NC}"
  echo -e "${BLUE}  PRP $PRP_NUM / ${#PRP_FILES[@]}${NC}"
  echo -e "${BLUE}  $PRP_FILE${NC}"
  echo -e "${BLUE}==========================================${NC}"

  # Log to batch progress
  START_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "### PRP $PRP_NUM: $PRP_FILE" >> "$BATCH_PROGRESS"
  echo "- Started: $START_TIME" >> "$BATCH_PROGRESS"

  # Generate unique session name
  SESSION_NAME="prp-batch-$$-$PRP_NUM"

  # Exit status file for capturing result
  EXIT_STATUS_FILE="/tmp/prp-batch-exit-$$.txt"

  # Build the command to run in tmux
  # Using tmux wait-for pattern: command signals completion, main script blocks until signal
  WAIT_SIGNAL="prp-done-$$-$PRP_NUM"

  # Call prp-orchestrator.sh directly (not via claude -p slash command)
  # This ensures accurate exit code capture and avoids "streaming mode" errors
  ORCHESTRATOR_CMD="bash '$SCRIPT_DIR/prp-orchestrator.sh' '$PRP_FILE' $ISOLATED_OPTS"

  # Command runs orchestrator, saves exit code, then signals completion
  TMUX_CMD="$ORCHESTRATOR_CMD; echo \$? > $EXIT_STATUS_FILE; tmux wait-for -S $WAIT_SIGNAL"

  echo "Starting tmux session: $SESSION_NAME"
  echo "Command: prp-orchestrator.sh $PRP_FILE"

  # Cleanup function for this session
  cleanup_session() {
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    rm -f "$EXIT_STATUS_FILE"
    # Unblock any waiting wait-for
    tmux wait-for -S "$WAIT_SIGNAL" 2>/dev/null || true
  }
  trap cleanup_session INT TERM

  # Create detached tmux session
  if ! tmux new-session -d -s "$SESSION_NAME" -x 200 -y 50 "bash -c '$TMUX_CMD'" 2>/dev/null; then
    echo -e "${RED}Error: Failed to create tmux session for $PRP_FILE${NC}" >&2
    echo "- Status: FAILED (tmux error)" >> "$BATCH_PROGRESS"
    BATCH_FAILED=$((BATCH_FAILED + 1))
    continue
  fi

  # Enable remain-on-exit so we can capture output after completion
  tmux set-option -t "$SESSION_NAME" remain-on-exit on 2>/dev/null

  echo "Waiting for PRP execution to complete..."
  echo "(You can attach to monitor: tmux attach -t $SESSION_NAME)"

  # Block until the tmux session signals completion via wait-for
  # This is the proper tmux pattern - no polling needed
  if ! tmux wait-for "$WAIT_SIGNAL" 2>/dev/null; then
    echo -e "${YELLOW}Warning: wait-for failed, session may have crashed${NC}"
  fi

  echo "PRP execution completed"

  # Kill the session
  tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

  # Check exit status from file
  END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  if [[ -f "$EXIT_STATUS_FILE" ]]; then
    EXIT_CODE=$(cat "$EXIT_STATUS_FILE")
    rm -f "$EXIT_STATUS_FILE"
  else
    EXIT_CODE=1  # Assume failure if no status file
  fi

  # Parse the orchestrator's progress file for accurate task counts
  # This provides ground truth regardless of exit code
  PRP_PROGRESS_FILE=".claude/prp-progress.md"
  TASKS_SUCCEEDED=0
  TASKS_FAILED=0
  TOTAL_TASKS=0

  if [[ -f "$PRP_PROGRESS_FILE" ]]; then
    # Extract task counts from summary section
    TASKS_SUCCEEDED=$(grep -oP 'Tasks Succeeded: \K\d+' "$PRP_PROGRESS_FILE" 2>/dev/null | tail -1 || echo "0")
    TOTAL_TASKS=$(grep -oP 'Tasks Succeeded: \d+ / \K\d+' "$PRP_PROGRESS_FILE" 2>/dev/null | tail -1 || echo "0")
    TASKS_FAILED=$(grep -oP 'Tasks Failed: \K\d+' "$PRP_PROGRESS_FILE" 2>/dev/null | tail -1 || echo "0")

    # Fallback: check for "FULLY COMPLETE" lines if summary not found
    if [[ "$TOTAL_TASKS" == "0" ]] || [[ -z "$TOTAL_TASKS" ]]; then
      TASKS_SUCCEEDED=$(grep -c "FULLY COMPLETE" "$PRP_PROGRESS_FILE" 2>/dev/null || echo "0")
      TASKS_FAILED=$(grep -c "FAILED after" "$PRP_PROGRESS_FILE" 2>/dev/null || echo "0")
      TOTAL_TASKS=$((TASKS_SUCCEEDED + TASKS_FAILED))
    fi
  fi

  # Determine actual success based on orchestrator results (not just exit code)
  # A PRP succeeds if: exit code is 0 OR (tasks succeeded > 0 AND tasks failed == 0)
  if [[ "$EXIT_CODE" == "0" ]] || { [[ "$TASKS_SUCCEEDED" -gt 0 ]] && [[ "$TASKS_FAILED" == "0" ]]; }; then
    PRP_STATUS="SUCCESS"
    echo -e "${GREEN}PRP $PRP_NUM: SUCCESS${NC}"
    if [[ "$TOTAL_TASKS" -gt 0 ]]; then
      echo "  Tasks: $TASKS_SUCCEEDED/$TOTAL_TASKS succeeded"
    fi
    echo "- Completed: $END_TIME" >> "$BATCH_PROGRESS"
    echo "- Status: SUCCESS" >> "$BATCH_PROGRESS"
    if [[ "$TOTAL_TASKS" -gt 0 ]]; then
      echo "- Tasks: $TASKS_SUCCEEDED/$TOTAL_TASKS succeeded" >> "$BATCH_PROGRESS"
    fi
    BATCH_SUCCEEDED=$((BATCH_SUCCEEDED + 1))
    # Update checkbox to mark as complete
    sed -i.bak "s|^- \[ \] $PRP_FILE\$|- [x] $PRP_FILE|" "$BATCH_PROGRESS" && rm -f "${BATCH_PROGRESS}.bak"
  else
    PRP_STATUS="FAILED"
    echo -e "${RED}PRP $PRP_NUM: $(get_status_message $EXIT_CODE)${NC}"
    if [[ "$TOTAL_TASKS" -gt 0 ]]; then
      echo "  Tasks: $TASKS_SUCCEEDED/$TOTAL_TASKS succeeded, $TASKS_FAILED failed"
    fi
    echo "- Completed: $END_TIME" >> "$BATCH_PROGRESS"
    echo "- Status: $(get_status_message $EXIT_CODE)" >> "$BATCH_PROGRESS"
    if [[ "$TOTAL_TASKS" -gt 0 ]]; then
      echo "- Tasks: $TASKS_SUCCEEDED/$TOTAL_TASKS succeeded, $TASKS_FAILED failed" >> "$BATCH_PROGRESS"
    fi
    BATCH_FAILED=$((BATCH_FAILED + 1))
    # Update checkbox to mark as failed
    sed -i.bak "s|^- \[ \] $PRP_FILE\$|- [~] $PRP_FILE (FAILED)|" "$BATCH_PROGRESS" && rm -f "${BATCH_PROGRESS}.bak"
  fi

  echo "" >> "$BATCH_PROGRESS"

  # Reset trap
  trap - INT TERM

  # Brief pause between PRPs
  if [[ $PRP_NUM -lt ${#PRP_FILES[@]} ]]; then
    echo "Pausing before next PRP..."
    sleep 2
  fi
done

# Final summary
FINAL_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  BATCH EXECUTION COMPLETE${NC}"
echo -e "${BLUE}==========================================${NC}"
echo "Total PRPs: ${#PRP_FILES[@]}"
echo -e "Succeeded: ${GREEN}$BATCH_SUCCEEDED${NC}"
echo -e "Failed: ${RED}$BATCH_FAILED${NC}"
echo -e "${BLUE}==========================================${NC}"

# Append summary to batch progress
cat >> "$BATCH_PROGRESS" <<EOF

## Batch Summary
- Completed: $FINAL_TIME
- Total PRPs: ${#PRP_FILES[@]}
- Succeeded: $BATCH_SUCCEEDED
- Failed: $BATCH_FAILED
EOF

echo ""
echo "Batch progress saved to: $BATCH_PROGRESS"

# Exit with appropriate code
if [[ $BATCH_FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi

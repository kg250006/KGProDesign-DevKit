#!/bin/bash
# PRP Orchestrator - External task executor with hard session boundaries
# Usage: ./prp-orchestrator.sh <prp-file.md> [--max-retries N] [--timeout M]
#
# PATTERN: Follow scripts/setup-ralph-loop.sh conventions
# Each PRP task runs in a completely fresh Claude session.
# Claude sees ONLY the current task - never the full PRP.

set -euo pipefail

# Get script directory for relative paths (works in both bash and zsh)
# Try BASH_SOURCE first (bash), fall back to ${(%):-%x} (zsh), then $0
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x:-}" ]] 2>/dev/null; then
  SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  # Fallback: use $0 but resolve it properly
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# Validate we found the right directory by checking for expected files
if [[ ! -f "$SCRIPT_DIR/prp-to-tasks.js" ]]; then
  echo "Error: Cannot find prp-to-tasks.js in $SCRIPT_DIR" >&2
  echo "SCRIPT_DIR detection may have failed." >&2
  echo "Try running with: bash /path/to/prp-orchestrator.sh ..." >&2
  exit 1
fi

# Task template file
TASK_TEMPLATE="$PLUGIN_ROOT/templates/current-task.md.template"

# Detect package manager for auto-installation
detect_package_manager() {
  if command -v brew &> /dev/null; then
    echo "brew"
  elif command -v apt-get &> /dev/null; then
    echo "apt"
  elif command -v yum &> /dev/null; then
    echo "yum"
  elif command -v dnf &> /dev/null; then
    echo "dnf"
  elif command -v pacman &> /dev/null; then
    echo "pacman"
  elif command -v apk &> /dev/null; then
    echo "apk"
  else
    echo "unknown"
  fi
}

# Prompt user to install a package
prompt_install() {
  local package="$1"
  local pkg_manager
  pkg_manager=$(detect_package_manager)

  echo ""
  echo "$package is required but not installed." >&2

  # Determine install command
  local install_cmd=""
  case "$pkg_manager" in
    brew)   install_cmd="brew install $package" ;;
    apt)    install_cmd="sudo apt-get install -y $package" ;;
    yum)    install_cmd="sudo yum install -y $package" ;;
    dnf)    install_cmd="sudo dnf install -y $package" ;;
    pacman) install_cmd="sudo pacman -S --noconfirm $package" ;;
    apk)    install_cmd="sudo apk add $package" ;;
    *)
      echo "Could not detect package manager. Please install $package manually." >&2
      return 1
      ;;
  esac

  # Prompt user
  echo -n "Install it now with '$install_cmd'? [y/N] " >&2
  read -r response

  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Installing $package..." >&2
    if eval "$install_cmd"; then
      echo "$package installed successfully." >&2
      return 0
    else
      echo "Failed to install $package." >&2
      return 1
    fi
  else
    echo "Skipping installation of $package." >&2
    return 1
  fi
}

# Check pre-requisites for isolated execution
check_prerequisites() {
  local missing=()
  local can_continue=true

  # Node.js is required for task extraction
  if ! command -v node &> /dev/null; then
    missing+=("node (required for PRP parsing)")
    can_continue=false
  fi

  # Claude CLI must be installed
  if ! command -v claude &> /dev/null; then
    missing+=("claude (Claude CLI must be installed)")
    can_continue=false
  fi

  # tmux is required on macOS/Linux when no native timeout command
  if [[ "$(uname)" != "MINGW"* ]] && [[ "$(uname)" != "CYGWIN"* ]]; then
    if ! command -v timeout &> /dev/null && ! command -v gtimeout &> /dev/null; then
      if ! command -v tmux &> /dev/null; then
        # Try to install tmux with user consent
        if prompt_install "tmux"; then
          echo "" >&2
        else
          missing+=("tmux (required for task timeout on macOS/Linux)")
          can_continue=false
        fi
      fi
    fi
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "" >&2
    echo "Error: Missing pre-requisites for isolated PRP execution:" >&2
    for item in "${missing[@]}"; do
      echo "  - $item" >&2
    done
    echo "" >&2
    echo "Install missing dependencies and try again." >&2
    exit 1
  fi
}

# Cleanup orphaned tmux sessions from previous interrupted runs
cleanup_orphaned_sessions() {
  if command -v tmux &> /dev/null; then
    local orphans
    orphans=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^prp-task-' || true)
    if [[ -n "$orphans" ]]; then
      echo "$orphans" | while read -r session; do
        echo "Cleaning up orphaned session: $session" >&2
        tmux kill-session -t "$session" 2>/dev/null || true
      done
    fi
  fi
}

# tmux-based timeout for macOS/Linux
# Runs command in a pseudo-terminal with proper stdin handling
tmux_timeout() {
  local timeout_seconds="$1"
  shift

  # Generate unique session name
  local session_name="prp-task-$$-$(date +%s)"

  # Properly quote arguments for tmux command
  # This preserves quote structure through the tmux invocation
  local cmd=""
  for arg in "$@"; do
    cmd="$cmd $(printf '%q' "$arg")"
  done

  # Cleanup handler
  cleanup_session() {
    tmux kill-session -t "$session_name" 2>/dev/null || true
  }
  trap cleanup_session EXIT INT TERM

  # Create detached tmux session running the command
  # Use remain-on-exit to capture exit status after completion
  # Note: cmd already includes bash -c from caller, don't double-wrap
  if ! tmux new-session -d -s "$session_name" -x 200 -y 50 "$cmd" 2>/dev/null; then
    echo "Error: Failed to create tmux session" >&2
    trap - EXIT
    return 1
  fi

  # Enable remain-on-exit to preserve pane after command exits
  tmux set-option -t "$session_name" remain-on-exit on 2>/dev/null

  # Poll for completion or timeout
  local start_time=$(date +%s)
  local elapsed=0

  while [[ $elapsed -lt $timeout_seconds ]]; do
    sleep 1
    elapsed=$(($(date +%s) - start_time))

    # Check if command finished (pane is dead)
    local pane_dead
    pane_dead=$(tmux display-message -t "$session_name" -p '#{pane_dead}' 2>/dev/null) || {
      # Session doesn't exist - unexpected termination
      trap - EXIT
      return 1
    }

    if [[ "$pane_dead" == "1" ]]; then
      # Command completed - capture output
      tmux capture-pane -t "$session_name" -p -S - -E - 2>/dev/null

      # Get exit status
      local exit_status
      exit_status=$(tmux display-message -t "$session_name" -p '#{pane_dead_status}' 2>/dev/null)

      # Cleanup
      tmux kill-session -t "$session_name" 2>/dev/null
      trap - EXIT

      return "${exit_status:-0}"
    fi
  done

  # Timeout reached
  echo "Timeout: Command exceeded ${timeout_seconds}s limit" >&2
  tmux capture-pane -t "$session_name" -p -S - -E - 2>/dev/null
  tmux kill-session -t "$session_name" 2>/dev/null
  trap - EXIT

  return 124
}

if command -v timeout &> /dev/null; then
  TIMEOUT_CMD="timeout"
elif command -v gtimeout &> /dev/null; then
  TIMEOUT_CMD="gtimeout"
elif command -v tmux &> /dev/null; then
  TIMEOUT_CMD="tmux_timeout"
else
  # This shouldn't happen if check_prerequisites passed
  echo "Error: No timeout mechanism available" >&2
  exit 1
fi

# Map exit codes to human-readable status messages
get_status_message() {
  local exit_code="$1"
  local timeout_seconds="${2:-$TIMEOUT}"

  case "$exit_code" in
    0)   echo "SUCCESS" ;;
    124) echo "TIMED OUT (after ${timeout_seconds}s)" ;;
    125) echo "TIMEOUT COMMAND FAILED" ;;
    126) echo "COMMAND NOT EXECUTABLE" ;;
    127) echo "COMMAND NOT FOUND" ;;
    130) echo "INTERRUPTED (Ctrl+C)" ;;
    137) echo "KILLED (SIGKILL)" ;;
    143) echo "TERMINATED (SIGTERM)" ;;
    *)   echo "FAILED (exit code $exit_code)" ;;
  esac
}

# Default values
MAX_RETRIES=3
TIMEOUT=300  # 5 minutes per task
MIN_ITERATIONS=1  # Minimum successful iterations per task (default: 1, use --iterations for more)
DRY_RUN=false
NO_SAFETY=false
SKIP_VALIDATION=false
RESUME=true   # Auto-resume is ON by default - use --fresh to start over
FRESH=false   # Explicit flag to force fresh start

# Safety configuration
BLOCKED_TOOLS="WebFetch,WebSearch,KillShell,Task,NotebookEdit"

# Run prerequisite checks and cleanup orphaned sessions
check_prerequisites
cleanup_orphaned_sessions

# Show help function
show_help() {
  cat <<EOF
PRP Isolated Orchestrator - Execute PRPs with hard session boundaries

USAGE:
  ./prp-orchestrator.sh <prp-file.md> [OPTIONS]

ARGUMENTS:
  prp-file.md    Path to PRP file with XML task structure

OPTIONS:
  --max-retries N     Max retry attempts per task (default: 3)
  --timeout M         Timeout in seconds per task (default: 300)
  --iterations N      Min successful iterations per task (default: 1)
  --fresh             Start fresh - ignore previous progress (default: auto-resume)
  --dry-run           Test mode - echo commands instead of running Claude
  --no-safety         Disable safety mode (use standard permissions)
  --skip-validation   Skip acceptance criteria validation
  --help, -h          Show this help message

NOTE:
  Auto-resume is enabled by default. If a previous run exists for the same PRP,
  completed tasks will be skipped automatically. Use --fresh to force a clean start.

DESCRIPTION:
  Executes each PRP task in a completely separate Claude session.
  Claude sees ONLY the current task - never the full PRP.

  This enforces hard session isolation at the process level.
  Claude cannot "optimize" by combining tasks.

SAFETY MODEL:
  By default, tasks run with --dangerously-skip-permissions for speed,
  but with layered safety:

  Layer 1: Tool Blocking
    Blocked tools: WebFetch, WebSearch, KillShell, Task, NotebookEdit
    Claude cannot access the web or spawn subagents

  Layer 2: Command Blocking (PreToolUse hook)
    Blocked patterns: rm -rf /, sudo, kill (non-dev), force push main
    See hooks/prp-safety-hook.sh for full list

  Use --no-safety to revert to standard permission prompts (slower)

EXAMPLE:
  ./prp-orchestrator.sh PRPs/my-feature.md              # Auto-resumes if prior progress exists
  ./prp-orchestrator.sh PRPs/my-feature.md --fresh      # Force fresh start, ignore prior progress
  ./prp-orchestrator.sh PRPs/my-feature.md --no-safety
  ./prp-orchestrator.sh PRPs/complex.md --timeout 600 --skip-validation

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
    --iterations)
      MIN_ITERATIONS="$2"
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
    --fresh)
      FRESH=true
      RESUME=false
      shift
      ;;
    --resume)
      # Legacy flag - resume is now default, but accept for backwards compatibility
      RESUME=true
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
  HAS_RESEARCH=$(echo "$TASKS_JSON" | jq -r '.research != null')
else
  # Fallback: use node for JSON parsing
  TOTAL=$(echo "$TASKS_JSON" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).total)")
  PRP_NAME=$(echo "$TASKS_JSON" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).name)")
  PRP_GOAL=""
  HAS_RESEARCH=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.research!==null)")
fi

# Extract and format research findings (if present)
RESEARCH_CONTEXT=""
if [[ "$HAS_RESEARCH" == "true" ]]; then
  # Use Node.js to format research findings into readable markdown
  RESEARCH_CONTEXT=$(echo "$TASKS_JSON" | node -e '
    const fs = require("fs");
    const data = JSON.parse(fs.readFileSync(0, "utf8"));
    const r = data.research;
    if (!r) { console.log(""); process.exit(0); }

    let out = "## Research Context (Don'\''t Reinvent the Wheel)\n\n";
    out += "The following research was conducted during PRP creation. Use these proven solutions.\n\n";

    if (r.libraries && r.libraries.length > 0) {
      out += "### Recommended Libraries\n\n";
      for (const lib of r.libraries) {
        out += `**${lib.name}** - ${lib.purpose}\n`;
        if (lib.rationale) out += `- Why: ${lib.rationale}\n`;
        if (lib.install) out += `- Install: \`${lib.install}\`\n`;
        if (lib.docsUrl) out += `- Docs: ${lib.docsUrl}\n`;
        out += "\n";
      }
    }

    if (r.patterns && r.patterns.length > 0) {
      out += "### Patterns to Follow\n\n";
      for (const p of r.patterns) {
        out += `- **${p.description || "Pattern"}**`;
        if (p.applicability) out += `: ${p.applicability}`;
        if (p.source && p.source !== "official docs") out += ` (Source: ${p.source})`;
        out += "\n";
      }
      out += "\n";
    }

    if (r.pitfalls && r.pitfalls.length > 0) {
      out += "### Pitfalls to Avoid\n\n";
      for (const p of r.pitfalls) {
        out += `- **${p.issue || "Issue"}**`;
        if (p.mitigation) out += `: ${p.mitigation}`;
        out += "\n";
      }
      out += "\n";
    }

    if (r.references && r.references.length > 0) {
      out += "### Key Documentation\n\n";
      for (const ref of r.references) {
        out += `- **${ref.topic}**: ${ref.url}\n`;
        if (ref.keyPoints && ref.keyPoints.length > 0) {
          for (const point of ref.keyPoints) {
            out += `  - ${point}\n`;
          }
        }
      }
      out += "\n";
    }

    console.log(out);
  ' 2>/dev/null)

  if [[ -n "$RESEARCH_CONTEXT" ]]; then
    echo "Research findings detected - will include in task context"
  fi
fi

# Function to get the PRP file path from an existing progress file
# Returns the PRP path or empty string if not found
get_progress_prp_file() {
  local progress_file="$1"
  if [[ -f "$progress_file" ]]; then
    # Look for "- PRP: <path>" line in the progress file
    grep -oP '^- PRP: \K.*' "$progress_file" 2>/dev/null | head -1 || true
  fi
}

# Function to get completed task IDs from progress file
# Returns a newline-separated list of task IDs that have "FULLY COMPLETE" status
get_completed_tasks() {
  local progress_file="$1"
  if [[ -f "$progress_file" ]]; then
    # Parse lines like "Task Status: FULLY COMPLETE" and extract the preceding task ID
    # Look for "### Task X.X:" headers followed by "Task Status: FULLY COMPLETE"
    grep -B 10 "Task Status: FULLY COMPLETE" "$progress_file" 2>/dev/null | \
      grep -oP '### Task \K[0-9]+\.[0-9]+' | sort -u || true
  fi
}

# Declare associative array for completed tasks (bash 4+)
declare -A COMPLETED_TASKS

# Resume logic: Auto-resume is ON by default
# Check for existing progress unless --fresh was specified
SKIPPED_COUNT=0
if [[ "$RESUME" == "true" ]] && [[ -f "$PROGRESS_FILE" ]]; then
  echo "Checking for previous progress..."

  # CRITICAL: Verify the progress file is for the SAME PRP
  EXISTING_PRP=$(get_progress_prp_file "$PROGRESS_FILE")

  if [[ -n "$EXISTING_PRP" ]] && [[ "$EXISTING_PRP" != "$PRP_FILE" ]]; then
    # Different PRP - the progress file is stale/from another run
    echo "Existing progress is for a different PRP:"
    echo "  Previous: $EXISTING_PRP"
    echo "  Current:  $PRP_FILE"
    echo "Starting fresh (previous progress will be overwritten)"
    echo ""
    # Don't load any completed tasks - start fresh
  else
    # Same PRP (or no PRP recorded) - safe to resume
    # Load completed task IDs into associative array
    while IFS= read -r task_id; do
      if [[ -n "$task_id" ]]; then
        COMPLETED_TASKS["$task_id"]=1
      fi
    done < <(get_completed_tasks "$PROGRESS_FILE")

    if [[ ${#COMPLETED_TASKS[@]} -gt 0 ]]; then
      echo "Found ${#COMPLETED_TASKS[@]} completed tasks from previous run"
      echo "Auto-resuming: Will skip completed tasks (use --fresh to start over)"
      for task_id in "${!COMPLETED_TASKS[@]}"; do
        echo "  - $task_id [complete]"
      done
      echo ""
    else
      echo "No completed tasks found - starting fresh"
    fi
  fi
elif [[ "$FRESH" == "true" ]]; then
  echo "Fresh start requested - ignoring any previous progress"
fi

# Initialize progress file
# If resuming with completed tasks, append to existing file; otherwise create fresh
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
if [[ ${#COMPLETED_TASKS[@]} -gt 0 ]]; then
  # Append resume session marker to existing progress file
  cat >> "$PROGRESS_FILE" <<EOF

---
## Resume Session
- Resumed: $TIMESTAMP
- Previously Completed: ${#COMPLETED_TASKS[@]} tasks
- Remaining: $((TOTAL - ${#COMPLETED_TASKS[@]})) tasks

EOF
else
  # Fresh start - overwrite progress file
  cat > "$PROGRESS_FILE" <<EOF
# PRP Execution Progress (Isolated Mode)

## Session Info
- PRP: $PRP_FILE
- Name: $PRP_NAME
- Started: $TIMESTAMP
- Total Tasks: $TOTAL
- Max Retries: $MAX_RETRIES
- Timeout: ${TIMEOUT}s
- Min Iterations: $MIN_ITERATIONS

## Task Log

EOF
fi

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
echo "Iterations: $MIN_ITERATIONS (per task)"
echo "Progress: $PROGRESS_FILE"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "Mode: DRY RUN (no Claude sessions)"
fi
if [[ ${#COMPLETED_TASKS[@]} -gt 0 ]]; then
  echo "Mode: AUTO-RESUME (skipping ${#COMPLETED_TASKS[@]} completed tasks)"
fi
if [[ "$FRESH" == "true" ]]; then
  echo "Mode: FRESH START (ignoring previous progress)"
fi
echo "=========================================="
echo ""

# Track stats
SUCCEEDED=0
FAILED=0
TOTAL_ITERATIONS=0

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
    TASK_TIMEOUT_HINT=$(echo "$TASKS_JSON" | jq -r ".tasks[$i].timeout // \"default\"")
    TASK_ITERATIONS=$(echo "$TASKS_JSON" | jq -r ".tasks[$i].iterations // \"default\"")
  else
    # Node.js fallback
    TASK_ID=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.tasks[$i].id)")
    TASK_AGENT=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.tasks[$i].agent)")
    TASK_DESC=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.tasks[$i].description)")
    TASK_TIMEOUT_HINT=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.tasks[$i].timeout||'default')")
    TASK_ITERATIONS=$(echo "$TASKS_JSON" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(d.tasks[$i].iterations||'default')")
    TASK_CRITERIA=""
    TASK_FILES=""
    TASK_PSEUDO=""
  fi

  # Resume mode: Skip already-completed tasks
  if [[ "$RESUME" == "true" ]] && [[ -n "${COMPLETED_TASKS[$TASK_ID]:-}" ]]; then
    echo ""
    echo "=========================================="
    echo "TASK $TASK_NUM / $TOTAL: $TASK_ID [SKIPPED - Already Complete]"
    echo "=========================================="
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    SUCCEEDED=$((SUCCEEDED + 1))  # Count as succeeded for final stats
    continue
  fi

  # Determine effective timeout for this task
  # Supports: numeric value (e.g., "900"), "extended" (600s), or default
  if [[ "$TASK_TIMEOUT_HINT" =~ ^[0-9]+$ ]]; then
    # Numeric timeout specified in PRP
    EFFECTIVE_TIMEOUT=$TASK_TIMEOUT_HINT
    echo "Note: Using task-specified timeout (${EFFECTIVE_TIMEOUT}s)"
  elif [[ "$TASK_TIMEOUT_HINT" == "extended" ]]; then
    EFFECTIVE_TIMEOUT=600
    echo "Note: Using extended timeout (600s) for this task"
  else
    EFFECTIVE_TIMEOUT=$TIMEOUT
  fi

  # Create truncated task title for progress log readability
  TASK_TITLE=$(echo "$TASK_DESC" | head -c 80 | tr '\n' ' ')
  if [[ ${#TASK_DESC} -gt 80 ]]; then
    TASK_TITLE="${TASK_TITLE}..."
  fi

  echo ""
  echo "=========================================="
  echo "TASK $TASK_NUM / $TOTAL: $TASK_ID"
  echo "Agent: $TASK_AGENT"
  echo "Description: $TASK_DESC"
  echo "=========================================="

  # Track iterations for this task
  ITERATIONS_COMPLETED=0
  TASK_FULLY_COMPLETE=false

  # Determine effective iterations for this task
  # Supports: numeric value (e.g., "3"), or default to global MIN_ITERATIONS
  if [[ "$TASK_ITERATIONS" =~ ^[0-9]+$ ]]; then
    EFFECTIVE_ITERATIONS=$TASK_ITERATIONS
    echo "Note: Using task-specified iterations ($EFFECTIVE_ITERATIONS)"
  else
    EFFECTIVE_ITERATIONS=$MIN_ITERATIONS
  fi

  # Outer loop: Success iterations (Ralph Loop philosophy)
  # Each task must complete EFFECTIVE_ITERATIONS successful runs before moving on
  while [[ $ITERATIONS_COMPLETED -lt $EFFECTIVE_ITERATIONS ]] && [[ "$TASK_FULLY_COMPLETE" == "false" ]]; do
    CURRENT_ITERATION=$((ITERATIONS_COMPLETED + 1))
    echo "Iteration $CURRENT_ITERATION of $EFFECTIVE_ITERATIONS..."

    # Re-render template with iteration context for this iteration
    if [[ -f "$TASK_TEMPLATE" ]]; then
      export TASK_ID TASK_DESC TASK_FILES TASK_PSEUDO TASK_CRITERIA TASK_AGENT PRP_NAME PRP_FILE RESEARCH_CONTEXT
      export TASK_FILE_PATH="$TASK_FILE"
      export TEMPLATE_PATH="$TASK_TEMPLATE"

      node -e '
        const fs = require("fs");
        const template = fs.readFileSync(process.env.TEMPLATE_PATH, "utf8");
        const vars = {
          TASK_ID: process.env.TASK_ID || "",
          TASK_DESC: process.env.TASK_DESC || "",
          TASK_FILES: process.env.TASK_FILES || "",
          TASK_PSEUDO: process.env.TASK_PSEUDO || "",
          TASK_CRITERIA: process.env.TASK_CRITERIA || "",
          TASK_AGENT: process.env.TASK_AGENT || "",
          PRP_NAME: process.env.PRP_NAME || "",
          PRP_FILE: process.env.PRP_FILE || "",
          RESEARCH_CONTEXT: process.env.RESEARCH_CONTEXT || ""
        };
        let output = template;
        for (const [key, value] of Object.entries(vars)) {
          output = output.split("{{" + key + "}}").join(value);
        }
        fs.writeFileSync(process.env.TASK_FILE_PATH, output);
      ' 2>/dev/null

      if [[ ! -f "$TASK_FILE" ]] || [[ ! -s "$TASK_FILE" ]]; then
        echo "Warning: Template rendering failed, using inline fallback" >&2
        USE_ITERATION_FALLBACK=true
      else
        USE_ITERATION_FALLBACK=false
      fi
    else
      USE_ITERATION_FALLBACK=true
    fi

    if [[ "$USE_ITERATION_FALLBACK" == "true" ]]; then
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

$RESEARCH_CONTEXT

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
    fi

    # Log iteration start
    echo "### Task $TASK_ID: $TASK_TITLE" >> "$PROGRESS_FILE"
    echo "#### Iteration $CURRENT_ITERATION - $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROGRESS_FILE"

    # Reset retry counter for this iteration (fresh start)
    RETRIES=0
    ITERATION_SUCCESS=false

    # Inner loop: Retry on failure (existing logic)
    while [[ $RETRIES -lt $MAX_RETRIES ]] && [[ "$ITERATION_SUCCESS" == "false" ]]; do
      ATTEMPT=$((RETRIES + 1))
      echo "  Attempt $ATTEMPT of $MAX_RETRIES..."

      # Log attempt start
      echo "  Attempt $ATTEMPT - $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROGRESS_FILE"

      # Spawn fresh Claude session for THIS task only
      # Using -p for print mode (non-interactive)
      if [[ "$DRY_RUN" == "true" ]]; then
        # Dry run mode - simulate success
        echo "[DRY RUN] Would execute: claude -p \"Read .claude/current-task.md and execute task $TASK_ID\""
        echo "[DRY RUN] Task file contents:"
        head -10 "$TASK_FILE" | sed 's/^/    /'
        echo "    ..."
        sleep 0.5  # Brief pause to simulate work
        ITERATION_SUCCESS=true
        ITERATIONS_COMPLETED=$((ITERATIONS_COMPLETED + 1))
        TOTAL_ITERATIONS=$((TOTAL_ITERATIONS + 1))
        echo "  Status: SUCCESS (dry-run, iteration $CURRENT_ITERATION)" >> "$PROGRESS_FILE"
        echo "  Iteration $CURRENT_ITERATION: SUCCESS (dry-run)"
      else
        # Build Claude command based on safety mode
        # CRITICAL: Use --dangerously-skip-permissions to bypass all permission checks
        # The -p flag already skips the workspace trust dialog
        # Safety is enforced via --disallowedTools instead
        CLAUDE_PROMPT="Read .claude/current-task.md and execute the task described. When complete, simply exit."

        if [[ "$NO_SAFETY" == "true" ]]; then
          # User explicitly disabled safety - use standard permissions
          CLAUDE_FULL_CMD="claude -p '$CLAUDE_PROMPT'"
        else
          # Default: skip permissions but block dangerous tools
          CLAUDE_FULL_CMD="claude --dangerously-skip-permissions --disallowedTools $BLOCKED_TOOLS -p '$CLAUDE_PROMPT'"
        fi

        # Execute with timeout and capture output
        # Uses EFFECTIVE_TIMEOUT which may be extended for test/build tasks
        CLAUDE_OUTPUT=$($TIMEOUT_CMD "$EFFECTIVE_TIMEOUT" bash -c "$CLAUDE_FULL_CMD" 2>&1)
        EXIT_CODE=$?

        if [[ $EXIT_CODE -eq 0 ]]; then
          ITERATION_SUCCESS=true
          ITERATIONS_COMPLETED=$((ITERATIONS_COMPLETED + 1))
          TOTAL_ITERATIONS=$((TOTAL_ITERATIONS + 1))
          echo "  Status: SUCCESS (iteration $CURRENT_ITERATION)" >> "$PROGRESS_FILE"
          echo "  Iteration $CURRENT_ITERATION: SUCCESS"
        else
          RETRIES=$((RETRIES + 1))
          echo "  Status: $(get_status_message $EXIT_CODE $EFFECTIVE_TIMEOUT)" >> "$PROGRESS_FILE"
          echo "  Iteration $CURRENT_ITERATION, attempt $ATTEMPT: $(get_status_message $EXIT_CODE $EFFECTIVE_TIMEOUT)"

          # Capture error output for debugging
          echo "  ### Error Output (last 50 lines)" >> "$PROGRESS_FILE"
          echo '  ```' >> "$PROGRESS_FILE"
          echo "$CLAUDE_OUTPUT" | tail -50 | sed 's/^/  /' >> "$PROGRESS_FILE"
          echo '  ```' >> "$PROGRESS_FILE"

          if [[ $RETRIES -lt $MAX_RETRIES ]]; then
            BACKOFF=$((2 ** RETRIES))
            echo "  Retrying in ${BACKOFF} seconds..."
            sleep $BACKOFF
          fi
        fi
      fi
    done

    # If this iteration exhausted retries without success, mark task as failed
    if [[ "$ITERATION_SUCCESS" == "false" ]]; then
      echo "  Iteration $CURRENT_ITERATION: FAILED after $MAX_RETRIES attempts" >> "$PROGRESS_FILE"
      echo "  Iteration $CURRENT_ITERATION: FAILED after $MAX_RETRIES attempts"
      TASK_FULLY_COMPLETE=true  # Exit iteration loop
      FAILED=$((FAILED + 1))
    fi

    # Brief pause between iterations (if more iterations needed)
    if [[ $ITERATIONS_COMPLETED -lt $EFFECTIVE_ITERATIONS ]] && [[ "$ITERATION_SUCCESS" == "true" ]]; then
      echo "  Pausing before next iteration..."
      sleep 1
    fi
  done

  # Only count as succeeded if ALL iterations completed
  if [[ $ITERATIONS_COMPLETED -eq $EFFECTIVE_ITERATIONS ]]; then
    SUCCEEDED=$((SUCCEEDED + 1))
    echo "Task $TASK_ID: FULLY COMPLETE ($EFFECTIVE_ITERATIONS iterations)"
    echo "Task Status: FULLY COMPLETE ($EFFECTIVE_ITERATIONS/$EFFECTIVE_ITERATIONS iterations)" >> "$PROGRESS_FILE"
  fi

  echo "" >> "$PROGRESS_FILE"

  # Cleanup: Clear current task file between tasks
  if [[ -f "$TASK_FILE" ]]; then
    rm -f "$TASK_FILE"
  fi

  # Brief pause between tasks
  sleep 1
done

# Final summary
echo ""
echo "=========================================="
echo "  EXECUTION COMPLETE"
echo "=========================================="
echo "Total Tasks: $TOTAL"
echo "Succeeded (all iterations): $SUCCEEDED"
if [[ $SKIPPED_COUNT -gt 0 ]]; then
  echo "  (includes $SKIPPED_COUNT skipped/resumed)"
fi
echo "Failed: $FAILED"
echo "Total Iterations Run: $TOTAL_ITERATIONS"
echo "Target Iterations/Task: $MIN_ITERATIONS"
echo "=========================================="

# Append summary to progress file
cat >> "$PROGRESS_FILE" <<EOF

## Summary
- Completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Tasks Succeeded: $SUCCEEDED / $TOTAL
- Tasks Skipped (resumed): $SKIPPED_COUNT
- Tasks Failed: $FAILED
- Total Iterations: $TOTAL_ITERATIONS
- Target Iterations/Task: $MIN_ITERATIONS
EOF

# Final cleanup: Remove task file if it exists
if [[ -f "$TASK_FILE" ]]; then
  rm -f "$TASK_FILE"
  echo "Cleaned up: $TASK_FILE"
fi

# Exit with appropriate code
if [[ $FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi

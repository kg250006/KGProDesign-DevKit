#!/bin/bash

# Ralph Loop Setup Script
# Creates state file for in-session Ralph loop

set -euo pipefail

# Parse arguments
PROMPT_PARTS=()
MAX_ITERATIONS=20
COMPLETION_PROMISE="null"
READ_ARGS_FROM_STDIN=false
FRESH_CONTEXT=false
MAX_RETRIES=0
RESUME_MODE=false

# Check for --args-stdin flag first (must be only arg when used)
if [[ "${1:-}" == "--args-stdin" ]]; then
  READ_ARGS_FROM_STDIN=true
  shift
fi

# If reading from stdin, get the full input and parse it
if [[ "$READ_ARGS_FROM_STDIN" == "true" ]]; then
  # Read entire stdin content
  STDIN_CONTENT=$(cat)

  # Parse --max-iterations from stdin content
  if [[ "$STDIN_CONTENT" =~ --max-iterations[[:space:]]+([0-9]+) ]]; then
    MAX_ITERATIONS="${BASH_REMATCH[1]}"
    # Remove the flag from content
    STDIN_CONTENT=$(echo "$STDIN_CONTENT" | sed -E 's/--max-iterations[[:space:]]+[0-9]+//')
  fi

  # Parse --completion-promise from stdin content (handles quoted strings)
  # Match: --completion-promise "text" or --completion-promise 'text' or --completion-promise text
  if [[ "$STDIN_CONTENT" =~ --completion-promise[[:space:]]+[\"\']([^\"\']+)[\"\'] ]]; then
    COMPLETION_PROMISE="${BASH_REMATCH[1]}"
    STDIN_CONTENT=$(echo "$STDIN_CONTENT" | sed -E "s/--completion-promise[[:space:]]+[\"'][^\"']+[\"']//")
  elif [[ "$STDIN_CONTENT" =~ --completion-promise[[:space:]]+([^[:space:]]+) ]]; then
    COMPLETION_PROMISE="${BASH_REMATCH[1]}"
    STDIN_CONTENT=$(echo "$STDIN_CONTENT" | sed -E 's/--completion-promise[[:space:]]+[^[:space:]]+//')
  fi

  # Parse --fresh-context flag (boolean)
  if [[ "$STDIN_CONTENT" =~ --fresh-context ]]; then
    FRESH_CONTEXT=true
    STDIN_CONTENT=$(echo "$STDIN_CONTENT" | sed -E 's/--fresh-context//')
  fi

  # Parse --max-retries from stdin content
  if [[ "$STDIN_CONTENT" =~ --max-retries[[:space:]]+([0-9]+) ]]; then
    MAX_RETRIES="${BASH_REMATCH[1]}"
    STDIN_CONTENT=$(echo "$STDIN_CONTENT" | sed -E 's/--max-retries[[:space:]]+[0-9]+//')
  fi

  # Parse --resume flag (boolean)
  if [[ "$STDIN_CONTENT" =~ --resume ]]; then
    RESUME_MODE=true
    STDIN_CONTENT=$(echo "$STDIN_CONTENT" | sed -E 's/--resume//')
  fi

  # Remaining content is the prompt (trim leading/trailing whitespace but preserve internal newlines)
  PROMPT=$(echo "$STDIN_CONTENT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
fi

# Parse options and positional arguments (for non-stdin mode)
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Ralph Loop - Interactive self-referential development loop

USAGE:
  /$PLUGIN_NAME:ralph-loop [PROMPT...] [OPTIONS]
  /$PLUGIN_NAME:ralph-loop --resume [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words without quotes)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: 20)
  --completion-promise '<text>'  Promise phrase (USE QUOTES for multi-word)
  --max-retries <n>              Max retries per task before marking blocked (default: 0/disabled)
  --fresh-context                Enable session isolation mode (fresh context each iteration)
  --resume                       Resume from previous progress file
  --args-stdin                   Read all arguments from stdin (for multi-line prompts)
  -h, --help                     Show this help message

DESCRIPTION:
  Starts a Ralph Loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  To signal completion, you must output: <promise>YOUR_PHRASE</promise>

  Use this for:
  - Interactive iteration where you want to see progress
  - Tasks requiring self-correction and refinement
  - Learning how Ralph works

FRESH CONTEXT MODE (--fresh-context):
  For long-running tasks (10+ iterations), enables session isolation:
  - Each iteration ends the session cleanly
  - Progress is tracked in .claude/ralph-progress.md
  - Use --resume to continue after each iteration
  - Prevents context rot for complex tasks

EXAMPLES:
  /$PLUGIN_NAME:ralph-loop Build a todo API --completion-promise 'DONE' --max-iterations 20
  /$PLUGIN_NAME:ralph-loop --max-iterations 10 Fix the auth bug
  /$PLUGIN_NAME:ralph-loop Refactor cache layer  (runs forever)
  /$PLUGIN_NAME:ralph-loop --completion-promise 'TASK COMPLETE' Create a REST API
  /$PLUGIN_NAME:ralph-loop --fresh-context --max-iterations 30 Complex refactoring
  /$PLUGIN_NAME:ralph-loop --resume  (continue interrupted loop)

STOPPING:
  Only by reaching --max-iterations or detecting --completion-promise
  No manual stop - Ralph runs infinitely by default!

MONITORING:
  # View current iteration:
  grep '^iteration:' .claude/ralph-loop.local.md

  # View full state:
  head -10 .claude/ralph-loop.local.md

  # View progress (fresh-context mode):
  cat .claude/ralph-progress.md

AVAILABLE AGENTS:
  Use the Task tool with subagent_type to delegate work to specialized agents:

  backend-engineer     - APIs, auth, services, business logic, server-side scripts
  frontend-engineer    - UI components, accessibility, performance, responsive design
  data-engineer        - Schema design, migrations, queries, data modeling
  qa-engineer          - Testing, security, code review, quality analysis
  devops-engineer      - CI/CD, Docker, infrastructure, monitoring
  document-specialist  - Documentation, PRDs, technical writing, README files
  project-coordinator  - Sprint planning, task breakdown, progress tracking

  Example Task tool usage in your prompt:
    "Use the Task tool with subagent_type='backend-engineer' to implement the API"
    "Delegate to qa-engineer agent to write tests for this feature"

AUTOMATIC RESPAWN (fresh-context mode):
  For fully automatic session respawn, use the wrapper scripts:
    ./scripts/ralph-auto.sh     (macOS/Linux)
    ./scripts/ralph-auto.ps1    (Windows)

  The wrapper monitors the state file and automatically restarts
  Claude sessions when continue_next: true is detected.
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        echo "" >&2
        echo "   You provided: --max-iterations (with no number)" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations must be a positive integer or 0, got: $2" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        echo "" >&2
        echo "   Invalid: decimals (10.5), negative numbers (-5), text" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires a text argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --completion-promise 'DONE'" >&2
        echo "     --completion-promise 'TASK COMPLETE'" >&2
        echo "     --completion-promise 'All tests passing'" >&2
        echo "" >&2
        echo "   You provided: --completion-promise (with no text)" >&2
        echo "" >&2
        echo "   Note: Multi-word promises must be quoted!" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --fresh-context)
      FRESH_CONTEXT=true
      shift
      ;;
    --max-retries)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-retries requires a number argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-retries 3" >&2
        echo "     --max-retries 5" >&2
        echo "     --max-retries 0  (disabled)" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-retries must be a positive integer or 0, got: $2" >&2
        exit 1
      fi
      MAX_RETRIES="$2"
      shift 2
      ;;
    --resume)
      RESUME_MODE=true
      shift
      ;;
    *)
      # Non-option argument - collect all as prompt parts
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# Get prompt from command-line arguments if not already set from stdin
if [[ "$READ_ARGS_FROM_STDIN" != "true" ]]; then
  # Join all prompt parts with spaces
  PROMPT="${PROMPT_PARTS[*]}"
fi

# Handle resume mode
if [[ "$RESUME_MODE" == "true" ]]; then
  STATE_FILE=".claude/ralph-loop.local.md"

  # Check for existing state file
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "Error: No active Ralph loop to resume" >&2
    echo "" >&2
    echo "   No state file found at: $STATE_FILE" >&2
    echo "   Start a new loop with: /\$PLUGIN_NAME:ralph-loop 'your prompt'" >&2
    exit 1
  fi

  # Validate state file has active: true
  if ! grep -q '^active: true' "$STATE_FILE"; then
    echo "Error: Ralph loop is not active" >&2
    echo "" >&2
    echo "   State file exists but loop is not active." >&2
    echo "   Start a new loop with: /\$PLUGIN_NAME:ralph-loop 'your prompt'" >&2
    exit 1
  fi

  # Read existing values from state file
  RESUME_FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
  RESUME_ITERATION=$(echo "$RESUME_FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
  RESUME_MAX_ITER=$(echo "$RESUME_FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
  RESUME_PROMISE=$(echo "$RESUME_FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')
  RESUME_ISOLATION=$(echo "$RESUME_FRONTMATTER" | grep '^isolation_mode:' | sed 's/isolation_mode: *//')
  RESUME_MAX_RETRIES=$(echo "$RESUME_FRONTMATTER" | grep '^max_retries:' | sed 's/max_retries: *//')

  # Read prompt from state file
  RESUME_PROMPT=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE")

  # Reset continue_next marker
  if grep -q '^continue_next: true' "$STATE_FILE"; then
    TEMP_FILE="${STATE_FILE}.tmp.$$"
    sed 's/^continue_next: true/continue_next: false/' "$STATE_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$STATE_FILE"
  fi

  # Display resume info
  echo "Resuming Ralph loop from iteration $RESUME_ITERATION"
  echo ""
  echo "State file: $STATE_FILE"
  echo "Progress: .claude/ralph-progress.md"
  echo "Max iterations: $RESUME_MAX_ITER"
  echo "Isolation mode: $RESUME_ISOLATION"
  if [[ "$RESUME_PROMISE" != "null" ]]; then
    echo "Completion promise: $RESUME_PROMISE"
  fi

  # Show progress summary if available
  PROGRESS_FILE=".claude/ralph-progress.md"
  if [[ -f "$PROGRESS_FILE" ]]; then
    SUCCESS_COUNT=$(grep -c 'Status: SUCCESS' "$PROGRESS_FILE" 2>/dev/null || echo 0)
    FAILED_COUNT=$(grep -c 'Status: FAILED' "$PROGRESS_FILE" 2>/dev/null || echo 0)
    BLOCKED_COUNT=$(grep -c 'Status: BLOCKED' "$PROGRESS_FILE" 2>/dev/null || echo 0)

    echo ""
    echo "Progress Summary:"
    echo "  Completed: $SUCCESS_COUNT"
    echo "  Failed: $FAILED_COUNT"
    echo "  Blocked: $BLOCKED_COUNT"
  fi

  echo ""
  echo "$RESUME_PROMPT"

  # Display completion promise requirements if set
  if [[ "$RESUME_PROMISE" != "null" ]] && [[ -n "$RESUME_PROMISE" ]]; then
    echo ""
    echo "==============================================================="
    echo "CRITICAL - Ralph Loop Completion Promise"
    echo "==============================================================="
    echo ""
    echo "To complete this loop, output this EXACT text:"
    echo "  <promise>$RESUME_PROMISE</promise>"
    echo "==============================================================="
  fi

  exit 0
fi

# Validate prompt is non-empty (for new loops)
if [[ -z "$PROMPT" ]]; then
  echo "Error: No prompt provided" >&2
  echo "" >&2
  echo "   Ralph needs a task description to work on." >&2
  echo "" >&2
  echo "   Examples:" >&2
  echo "     /\$PLUGIN_NAME:ralph-loop Build a REST API for todos" >&2
  echo "     /\$PLUGIN_NAME:ralph-loop Fix the auth bug --max-iterations 20" >&2
  echo "     /\$PLUGIN_NAME:ralph-loop --completion-promise 'DONE' Refactor code" >&2
  echo "" >&2
  echo "   For all options: /\$PLUGIN_NAME:ralph-loop --help" >&2
  exit 1
fi

# Create state file for stop hook (markdown with YAML frontmatter)
mkdir -p .claude

# Quote completion promise for YAML if it contains special chars or is not null
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

# Prepare isolation mode YAML value
if [[ "$FRESH_CONTEXT" == "true" ]]; then
  ISOLATION_MODE_YAML="true"
else
  ISOLATION_MODE_YAML="false"
fi

cat > .claude/ralph-loop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
max_retries: $MAX_RETRIES
completion_promise: $COMPLETION_PROMISE_YAML
isolation_mode: $ISOLATION_MODE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
continue_next: false
current_task: null
task_retries: {}
---

$PROMPT
EOF

# Initialize progress file (new loop or fresh start - skip if resuming)
if [[ "$RESUME_MODE" != "true" ]]; then
  MODE_DISPLAY=$(if [[ "$FRESH_CONTEXT" == "true" ]]; then echo "fresh-context"; else echo "in-session"; fi)
  cat > .claude/ralph-progress.md <<EOF
# Ralph Loop Progress Log

## Session Info
- Source: $PROMPT
- Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Mode: $MODE_DISPLAY
- Max Iterations: $MAX_ITERATIONS
- Max Retries: $MAX_RETRIES
- Completion Promise: $COMPLETION_PROMISE

## Iterations

EOF
fi

# Output setup message
cat <<EOF
Ralph loop activated in this session!

Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Max retries: $(if [[ $MAX_RETRIES -gt 0 ]]; then echo "$MAX_RETRIES per task"; else echo "disabled"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE//\"/} (ONLY output when TRUE - do not lie!)"; else echo "none (runs forever)"; fi)
Isolation mode: $(if [[ "$FRESH_CONTEXT" == "true" ]]; then echo "ENABLED (fresh context per iteration)"; else echo "disabled (in-session)"; fi)

The stop hook is now active. When you try to exit, the SAME PROMPT will be
fed back to you. You'll see your previous work in files, creating a
self-referential loop where you iteratively improve on the same task.

To monitor: head -10 .claude/ralph-loop.local.md

WARNING: This loop cannot be stopped manually! It will run infinitely
    unless you set --max-iterations or --completion-promise.

EOF

# Output the initial prompt if provided
if [[ -n "$PROMPT" ]]; then
  echo ""
  echo "$PROMPT"
fi

# Display completion promise requirements if set
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "==============================================================="
  echo "CRITICAL - Ralph Loop Completion Promise"
  echo "==============================================================="
  echo ""
  echo "To complete this loop, output this EXACT text:"
  echo "  <promise>$COMPLETION_PROMISE</promise>"
  echo ""
  echo "STRICT REQUIREMENTS (DO NOT VIOLATE):"
  echo "  - Use <promise> XML tags EXACTLY as shown above"
  echo "  - The statement MUST be completely and unequivocally TRUE"
  echo "  - Do NOT output false statements to exit the loop"
  echo "  - Do NOT lie even if you think you should exit"
  echo ""
  echo "IMPORTANT - Do not circumvent the loop:"
  echo "  Even if you believe you're stuck, the task is impossible,"
  echo "  or you've been running too long - you MUST NOT output a"
  echo "  false promise statement. The loop is designed to continue"
  echo "  until the promise is GENUINELY TRUE. Trust the process."
  echo ""
  echo "  If the loop should stop, the promise statement will become"
  echo "  true naturally. Do not force it by lying."
  echo "==============================================================="
fi

#Requires -Version 5.1
<#
.SYNOPSIS
    Ralph Loop Setup Script - PowerShell implementation for Windows
.DESCRIPTION
    Creates state file for in-session Ralph loop.
    This is the Windows equivalent of setup-ralph-loop.sh with exact feature parity.
#>

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$PromptParts,

    [Alias("max-iterations")]
    [int]$MaxIterations = 20,

    [Alias("completion-promise")]
    [string]$CompletionPromise = "null",

    [Alias("max-retries")]
    [int]$MaxRetries = 0,

    [Alias("fresh-context")]
    [switch]$FreshContext,

    [switch]$Resume,

    [switch]$ArgsStdin,

    [Alias("h")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Function to get plugin prefix from plugin.json
function Get-PluginPrefix {
    $pluginRoot = $env:CLAUDE_PLUGIN_ROOT
    if (-not $pluginRoot) {
        $pluginRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    }

    $pluginJson = Join-Path $pluginRoot ".claude-plugin" "plugin.json"
    if (Test-Path $pluginJson) {
        try {
            $config = Get-Content $pluginJson -Raw | ConvertFrom-Json
            if ($config.name) {
                return $config.name
            }
        } catch {
            # Fall through to default
        }
    }
    return "KGP"
}

$PluginName = Get-PluginPrefix

# Show help
if ($Help) {
    $helpText = @"
Ralph Loop - Interactive self-referential development loop

USAGE:
  /${PluginName}:ralph-loop [PROMPT...] [OPTIONS]
  /${PluginName}:ralph-loop -Resume [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words without quotes)

OPTIONS:
  -MaxIterations <n>           Maximum iterations before auto-stop (default: 20)
  -CompletionPromise '<text>'  Promise phrase (USE QUOTES for multi-word)
  -MaxRetries <n>              Max retries per task before marking blocked (default: 0/disabled)
  -FreshContext                Enable session isolation mode (fresh context each iteration)
  -Resume                      Resume from previous progress file
  -ArgsStdin                   Read all arguments from stdin (for multi-line prompts)
  -Help, -h                    Show this help message

DESCRIPTION:
  Starts a Ralph Loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  To signal completion, you must output: <promise>YOUR_PHRASE</promise>

  Use this for:
  - Interactive iteration where you want to see progress
  - Tasks requiring self-correction and refinement
  - Learning how Ralph works

FRESH CONTEXT MODE (-FreshContext):
  For long-running tasks (10+ iterations), enables session isolation:
  - Each iteration ends the session cleanly
  - Progress is tracked in .claude/ralph-progress.md
  - Use -Resume to continue after each iteration
  - Prevents context rot for complex tasks

EXAMPLES:
  /${PluginName}:ralph-loop Build a todo API -CompletionPromise 'DONE' -MaxIterations 20
  /${PluginName}:ralph-loop -MaxIterations 10 Fix the auth bug
  /${PluginName}:ralph-loop Refactor cache layer  (runs forever)
  /${PluginName}:ralph-loop -CompletionPromise 'TASK COMPLETE' Create a REST API
  /${PluginName}:ralph-loop -FreshContext -MaxIterations 30 Complex refactoring
  /${PluginName}:ralph-loop -Resume  (continue interrupted loop)

STOPPING:
  Only by reaching -MaxIterations or detecting -CompletionPromise
  No manual stop - Ralph runs infinitely by default!

MONITORING:
  # View current iteration:
  Select-String '^iteration:' .claude/${PluginName}:ralph-loop.local.md

  # View full state:
  Get-Content .claude/${PluginName}:ralph-loop.local.md -TotalCount 10

  # View progress (fresh-context mode):
  Get-Content .claude/ralph-progress.md

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
"@
    Write-Output $helpText
    exit 0
}

# Initialize prompt variable
$Prompt = ""

# If reading from stdin, get the full input and parse it
if ($ArgsStdin) {
    $stdinContent = [Console]::In.ReadToEnd()

    # Parse --max-iterations from stdin content
    if ($stdinContent -match '--max-iterations\s+(\d+)') {
        $MaxIterations = [int]$Matches[1]
        $stdinContent = $stdinContent -replace '--max-iterations\s+\d+', ''
    }

    # Parse --completion-promise from stdin content (handles quoted strings)
    if ($stdinContent -match '--completion-promise\s+["\''](.*?)["\'']') {
        $CompletionPromise = $Matches[1]
        $stdinContent = $stdinContent -replace '--completion-promise\s+["\''](.*?)["\'']', ''
    } elseif ($stdinContent -match '--completion-promise\s+(\S+)') {
        $CompletionPromise = $Matches[1]
        $stdinContent = $stdinContent -replace '--completion-promise\s+\S+', ''
    }

    # Parse --fresh-context flag
    if ($stdinContent -match '--fresh-context') {
        $FreshContext = $true
        $stdinContent = $stdinContent -replace '--fresh-context', ''
    }

    # Parse --max-retries from stdin content
    if ($stdinContent -match '--max-retries\s+(\d+)') {
        $MaxRetries = [int]$Matches[1]
        $stdinContent = $stdinContent -replace '--max-retries\s+\d+', ''
    }

    # Parse --resume flag
    if ($stdinContent -match '--resume') {
        $Resume = $true
        $stdinContent = $stdinContent -replace '--resume', ''
    }

    # Remaining content is the prompt (trim leading/trailing whitespace but preserve internal newlines)
    $Prompt = $stdinContent.Trim()
} else {
    # Join all prompt parts with spaces
    if ($PromptParts -and $PromptParts.Count -gt 0) {
        $Prompt = $PromptParts -join ' '
    }
}

# Handle resume mode
if ($Resume) {
    $stateFile = ".claude/${PluginName}:ralph-loop.local.md"

    if (-not (Test-Path $stateFile)) {
        Write-Host "Error: No active Ralph loop to resume" -ForegroundColor Red
        Write-Host ""
        Write-Host "   No state file found at: $stateFile"
        Write-Host "   Start a new loop with: /${PluginName}:ralph-loop 'your prompt'"
        exit 1
    }

    $stateContent = Get-Content $stateFile -Raw

    if ($stateContent -notmatch 'active:\s*true') {
        Write-Host "Error: Ralph loop is not active" -ForegroundColor Red
        Write-Host ""
        Write-Host "   State file exists but loop is not active."
        Write-Host "   Start a new loop with: /${PluginName}:ralph-loop 'your prompt'"
        exit 1
    }

    # Extract values from frontmatter
    $resumeIteration = "1"
    $resumeMaxIter = "20"
    $resumePromise = "null"
    $resumeIsolation = "false"
    $resumeMaxRetries = "0"

    if ($stateContent -match '(?m)^iteration:\s*(\d+)') { $resumeIteration = $Matches[1] }
    if ($stateContent -match '(?m)^max_iterations:\s*(\d+)') { $resumeMaxIter = $Matches[1] }
    if ($stateContent -match '(?m)^completion_promise:\s*"?([^"\r\n]+)"?') { $resumePromise = $Matches[1] }
    if ($stateContent -match '(?m)^isolation_mode:\s*(\w+)') { $resumeIsolation = $Matches[1] }
    if ($stateContent -match '(?m)^max_retries:\s*(\d+)') { $resumeMaxRetries = $Matches[1] }

    # Extract prompt (everything after second ---)
    $resumePromptText = ""
    if ($stateContent -match '(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$') {
        $resumePromptText = $Matches[1]
    }

    # Reset continue_next marker
    if ($stateContent -match 'continue_next:\s*true') {
        $stateContent = $stateContent -replace '(?m)^continue_next:\s*true', 'continue_next: false'
        Set-Content -Path $stateFile -Value $stateContent -NoNewline
    }

    # Display resume info
    Write-Output "Resuming Ralph loop from iteration $resumeIteration"
    Write-Output ""
    Write-Output "State file: $stateFile"
    Write-Output "Progress: .claude/ralph-progress.md"
    Write-Output "Max iterations: $resumeMaxIter"
    Write-Output "Isolation mode: $resumeIsolation"
    if ($resumePromise -ne "null") {
        Write-Output "Completion promise: $resumePromise"
    }

    # Show progress summary if available
    $progressFile = ".claude/ralph-progress.md"
    if (Test-Path $progressFile) {
        $progressContent = Get-Content $progressFile -Raw
        $successCount = ([regex]::Matches($progressContent, 'Status: SUCCESS')).Count
        $failedCount = ([regex]::Matches($progressContent, 'Status: FAILED')).Count
        $blockedCount = ([regex]::Matches($progressContent, 'Status: BLOCKED')).Count

        Write-Output ""
        Write-Output "Progress Summary:"
        Write-Output "  Completed: $successCount"
        Write-Output "  Failed: $failedCount"
        Write-Output "  Blocked: $blockedCount"
    }

    Write-Output ""
    Write-Output $resumePromptText

    # Display completion promise requirements if set
    if ($resumePromise -ne "null" -and $resumePromise) {
        Write-Output @"

===============================================================
CRITICAL - Ralph Loop Completion Promise
===============================================================

To complete this loop, output this EXACT text:
  <promise>$resumePromise</promise>
===============================================================
"@
    }

    exit 0
}

# Validate prompt is non-empty (for new loops)
if ([string]::IsNullOrWhiteSpace($Prompt)) {
    Write-Host "Error: No prompt provided" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Ralph needs a task description to work on."
    Write-Host ""
    Write-Host "   Examples:"
    Write-Host "     /${PluginName}:ralph-loop Build a REST API for todos"
    Write-Host "     /${PluginName}:ralph-loop Fix the auth bug -MaxIterations 20"
    Write-Host "     /${PluginName}:ralph-loop -CompletionPromise 'DONE' Refactor code"
    Write-Host ""
    Write-Host "   For all options: /${PluginName}:ralph-loop -Help"
    exit 1
}

# Create .claude directory if it doesn't exist
$claudeDir = ".claude"
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

# Quote completion promise for YAML if it contains special chars or is not null
if ($CompletionPromise -and $CompletionPromise -ne "null") {
    $completionPromiseYaml = "`"$CompletionPromise`""
} else {
    $completionPromiseYaml = "null"
}

# Prepare isolation mode YAML value
$isolationModeYaml = if ($FreshContext) { "true" } else { "false" }

# Get current UTC timestamp
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Create state file for stop hook (markdown with YAML frontmatter)
$stateFilePath = ".claude/${PluginName}:ralph-loop.local.md"
$stateContent = @"
---
active: true
iteration: 1
max_iterations: $MaxIterations
max_retries: $MaxRetries
completion_promise: $completionPromiseYaml
isolation_mode: $isolationModeYaml
started_at: "$timestamp"
continue_next: false
current_task: null
task_retries: {}
---

$Prompt
"@

Set-Content -Path $stateFilePath -Value $stateContent -NoNewline

# Initialize progress file (new loop or fresh start - skip if resuming)
if (-not $Resume) {
    $modeDisplay = if ($FreshContext) { "fresh-context" } else { "in-session" }
    $progressContent = @"
# Ralph Loop Progress Log

## Session Info
- Source: $Prompt
- Started: $timestamp
- Mode: $modeDisplay
- Max Iterations: $MaxIterations
- Max Retries: $MaxRetries
- Completion Promise: $CompletionPromise

## Iterations

"@
    Set-Content -Path ".claude/ralph-progress.md" -Value $progressContent
}

# Output setup message
$maxIterDisplay = if ($MaxIterations -gt 0) { $MaxIterations } else { "unlimited" }
$maxRetriesDisplay = if ($MaxRetries -gt 0) { "$MaxRetries per task" } else { "disabled" }
$promiseDisplay = if ($CompletionPromise -ne "null") { "$CompletionPromise (ONLY output when TRUE - do not lie!)" } else { "none (runs forever)" }
$isolationDisplay = if ($FreshContext) { "ENABLED (fresh context per iteration)" } else { "disabled (in-session)" }

Write-Output @"
Ralph loop activated in this session!

Iteration: 1
Max iterations: $maxIterDisplay
Max retries: $maxRetriesDisplay
Completion promise: $promiseDisplay
Isolation mode: $isolationDisplay

The stop hook is now active. When you try to exit, the SAME PROMPT will be
fed back to you. You'll see your previous work in files, creating a
self-referential loop where you iteratively improve on the same task.

To monitor: Get-Content .claude/${PluginName}:ralph-loop.local.md -TotalCount 10

WARNING: This loop cannot be stopped manually! It will run infinitely
    unless you set -MaxIterations or -CompletionPromise.

"@

# Output the initial prompt if provided
if ($Prompt) {
    Write-Output ""
    Write-Output $Prompt
}

# Display completion promise requirements if set
if ($CompletionPromise -ne "null") {
    Write-Output @"

===============================================================
CRITICAL - Ralph Loop Completion Promise
===============================================================

To complete this loop, output this EXACT text:
  <promise>$CompletionPromise</promise>

STRICT REQUIREMENTS (DO NOT VIOLATE):
  - Use <promise> XML tags EXACTLY as shown above
  - The statement MUST be completely and unequivocally TRUE
  - Do NOT output false statements to exit the loop
  - Do NOT lie even if you think you should exit

IMPORTANT - Do not circumvent the loop:
  Even if you believe you're stuck, the task is impossible,
  or you've been running too long - you MUST NOT output a
  false promise statement. The loop is designed to continue
  until the promise is GENUINELY TRUE. Trust the process.

  If the loop should stop, the promise statement will become
  true naturally. Do not force it by lying.
===============================================================
"@
}

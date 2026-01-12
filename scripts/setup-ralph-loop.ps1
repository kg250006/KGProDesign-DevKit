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

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words without quotes)

OPTIONS:
  -MaxIterations <n>           Maximum iterations before auto-stop (default: 20)
  -CompletionPromise '<text>'  Promise phrase (USE QUOTES for multi-word)
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

EXAMPLES:
  /${PluginName}:ralph-loop Build a todo API -CompletionPromise 'DONE' -MaxIterations 20
  /${PluginName}:ralph-loop -MaxIterations 10 Fix the auth bug
  /${PluginName}:ralph-loop Refactor cache layer  (runs forever)
  /${PluginName}:ralph-loop -CompletionPromise 'TASK COMPLETE' Create a REST API

STOPPING:
  Only by reaching -MaxIterations or detecting -CompletionPromise
  No manual stop - Ralph runs infinitely by default!

MONITORING:
  # View current iteration:
  Select-String '^iteration:' .claude/${PluginName}:ralph-loop.local.md

  # View full state:
  Get-Content .claude/${PluginName}:ralph-loop.local.md -TotalCount 10
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

    # Remaining content is the prompt (trim leading/trailing whitespace but preserve internal newlines)
    $Prompt = $stdinContent.Trim()
} else {
    # Join all prompt parts with spaces
    if ($PromptParts -and $PromptParts.Count -gt 0) {
        $Prompt = $PromptParts -join ' '
    }
}

# Validate prompt is non-empty
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

# Get current UTC timestamp
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Create state file for stop hook (markdown with YAML frontmatter)
$stateFilePath = ".claude/${PluginName}:ralph-loop.local.md"
$stateContent = @"
---
active: true
iteration: 1
max_iterations: $MaxIterations
completion_promise: $completionPromiseYaml
started_at: "$timestamp"
---

$Prompt
"@

Set-Content -Path $stateFilePath -Value $stateContent -NoNewline

# Output setup message
$maxIterDisplay = if ($MaxIterations -gt 0) { $MaxIterations } else { "unlimited" }
$promiseDisplay = if ($CompletionPromise -ne "null") { "$CompletionPromise (ONLY output when TRUE - do not lie!)" } else { "none (runs forever)" }

Write-Output @"
Ralph loop activated in this session!

Iteration: 1
Max iterations: $maxIterDisplay
Completion promise: $promiseDisplay

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

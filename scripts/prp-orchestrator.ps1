#Requires -Version 5.1
<#
.SYNOPSIS
    PRP Isolated Orchestrator - Execute PRPs with hard session boundaries
.DESCRIPTION
    Executes each PRP task in a completely separate Claude session.
    Windows equivalent of prp-orchestrator.sh with exact feature parity.
    Claude sees ONLY the current task - never the full PRP.
#>

param(
    [Parameter(Position=0)]
    [string]$PrpFile,

    [Alias("max-retries")]
    [int]$MaxRetries = 3,

    [int]$Timeout = 300,

    [int]$Iterations = 2,

    [Alias("dry-run")]
    [switch]$DryRun,

    [Alias("no-safety")]
    [switch]$NoSafety,

    [Alias("skip-validation")]
    [switch]$SkipValidation,

    [Alias("h")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot = Split-Path -Parent $ScriptDir
$TaskTemplate = Join-Path $PluginRoot "templates\current-task.md.template"

# Safety configuration
$BlockedTools = "WebFetch,WebSearch,KillShell,Task,NotebookEdit"

# Check pre-requisites for isolated execution and resolve paths
# Returns hashtable with resolved executable paths
function Test-Prerequisites {
    $missing = @()
    $paths = @{}

    # Node.js is required for task extraction
    $nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue
    if (-not $nodeCmd) {
        $missing += "node (required for PRP parsing)"
    } else {
        $paths.Node = $nodeCmd.Source
    }

    # Claude CLI must be installed
    # IMPORTANT: On Windows, npm creates three wrappers: claude (POSIX), claude.cmd (CMD), claude.ps1 (PowerShell)
    # We MUST use claude.cmd because System.Diagnostics.Process with UseShellExecute=$false
    # cannot execute POSIX shell scripts directly
    $claudeCmd = Get-Command "claude.cmd" -ErrorAction SilentlyContinue
    if (-not $claudeCmd) {
        # Fallback to 'claude' for non-Windows or if .cmd doesn't exist
        $claudeCmd = Get-Command "claude" -ErrorAction SilentlyContinue
    }
    if (-not $claudeCmd) {
        $missing += "claude (Claude CLI must be installed)"
    } else {
        $paths.Claude = $claudeCmd.Source
    }

    if ($missing.Count -gt 0) {
        Write-Host "Error: Missing pre-requisites for isolated PRP execution:" -ForegroundColor Red
        foreach ($item in $missing) {
            Write-Host "  - $item" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Install missing dependencies and try again." -ForegroundColor Red
        exit 1
    }

    return $paths
}

# Run pre-requisite check and get resolved paths
$ResolvedPaths = Test-Prerequisites
$ClaudePath = $ResolvedPaths.Claude

# Show help
if ($Help -or [string]::IsNullOrWhiteSpace($PrpFile)) {
    $helpText = @"
PRP Isolated Orchestrator - Execute PRPs with hard session boundaries

USAGE:
  .\prp-orchestrator.ps1 <prp-file.md> [OPTIONS]

ARGUMENTS:
  prp-file.md    Path to PRP file with XML task structure

OPTIONS:
  -MaxRetries N     Max retry attempts per task (default: 3)
  -Timeout M        Timeout in seconds per task (default: 300)
  -Iterations N     Min successful iterations per task (default: 2)
  -DryRun           Test mode - echo commands instead of running Claude
  -NoSafety         Disable safety mode (use standard permissions)
  -SkipValidation   Skip acceptance criteria validation
  -Help, -h         Show this help message

DESCRIPTION:
  Executes each PRP task in a completely separate Claude session.
  Claude sees ONLY the current task - never the full PRP.

  This enforces hard session isolation at the process level.
  Claude cannot "optimize" by combining tasks.

EXAMPLE:
  .\prp-orchestrator.ps1 PRPs\my-feature.md
  .\prp-orchestrator.ps1 PRPs\my-feature.md -MaxRetries 5 -Timeout 600

OUTPUT:
  Progress logged to: .claude\prp-progress.md
  Current task file: .claude\current-task.md
"@
    Write-Output $helpText
    exit 0
}

# Validate PRP file
if (-not (Test-Path $PrpFile)) {
    Write-Host "Error: PRP file not found: $PrpFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage: .\prp-orchestrator.ps1 <prp-file.md> [OPTIONS]"
    Write-Host "Run with -Help for more information."
    exit 1
}

# Create .claude directory
$claudeDir = ".claude"
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

# File paths
$TaskFile = ".claude\current-task.md"
$ProgressFile = ".claude\prp-progress.md"

# Extract tasks using Node.js
Write-Host "Extracting tasks from PRP..."
$TasksJson = & node "$ScriptDir\prp-to-tasks.js" $PrpFile | Out-String
$TasksData = $TasksJson | ConvertFrom-Json

$Total = $TasksData.total
$PrpName = $TasksData.name
$PrpGoal = $TasksData.goal

# Initialize progress file
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
@"
# PRP Execution Progress (Isolated Mode)

## Session Info
- PRP: $PrpFile
- Name: $PrpName
- Started: $Timestamp
- Total Tasks: $Total
- Max Retries: $MaxRetries
- Timeout: ${Timeout}s
- Min Iterations: $Iterations

## Task Log

"@ | Set-Content -Path $ProgressFile

# Banner
Write-Host ""
Write-Host "=========================================="
Write-Host "  PRP ISOLATED EXECUTION"
Write-Host "=========================================="
Write-Host "PRP File: $PrpFile"
Write-Host "PRP Name: $PrpName"
Write-Host "Total Tasks: $Total"
Write-Host "Max Retries: $MaxRetries"
Write-Host "Timeout: ${Timeout}s per task"
Write-Host "Iterations: $Iterations (per task)"
Write-Host "Progress: $ProgressFile"
if ($DryRun) {
    Write-Host "Mode: DRY RUN (no Claude sessions)"
}
Write-Host "=========================================="
Write-Host ""

# Stats
$Succeeded = 0
$Failed = 0
$Script:TotalIterations = 0

# Main loop
for ($i = 0; $i -lt $Total; $i++) {
    $TaskNum = $i + 1
    $Task = $TasksData.tasks[$i]

    # Determine effective timeout for this task
    # Extended timeout (600s) for test/build tasks, otherwise use command-line default
    $TaskTimeoutHint = if ($Task.timeout) { $Task.timeout } else { "default" }
    if ($TaskTimeoutHint -eq "extended") {
        $EffectiveTimeout = 600
    } else {
        $EffectiveTimeout = $Timeout
    }

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "TASK $TaskNum / $Total : $($Task.id)"
    Write-Host "Agent: $($Task.agent)"
    Write-Host "Description: $($Task.description)"
    if ($TaskTimeoutHint -eq "extended") {
        Write-Host "Note: Using extended timeout (600s) for this task" -ForegroundColor Cyan
    }
    Write-Host "=========================================="

    # Write task file using template or fallback
    if (Test-Path $TaskTemplate) {
        # Render template with variable substitution
        $TemplateContent = Get-Content -Path $TaskTemplate -Raw
        $TaskContent = $TemplateContent `
            -replace '{{TASK_ID}}', $Task.id `
            -replace '{{TASK_DESC}}', $Task.description `
            -replace '{{TASK_FILES}}', $Task.files `
            -replace '{{TASK_PSEUDO}}', $Task.pseudocode `
            -replace '{{TASK_CRITERIA}}', $Task.acceptance_criteria `
            -replace '{{TASK_AGENT}}', $Task.agent `
            -replace '{{PRP_NAME}}', $PrpName `
            -replace '{{PRP_FILE}}', $PrpFile
        $TaskContent | Set-Content -Path $TaskFile -NoNewline
    } else {
        # Fallback: inline template
        @"
# Current Task: $($Task.id)

You are executing a single task from a PRP. Focus ONLY on this task.

## Task Description
$($Task.description)

## Files to Modify
$($Task.files)

## Implementation Guide
``````
$($Task.pseudocode)
``````

## Acceptance Criteria
$($Task.acceptance_criteria)

## Instructions
1. Complete this task fully
2. Validate your work
3. Exit when done

## CRITICAL CONSTRAINTS
- DO NOT read the full PRP file
- DO NOT ask about other tasks
- DO NOT try to optimize by combining tasks
- Focus ONLY on this single task
"@ | Set-Content -Path $TaskFile
    }

    # Create truncated task title for progress log readability
    $TaskTitle = $Task.description
    if ($TaskTitle.Length -gt 80) {
        $TaskTitle = $TaskTitle.Substring(0, 80) + "..."
    }

    # Track iterations for this task
    $IterationsCompleted = 0
    $TaskFullyComplete = $false

    # Outer loop: Success iterations (Ralph Loop philosophy)
    # Each task must complete $Iterations successful runs before moving on
    while ($IterationsCompleted -lt $Iterations -and -not $TaskFullyComplete) {
        $CurrentIteration = $IterationsCompleted + 1
        Write-Host "Iteration $CurrentIteration of $Iterations..."

        # Log iteration start
        Add-Content -Path $ProgressFile -Value "### Task $($Task.id): $TaskTitle"
        $IterTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        Add-Content -Path $ProgressFile -Value "#### Iteration $CurrentIteration - $IterTimestamp"

        # Reset retry counter for this iteration (fresh start)
        $Retries = 0
        $IterationSuccess = $false

        # Inner loop: Retry on failure (existing logic)
        while ($Retries -lt $MaxRetries -and -not $IterationSuccess) {
            $Attempt = $Retries + 1
            Write-Host "  Attempt $Attempt of $MaxRetries..."

            # Log attempt start
            $AttemptTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            Add-Content -Path $ProgressFile -Value "  Attempt $Attempt - $AttemptTimestamp"

            try {
                if ($DryRun) {
                    # Dry run mode - simulate success
                    Write-Host "[DRY RUN] Would execute: claude -p `"Read .claude/current-task.md and execute task $($Task.id)`""
                    Write-Host "[DRY RUN] Task file contents:"
                    Get-Content -Path $TaskFile -TotalCount 10 | ForEach-Object { Write-Host "    $_" }
                    Write-Host "    ..."
                    Start-Sleep -Milliseconds 500
                    $IterationSuccess = $true
                    $IterationsCompleted++
                    $Script:TotalIterations++
                    Add-Content -Path $ProgressFile -Value "  Status: SUCCESS (dry-run, iteration $CurrentIteration)"
                    Write-Host "  Iteration $CurrentIteration`: SUCCESS (dry-run)"
                } else {
                    # Spawn Claude with timeout using Start-Process
                    # CRITICAL: Use --dangerously-skip-permissions to prevent interactive prompts that cause hangs
                    # Safety is enforced via --disallowedTools instead
                    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                    # Use resolved full path - UseShellExecute=$false doesn't search PATH
                    $pinfo.FileName = $ClaudePath

                    $ClaudePrompt = "Read .claude/current-task.md and execute the task described. When complete, simply exit."
                    if ($NoSafety) {
                        # User explicitly disabled safety - use standard permissions
                        $pinfo.Arguments = "-p `"$ClaudePrompt`""
                    } else {
                        # Default: skip permissions but block dangerous tools
                        $pinfo.Arguments = "--dangerously-skip-permissions --disallowedTools $BlockedTools -p `"$ClaudePrompt`""
                    }

                    $pinfo.RedirectStandardOutput = $true
                    $pinfo.RedirectStandardError = $true
                    $pinfo.UseShellExecute = $false
                    $pinfo.CreateNoWindow = $true

                    $process = New-Object System.Diagnostics.Process
                    $process.StartInfo = $pinfo
                    $process.Start() | Out-Null

                    # Use EffectiveTimeout which may be extended for test/build tasks
                    $completed = $process.WaitForExit($EffectiveTimeout * 1000)

                    if (-not $completed) {
                        $process.Kill()
                        throw "Timeout after $EffectiveTimeout seconds"
                    }

                    if ($process.ExitCode -eq 0) {
                        $IterationSuccess = $true
                        $IterationsCompleted++
                        $Script:TotalIterations++
                        Add-Content -Path $ProgressFile -Value "  Status: SUCCESS (iteration $CurrentIteration)"
                        Write-Host "  Iteration $CurrentIteration`: SUCCESS" -ForegroundColor Green
                    } else {
                        throw "Exit code: $($process.ExitCode)"
                    }
                }
            } catch {
                $Retries++
                Add-Content -Path $ProgressFile -Value "  Status: FAILED ($_)"
                Write-Host "  Iteration $CurrentIteration, attempt $Attempt`: FAILED ($_)" -ForegroundColor Yellow

                if ($Retries -lt $MaxRetries) {
                    Write-Host "  Retrying in 2 seconds..."
                    Start-Sleep -Seconds 2
                }
            }
        }

        # If this iteration exhausted retries without success, mark task as failed
        if (-not $IterationSuccess) {
            Add-Content -Path $ProgressFile -Value "  Iteration $CurrentIteration`: FAILED after $MaxRetries attempts"
            Write-Host "  Iteration $CurrentIteration`: FAILED after $MaxRetries attempts" -ForegroundColor Red
            $TaskFullyComplete = $true  # Exit iteration loop
            $Failed++
        }

        # Brief pause between iterations (if more iterations needed)
        if ($IterationsCompleted -lt $Iterations -and $IterationSuccess) {
            Write-Host "  Pausing before next iteration..."
            Start-Sleep -Seconds 1
        }
    }

    # Only count as succeeded if ALL iterations completed
    if ($IterationsCompleted -eq $Iterations) {
        $Succeeded++
        Write-Host "Task $($Task.id): FULLY COMPLETE ($Iterations iterations)" -ForegroundColor Green
        Add-Content -Path $ProgressFile -Value "Task Status: FULLY COMPLETE ($Iterations/$Iterations iterations)"
    }

    Add-Content -Path $ProgressFile -Value ""

    # Cleanup: Clear current task file between tasks
    if (Test-Path $TaskFile) {
        Remove-Item -Path $TaskFile -Force
    }

    Start-Sleep -Seconds 1
}

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "  EXECUTION COMPLETE"
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Total Tasks: $Total"
Write-Host "Succeeded (all iterations): $Succeeded" -ForegroundColor Green
Write-Host "Failed: $Failed" -ForegroundColor $(if ($Failed -gt 0) { "Red" } else { "Green" })
Write-Host "Total Iterations Run: $Script:TotalIterations"
Write-Host "Target Iterations/Task: $Iterations"
Write-Host "==========================================" -ForegroundColor Blue

# Append summary to progress file
$CompletedTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
@"

## Summary
- Completed: $CompletedTimestamp
- Tasks Succeeded: $Succeeded / $Total
- Tasks Failed: $Failed
- Total Iterations: $Script:TotalIterations
- Target Iterations/Task: $Iterations
"@ | Add-Content -Path $ProgressFile

# Final cleanup: Remove task file if it exists
if (Test-Path $TaskFile) {
    Remove-Item -Path $TaskFile -Force
    Write-Host "Cleaned up: $TaskFile"
}

# Exit code
if ($Failed -gt 0) {
    exit 1
} else {
    exit 0
}

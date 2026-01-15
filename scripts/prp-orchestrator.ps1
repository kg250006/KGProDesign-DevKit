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

    [Alias("h")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot = Split-Path -Parent $ScriptDir
$TaskTemplate = Join-Path $PluginRoot "templates\current-task.md.template"

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
Write-Host "Progress: $ProgressFile"
Write-Host "=========================================="
Write-Host ""

# Stats
$Succeeded = 0
$Failed = 0

# Main loop
for ($i = 0; $i -lt $Total; $i++) {
    $TaskNum = $i + 1
    $Task = $TasksData.tasks[$i]

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "TASK $TaskNum / $Total : $($Task.id)"
    Write-Host "Agent: $($Task.agent)"
    Write-Host "Description: $($Task.description)"
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

    # Retry loop
    $Retries = 0
    $Success = $false

    while ($Retries -lt $MaxRetries -and -not $Success) {
        $Attempt = $Retries + 1
        Write-Host "Attempt $Attempt of $MaxRetries..."

        $AttemptTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        Add-Content -Path $ProgressFile -Value "### Task $($Task.id) - Attempt $Attempt - $AttemptTimestamp"

        try {
            # Spawn Claude with timeout using Start-Process
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "claude"
            $pinfo.Arguments = "-p `"Read .claude/current-task.md and execute the task described. When complete, simply exit.`""
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $pinfo
            $process.Start() | Out-Null

            $completed = $process.WaitForExit($Timeout * 1000)

            if (-not $completed) {
                $process.Kill()
                throw "Timeout after $Timeout seconds"
            }

            if ($process.ExitCode -eq 0) {
                $Success = $true
                $Succeeded++
                Add-Content -Path $ProgressFile -Value "Status: SUCCESS"
                Write-Host "Task $($Task.id): SUCCESS" -ForegroundColor Green
            } else {
                throw "Exit code: $($process.ExitCode)"
            }
        } catch {
            $Retries++
            Add-Content -Path $ProgressFile -Value "Status: FAILED ($_)"
            Write-Host "Task $($Task.id): FAILED (attempt $Attempt)" -ForegroundColor Yellow

            if ($Retries -lt $MaxRetries) {
                Write-Host "Retrying in 2 seconds..."
                Start-Sleep -Seconds 2
            }
        }
    }

    if (-not $Success) {
        $Failed++
        Add-Content -Path $ProgressFile -Value "Status: FAILED PERMANENTLY after $MaxRetries attempts"
        Write-Host "Task $($Task.id): FAILED permanently - continuing to next task" -ForegroundColor Red
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
Write-Host "=========================================="
Write-Host "  EXECUTION COMPLETE"
Write-Host "=========================================="
Write-Host "Total: $Total"
Write-Host "Succeeded: $Succeeded"
Write-Host "Failed: $Failed"
Write-Host "=========================================="

# Append summary to progress file
$CompletedTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
@"

## Summary
- Completed: $CompletedTimestamp
- Succeeded: $Succeeded / $Total
- Failed: $Failed
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

#Requires -Version 5.1
<#
.SYNOPSIS
    Ralph Auto - Automatic respawn wrapper for Ralph Loop with fresh-context mode
.DESCRIPTION
    This script wraps the claude CLI and automatically restarts sessions
    when the Ralph loop's continue_next flag is set to true.
#>

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"

Write-Host "Ralph Auto: Starting session..."
Write-Host ""

# Run the initial claude session with any provided arguments
if ($Arguments -and $Arguments.Count -gt 0) {
    & claude $Arguments
} else {
    & claude
}

# Check for continuation flag in state file
# Get plugin name for state file path
$pluginRoot = $env:CLAUDE_PLUGIN_ROOT
if (-not $pluginRoot) {
    $pluginRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$pluginJson = Join-Path $pluginRoot ".claude-plugin" "plugin.json"
$pluginName = "KGP"
if (Test-Path $pluginJson) {
    try {
        $config = Get-Content $pluginJson -Raw | ConvertFrom-Json
        if ($config.name) {
            $pluginName = $config.name
        }
    } catch {
        # Fall through to default
    }
}

$stateFile = ".claude/${pluginName}:ralph-loop.local.md"

while (Test-Path $stateFile) {
    $stateContent = Get-Content $stateFile -Raw

    $continueNext = "false"
    $active = "false"
    $iteration = "?"

    if ($stateContent -match '(?m)^continue_next:\s*(\w+)') { $continueNext = $Matches[1] }
    if ($stateContent -match '(?m)^active:\s*(\w+)') { $active = $Matches[1] }
    if ($stateContent -match '(?m)^iteration:\s*(\d+)') { $iteration = $Matches[1] }

    if ($continueNext -eq "true" -and $active -eq "true") {
        Write-Host ""
        Write-Host "==============================================================="
        Write-Host "Ralph Auto: Fresh context restart detected (iteration $iteration)"
        Write-Host "==============================================================="
        Write-Host ""
        Write-Host "Waiting 2 seconds before restarting..."
        Start-Sleep -Seconds 2

        # Reset continue_next flag before starting new session
        $stateContent = $stateContent -replace '(?m)^continue_next:\s*true', 'continue_next: false'
        Set-Content -Path $stateFile -Value $stateContent -NoNewline

        Write-Host "Starting fresh Claude session..."
        Write-Host ""

        # Start new Claude session - SessionStart hook will auto-inject --resume
        & claude
    } else {
        break
    }
}

Write-Host ""
Write-Host "Ralph Auto: Loop complete."
Write-Host ""

# Show final status if progress file exists
$progressFile = ".claude/ralph-progress.md"
if (Test-Path $progressFile) {
    $progressContent = Get-Content $progressFile -Raw
    $successCount = ([regex]::Matches($progressContent, 'Status: SUCCESS')).Count
    $failedCount = ([regex]::Matches($progressContent, 'Status: FAILED')).Count
    $blockedCount = ([regex]::Matches($progressContent, 'Status: BLOCKED')).Count

    Write-Host "Final Progress Summary:"
    Write-Host "  Completed: $successCount"
    Write-Host "  Failed: $failedCount"
    Write-Host "  Blocked: $blockedCount"
    Write-Host ""
    Write-Host "Full progress: $progressFile"
}

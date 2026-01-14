#Requires -Version 5.1
<#
.SYNOPSIS
    Ralph Loop SessionStart Hook - PowerShell implementation for Windows
.DESCRIPTION
    Auto-injects --resume command when continuation is detected.
    This hook fires when a new Claude Code session starts.
#>

$ErrorActionPreference = "SilentlyContinue"

# Function to get plugin prefix from plugin.json
function Get-PluginPrefix {
    $pluginRoot = $env:CLAUDE_PLUGIN_ROOT
    if (-not $pluginRoot) {
        $pluginRoot = Split-Path -Parent $PSScriptRoot
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

$pluginName = Get-PluginPrefix
$stateFile = ".claude/${pluginName}:ralph-loop.local.md"

# Check if Ralph loop state exists and needs continuation
if (-not (Test-Path $stateFile)) {
    # No active loop - nothing to do
    exit 0
}

# Read state file
$stateContent = Get-Content $stateFile -Raw -ErrorAction SilentlyContinue

if (-not $stateContent) {
    exit 0
}

# Extract values from frontmatter
$continueNext = "false"
$active = "false"
$iteration = "1"

if ($stateContent -match '(?m)^continue_next:\s*(\w+)') { $continueNext = $Matches[1] }
if ($stateContent -match '(?m)^active:\s*(\w+)') { $active = $Matches[1] }
if ($stateContent -match '(?m)^iteration:\s*(\d+)') { $iteration = $Matches[1] }

# Check if continuation is needed
if ($continueNext -eq "true" -and $active -eq "true") {
    # Reset continue_next marker to prevent infinite detection
    $stateContent = $stateContent -replace '(?m)^continue_next:\s*true', 'continue_next: false'
    Set-Content -Path $stateFile -Value $stateContent -NoNewline -ErrorAction SilentlyContinue

    # Output hook response to inject context
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "SessionStart"
            additionalContext = "RALPH LOOP CONTINUATION DETECTED (iteration $iteration). Execute: /${pluginName}:ralph-loop --resume"
        }
    }

    $jsonOutput = $output | ConvertTo-Json -Depth 10 -Compress
    Write-Output $jsonOutput
}

exit 0

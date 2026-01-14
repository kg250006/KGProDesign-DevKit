#Requires -Version 5.1
<#
.SYNOPSIS
    Ralph Loop Stop Hook - PowerShell implementation for Windows
.DESCRIPTION
    Prevents session exit when a ralph-loop is active.
    Feeds Claude's output back as input to continue the loop.

    This is the Windows equivalent of stop-hook.sh with exact feature parity.
#>

$ErrorActionPreference = "SilentlyContinue"

# Read hook input from stdin (advanced stop hook API)
$hookInput = $null
$hookInputRaw = ""
try {
    $hookInputRaw = [Console]::In.ReadToEnd()
    if ($hookInputRaw) {
        $hookInput = $hookInputRaw | ConvertFrom-Json
    }
} catch {
    # If no input or invalid JSON, continue with null
}

# Function to get plugin prefix from plugin.json (dynamic discovery)
function Get-PluginPrefix {
    $pluginRoot = $env:CLAUDE_PLUGIN_ROOT
    if (-not $pluginRoot) {
        # Fallback: derive from script location (hooks -> plugin root)
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

# Get plugin name dynamically
$pluginName = Get-PluginPrefix

# Check if ralph-loop is active
$ralphStateFile = ".claude/${pluginName}:ralph-loop.local.md"

if (-not (Test-Path $ralphStateFile)) {
    # No active loop - allow exit
    exit 0
}

# Read state file content
$stateContent = Get-Content $ralphStateFile -Raw -ErrorAction Stop

# Parse markdown frontmatter (YAML between --- markers)
# Match content between first and second ---
if ($stateContent -notmatch '(?s)^---\r?\n(.*?)\r?\n---') {
    Write-Host "Warning: Ralph loop: State file has invalid format" -ForegroundColor Yellow
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

$frontmatter = $Matches[1]

# Extract values from frontmatter using regex
function Get-FrontmatterValue {
    param([string]$Content, [string]$Key)
    if ($Content -match "(?m)^${Key}:\s*(.+)$") {
        $value = $Matches[1].Trim()
        # Strip surrounding quotes if present
        if ($value -match '^"(.*)"$') {
            return $Matches[1]
        }
        return $value
    }
    return $null
}

$iteration = Get-FrontmatterValue -Content $frontmatter -Key "iteration"
$maxIterations = Get-FrontmatterValue -Content $frontmatter -Key "max_iterations"
$completionPromise = Get-FrontmatterValue -Content $frontmatter -Key "completion_promise"

# Validate iteration is numeric
if ($iteration -notmatch '^\d+$') {
    Write-Host "Warning: Ralph loop: State file corrupted" -ForegroundColor Yellow
    Write-Host "   File: $ralphStateFile"
    Write-Host "   Problem: 'iteration' field is not a valid number (got: '$iteration')"
    Write-Host ""
    Write-Host "   This usually means the state file was manually edited or corrupted."
    Write-Host "   Ralph loop is stopping. Run /${pluginName}:ralph-loop again to start fresh."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Validate max_iterations is numeric
if ($maxIterations -notmatch '^\d+$') {
    Write-Host "Warning: Ralph loop: State file corrupted" -ForegroundColor Yellow
    Write-Host "   File: $ralphStateFile"
    Write-Host "   Problem: 'max_iterations' field is not a valid number (got: '$maxIterations')"
    Write-Host ""
    Write-Host "   This usually means the state file was manually edited or corrupted."
    Write-Host "   Ralph loop is stopping. Run /${pluginName}:ralph-loop again to start fresh."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

$iterationNum = [int]$iteration
$maxIterationsNum = [int]$maxIterations

# Check if max iterations reached
if ($maxIterationsNum -gt 0 -and $iterationNum -ge $maxIterationsNum) {
    Write-Host "Ralph loop: Max iterations ($maxIterations) reached."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Get transcript path from hook input
$transcriptPath = $null
if ($hookInput -and $hookInput.transcript_path) {
    $transcriptPath = $hookInput.transcript_path
}

if (-not $transcriptPath -or -not (Test-Path $transcriptPath)) {
    Write-Host "Warning: Ralph loop: Transcript file not found" -ForegroundColor Yellow
    Write-Host "   Expected: $transcriptPath"
    Write-Host "   This is unusual and may indicate a Claude Code internal issue."
    Write-Host "   Ralph loop is stopping."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Read transcript and find assistant messages (JSONL format - one JSON per line)
$transcriptLines = Get-Content $transcriptPath -ErrorAction Stop

# Filter lines containing assistant role
$assistantLines = $transcriptLines | Where-Object { $_ -match '"role"\s*:\s*"assistant"' }

if (-not $assistantLines -or @($assistantLines).Count -eq 0) {
    Write-Host "Warning: Ralph loop: No assistant messages found in transcript" -ForegroundColor Yellow
    Write-Host "   Transcript: $transcriptPath"
    Write-Host "   This is unusual and may indicate a transcript format issue"
    Write-Host "   Ralph loop is stopping."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Get last assistant message line
$lastLine = @($assistantLines) | Select-Object -Last 1

if (-not $lastLine) {
    Write-Host "Warning: Ralph loop: Failed to extract last assistant message" -ForegroundColor Yellow
    Write-Host "   Ralph loop is stopping."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Parse JSON and extract text content
$lastOutput = ""
try {
    $lastMessage = $lastLine | ConvertFrom-Json

    # Extract text from message.content array where type == "text"
    $textParts = @()
    foreach ($contentItem in $lastMessage.message.content) {
        if ($contentItem.type -eq "text" -and $contentItem.text) {
            $textParts += $contentItem.text
        }
    }
    $lastOutput = $textParts -join "`n"
} catch {
    Write-Host "Warning: Ralph loop: Failed to parse assistant message JSON" -ForegroundColor Yellow
    Write-Host "   Error: $_"
    Write-Host "   This may indicate a transcript format issue"
    Write-Host "   Ralph loop is stopping."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

if ([string]::IsNullOrWhiteSpace($lastOutput)) {
    Write-Host "Warning: Ralph loop: Assistant message contained no text content" -ForegroundColor Yellow
    Write-Host "   Ralph loop is stopping."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Extract additional fields from frontmatter for progress tracking
$maxRetries = Get-FrontmatterValue -Content $frontmatter -Key "max_retries"
$isolationMode = Get-FrontmatterValue -Content $frontmatter -Key "isolation_mode"
if (-not $maxRetries -or $maxRetries -notmatch '^\d+$') { $maxRetries = "0" }
if (-not $isolationMode) { $isolationMode = "false" }
$maxRetriesNum = [int]$maxRetries

# Detect task status from output
$taskStatus = "IN_PROGRESS"
$taskNotes = ""

if ($lastOutput -match 'completed|success|done|finished') {
    $taskStatus = "SUCCESS"
}

if ($lastOutput -match 'error|failed|exception|cannot') {
    $taskStatus = "FAILED"
    # Extract error context (first line mentioning error)
    $errorLine = ($lastOutput -split "`n" | Where-Object { $_ -match 'error|failed|exception' } | Select-Object -First 1)
    if ($errorLine) {
        $taskNotes = $errorLine.Substring(0, [Math]::Min(100, $errorLine.Length))
    }
}

# Retry tracking - track consecutive failures
$consecutiveFailures = Get-FrontmatterValue -Content $frontmatter -Key "consecutive_failures"
if (-not $consecutiveFailures -or $consecutiveFailures -notmatch '^\d+$') { $consecutiveFailures = "0" }
$consecutiveFailuresNum = [int]$consecutiveFailures

if ($taskStatus -eq "FAILED") {
    $consecutiveFailuresNum++

    # Check if max retries exceeded
    if ($maxRetriesNum -gt 0 -and $consecutiveFailuresNum -ge $maxRetriesNum) {
        Write-Host "Ralph loop: Max retries ($maxRetries) reached after consecutive failures"
        $taskStatus = "BLOCKED"
        $consecutiveFailuresNum = 0
    }
} else {
    # Reset consecutive failures on success
    $consecutiveFailuresNum = 0
}

# Update consecutive_failures in state file
if ($stateContent -match 'consecutive_failures:\s*\d+') {
    $stateContent = $stateContent -replace '(?m)^consecutive_failures:\s*\d+', "consecutive_failures: $consecutiveFailuresNum"
} else {
    # Add consecutive_failures field after max_retries if not present
    $stateContent = $stateContent -replace '(?m)^(max_retries:\s*\d+)', "`$1`nconsecutive_failures: $consecutiveFailuresNum"
}

# Update progress file with iteration results
$progressFile = ".claude/ralph-progress.md"
$progressTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

if (Test-Path $progressFile) {
    $progressEntry = @"

### Iteration $iterationNum
- Timestamp: $progressTimestamp
- Status: $taskStatus
"@
    if ($taskNotes) {
        $progressEntry += "`n- Notes: $taskNotes"
    }
    if ($taskStatus -eq "FAILED" -and $maxRetriesNum -gt 0) {
        $progressEntry += "`n- Retries: $consecutiveFailuresNum/$maxRetries"
    }
    $progressEntry += "`n"
    Add-Content -Path $progressFile -Value $progressEntry
}

# Check for completion promise (only if set and not null)
if ($completionPromise -and $completionPromise -ne "null") {
    # Extract text from <promise> tags - non-greedy match for FIRST tag
    if ($lastOutput -match '(?s)<promise>(.*?)</promise>') {
        # Normalize whitespace: trim and collapse multiple spaces
        $promiseText = $Matches[1].Trim() -replace '\s+', ' '

        # Use exact string comparison (not pattern matching)
        if ($promiseText -eq $completionPromise) {
            Write-Host "Ralph loop: Detected <promise>$completionPromise</promise>"
            Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
            exit 0
        }
    }
}

# Not complete - continue loop with SAME PROMPT
$nextIteration = $iterationNum + 1

# Extract prompt (everything after the closing ---)
# Skip first --- line, skip until second --- line, then get everything after
$promptText = ""
if ($stateContent -match '(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$') {
    $promptText = $Matches[1]
}

if ([string]::IsNullOrWhiteSpace($promptText)) {
    Write-Host "Warning: Ralph loop: State file corrupted or incomplete" -ForegroundColor Yellow
    Write-Host "   File: $ralphStateFile"
    Write-Host "   Problem: No prompt text found"
    Write-Host ""
    Write-Host "   This usually means:"
    Write-Host "     - State file was manually edited"
    Write-Host "     - File was corrupted during writing"
    Write-Host ""
    Write-Host "   Ralph loop is stopping. Run /${pluginName}:ralph-loop again to start fresh."
    Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Update iteration in state file (portable atomic update)
$updatedContent = $stateContent -replace '(?m)^iteration:\s*\d+', "iteration: $nextIteration"
$tempFile = "${ralphStateFile}.tmp.$PID"
try {
    Set-Content -Path $tempFile -Value $updatedContent -NoNewline -ErrorAction Stop
    Move-Item -Path $tempFile -Destination $ralphStateFile -Force -ErrorAction Stop
} catch {
    # Fallback: direct write if atomic rename fails
    Set-Content -Path $ralphStateFile -Value $updatedContent -NoNewline -ErrorAction SilentlyContinue
    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
}

# Re-read updated content for isolation mode handling
$stateContent = Get-Content $ralphStateFile -Raw -ErrorAction Stop

# Handle isolation mode (fresh context per iteration)
if ($isolationMode -eq "true") {
    # In isolation mode, we allow the session to exit cleanly
    # Set continue_next: true so wrapper script or SessionStart hook knows to resume
    $stateContent = $stateContent -replace '(?m)^continue_next:\s*false', 'continue_next: true'
    Set-Content -Path $ralphStateFile -Value $stateContent -NoNewline

    Write-Host ""
    Write-Host "==============================================================="
    Write-Host "Ralph Loop - Fresh Context Mode (Iteration $iterationNum complete)"
    Write-Host "==============================================================="
    Write-Host ""
    Write-Host "Session will now exit cleanly for fresh context."
    Write-Host ""
    Write-Host "To continue: /${pluginName}:ralph-loop -Resume"
    Write-Host "   or use ralph-auto.ps1 for automatic continuation"
    Write-Host ""
    Write-Host "Progress: .claude/ralph-progress.md"
    Write-Host "Next iteration: $nextIteration"
    Write-Host "==============================================================="

    # Allow exit - wrapper script will detect continue_next: true and restart
    exit 0
}

# In-session mode: Block exit and continue in same session
# Build system message with iteration count and completion promise info
if ($completionPromise -and $completionPromise -ne "null") {
    $systemMsg = "Ralph iteration $nextIteration | To stop: output <promise>$completionPromise</promise> (ONLY when statement is TRUE - do not lie to exit!)"
} else {
    $systemMsg = "Ralph iteration $nextIteration | No completion promise set - loop runs infinitely"
}

# Output JSON to block the stop and feed prompt back
# The "reason" field contains the prompt that will be sent back to Claude
$output = @{
    decision = "block"
    reason = $promptText
    systemMessage = $systemMsg
}

# Use ConvertTo-Json with proper depth and compression
$jsonOutput = $output | ConvertTo-Json -Depth 10 -Compress
Write-Output $jsonOutput

# Exit 0 for successful hook execution
exit 0

# PRP Safety Hook - PowerShell Version
# PreToolUse hook that blocks dangerous commands in isolated PRP execution
#
# This is the Windows-compatible version of prp-safety-hook.sh
# Called by prp-safety-hook.js when running on Windows

param()

# Read all stdin
$inputData = [Console]::In.ReadToEnd()

# Parse JSON
try {
    $data = $inputData | ConvertFrom-Json
    $toolName = $data.tool_name
    $command = $data.tool_input.command
} catch {
    Write-Output '{"decision": "approve", "reason": "JSON parse error - fail-open"}'
    exit 0
}

# Only check Bash commands
if ($toolName -ne "Bash") {
    Write-Output '{"decision": "approve", "reason": "Non-Bash tool allowed"}'
    exit 0
}

# Empty command - approve
if ([string]::IsNullOrWhiteSpace($command)) {
    Write-Output '{"decision": "approve", "reason": "Empty command"}'
    exit 0
}

# === BLOCKED PATTERNS ===

# Block rm -rf on dangerous paths
if ($command -match 'rm\s+-rf?\s+(/|/usr|/etc|/var|/home|/root|~|\$HOME)') {
    Write-Output '{"decision": "block", "reason": "Destructive rm command on system path blocked"}'
    exit 0
}

# Block kill commands (except node/npm)
if ($command -match '^kill\s' -and $command -notmatch '(node|npm|vite|next|webpack)') {
    Write-Output '{"decision": "block", "reason": "kill command blocked - only node/npm/vite processes allowed"}'
    exit 0
}

# Block pkill/killall
if ($command -match '(pkill|killall)\s') {
    Write-Output '{"decision": "block", "reason": "pkill/killall blocked"}'
    exit 0
}

# Block cd to system directories
if ($command -match '^cd\s+(/usr|/etc|/var|/root|/sys|/proc)') {
    Write-Output '{"decision": "block", "reason": "cd to system directory blocked"}'
    exit 0
}

# Block format/disk commands
if ($command -match '(mkfs|fdisk|parted|dd\s+if=)') {
    Write-Output '{"decision": "block", "reason": "Disk manipulation command blocked"}'
    exit 0
}

# Block sudo
if ($command -match '^sudo\s') {
    Write-Output '{"decision": "block", "reason": "sudo commands blocked in isolated execution"}'
    exit 0
}

# Block force push to main/master
if ($command -match 'git\s+push.*--force' -and $command -match '(main|master)') {
    Write-Output '{"decision": "block", "reason": "Force push to main/master blocked"}'
    exit 0
}

# Block SSH
if ($command -match '^ssh\s') {
    Write-Output '{"decision": "block", "reason": "SSH commands blocked in isolated execution"}'
    exit 0
}

# Block netcat
if ($command -match '(^nc\s|netcat)') {
    Write-Output '{"decision": "block", "reason": "netcat blocked in isolated execution"}'
    exit 0
}

# Block chmod 777
if ($command -match 'chmod\s+777') {
    Write-Output '{"decision": "block", "reason": "chmod 777 blocked - use more restrictive permissions"}'
    exit 0
}

# === DIRECTORY CONTAINMENT ===

# Block cd to system directories with chaining
if ($command -match 'cd\s+(/etc|/usr|/var|/root|/home|/tmp|~|\$HOME)') {
    Write-Output '{"decision": "block", "reason": "cd to system directory blocked - stay within project"}'
    exit 0
}

# Block pushd to system paths
if ($command -match 'pushd\s+(/etc|/usr|/var|/root|/home|/tmp|~|\$HOME)') {
    Write-Output '{"decision": "block", "reason": "pushd to system directory blocked"}'
    exit 0
}

# Block reading sensitive files
if ($command -match '(cat|less|more|head|tail).*/etc/(passwd|shadow|hosts|sudoers)') {
    Write-Output '{"decision": "block", "reason": "Reading sensitive system file blocked"}'
    exit 0
}

# Block reading SSH/AWS keys
if ($command -match '(cat|less|more|head|tail).*(~|\$HOME)/(\.ssh|\.aws)') {
    Write-Output '{"decision": "block", "reason": "Reading sensitive credentials blocked"}'
    exit 0
}

# Block excessive path traversal
if ($command -match '\.\./\.\./\.\./\.\.') {
    Write-Output '{"decision": "block", "reason": "Excessive path traversal blocked"}'
    exit 0
}

# Block cp/mv to system paths
if ($command -match '(cp|mv)\s+.*\s+(/etc/|/usr/|/var/|/tmp/|/root/|~/\.)') {
    Write-Output '{"decision": "block", "reason": "Copy/move to system path blocked"}'
    exit 0
}

# Block symlinks to system paths
if ($command -match 'ln\s.*(/etc|/usr|~/\.|/root)') {
    Write-Output '{"decision": "block", "reason": "Symlink involving system path blocked"}'
    exit 0
}

# Block find from root
if ($command -match 'find\s+(/|/etc|/home|/root|~)\s') {
    Write-Output '{"decision": "block", "reason": "find on system root blocked"}'
    exit 0
}

# === ECHO/PRINTF/REDIRECTION BYPASS PREVENTION ===

# Block echo/printf to system files
if ($command -match '(echo|printf)\s.*>\s*(/etc/|/usr/|/var/|/root/|~/)') {
    Write-Output '{"decision": "block", "reason": "echo/printf to system file blocked"}'
    exit 0
}

# Block pipe to bash/sh/eval
if ($command -match '\|\s*(bash|sh|zsh|eval|source)') {
    Write-Output '{"decision": "block", "reason": "Pipe to shell interpreter blocked"}'
    exit 0
}

# Block base64 decode to execution
if ($command -match 'base64\s+-d.*\|.*(bash|sh|eval)') {
    Write-Output '{"decision": "block", "reason": "base64 decode to shell blocked"}'
    exit 0
}

# Block tee to system paths
if ($command -match 'tee\s.*(/etc/|/usr/|/var/|~/)') {
    Write-Output '{"decision": "block", "reason": "tee to system path blocked"}'
    exit 0
}

# Block eval command
if ($command -match '^eval\s' -or $command -match '[;|]\s*eval\s') {
    Write-Output '{"decision": "block", "reason": "eval command blocked"}'
    exit 0
}

# Block cron manipulation
if ($command -match '(crontab\s+-|/etc/cron)') {
    Write-Output '{"decision": "block", "reason": "Cron manipulation blocked"}'
    exit 0
}

# Block at/batch scheduling
if ($command -match '^(at|batch)\s') {
    Write-Output '{"decision": "block", "reason": "Job scheduling blocked"}'
    exit 0
}

# Block nohup
if ($command -match '^nohup\s') {
    Write-Output '{"decision": "block", "reason": "nohup blocked - background persistence not allowed"}'
    exit 0
}

# Block creating executables in /tmp
if ($command -match '>\s*/tmp/.*\.sh' -or $command -match 'chmod.*\+x.*/tmp/') {
    Write-Output '{"decision": "block", "reason": "Creating executable in /tmp blocked"}'
    exit 0
}

# === APPROVED ===
Write-Output '{"decision": "approve", "reason": "Command passed safety checks"}'

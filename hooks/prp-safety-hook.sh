#!/bin/bash
# PRP Safety Hook - PreToolUse Hook for Isolated PRP Execution
# Blocks dangerous command patterns while allowing normal development operations
#
# This hook is used by prp-execute-isolated to enable --dangerously-skip-permissions
# while still maintaining safety through pattern-based command blocking.
#
# Usage: echo '{"tool_name":"Bash","tool_input":{"command":"..."}}' | ./prp-safety-hook.sh

set -euo pipefail

# Read JSON input from stdin
input=$(cat)

# Extract tool name and command using jq
if ! command -v jq &> /dev/null; then
  # If jq not available, approve by default (fail-open)
  echo '{"decision": "approve", "reason": "jq not available - fail-open"}'
  exit 0
fi

tool_name=$(echo "$input" | jq -r '.tool_name // ""')
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only check Bash commands - approve all other tools
if [[ "$tool_name" != "Bash" ]]; then
  echo '{"decision": "approve", "reason": "Non-Bash tool allowed"}'
  exit 0
fi

# Empty command - approve
if [[ -z "$command" ]]; then
  echo '{"decision": "approve", "reason": "Empty command"}'
  exit 0
fi

# === BLOCKED PATTERNS ===

# Block rm -rf on dangerous paths
if echo "$command" | grep -qE 'rm[[:space:]]+-rf?[[:space:]]+(/|/usr|/etc|/var|/home|/root|~|\$HOME)'; then
  echo '{"decision": "block", "reason": "Destructive rm command on system path blocked"}'
  exit 0
fi

# Block kill commands (except for node/npm processes in development)
if echo "$command" | grep -qE '^kill[[:space:]]'; then
  if ! echo "$command" | grep -qE '(node|npm|vite|next|webpack)'; then
    echo '{"decision": "block", "reason": "kill command blocked - only node/npm/vite processes allowed"}'
    exit 0
  fi
fi

# Block pkill/killall (too broad)
if echo "$command" | grep -qE '(pkill|killall)[[:space:]]'; then
  echo '{"decision": "block", "reason": "pkill/killall blocked - use specific kill instead"}'
  exit 0
fi

# Block cd to system directories as standalone command
if echo "$command" | grep -qE '^cd[[:space:]]+(/usr|/etc|/var|/root|/sys|/proc|/home|/tmp|~|\$HOME)'; then
  echo '{"decision": "block", "reason": "cd to system directory blocked"}'
  exit 0
fi

# Block format/disk commands
if echo "$command" | grep -qE '(mkfs|fdisk|parted|dd[[:space:]]+if=)'; then
  echo '{"decision": "block", "reason": "Disk manipulation command blocked"}'
  exit 0
fi

# Block git force push to main/master
if echo "$command" | grep -qE 'git[[:space:]]+push.*(-f|--force)'; then
  if echo "$command" | grep -qE '(main|master)'; then
    echo '{"decision": "block", "reason": "Force push to main/master blocked"}'
    exit 0
  fi
fi

# Block sudo commands
if echo "$command" | grep -qE '^sudo[[:space:]]'; then
  echo '{"decision": "block", "reason": "sudo commands blocked in isolated execution"}'
  exit 0
fi

# Block curl/wget to non-localhost URLs (prevent data exfiltration)
if echo "$command" | grep -qE '(curl|wget)[[:space:]]'; then
  if ! echo "$command" | grep -qE '(localhost|127\.0\.0\.1|::1)'; then
    # Allow common safe domains
    if ! echo "$command" | grep -qE '(github\.com|npmjs\.org|registry\.npmjs|pypi\.org|api\.github\.com)'; then
      echo '{"decision": "block", "reason": "curl/wget to untrusted URL blocked - use WebFetch tool instead"}'
      exit 0
    fi
  fi
fi

# Block SSH commands (prevent lateral movement)
if echo "$command" | grep -qE '^ssh[[:space:]]'; then
  echo '{"decision": "block", "reason": "SSH commands blocked in isolated execution"}'
  exit 0
fi

# Block netcat/nc (security tool)
if echo "$command" | grep -qE '(^nc[[:space:]]|netcat)'; then
  echo '{"decision": "block", "reason": "netcat blocked in isolated execution"}'
  exit 0
fi

# Block chmod 777 (overly permissive)
if echo "$command" | grep -qE 'chmod[[:space:]]+777'; then
  echo '{"decision": "block", "reason": "chmod 777 blocked - use more restrictive permissions"}'
  exit 0
fi

# Block history manipulation
if echo "$command" | grep -qE '(history[[:space:]]+-c|HISTFILE=|unset[[:space:]]+HIST)'; then
  echo '{"decision": "block", "reason": "History manipulation blocked"}'
  exit 0
fi

# === DIRECTORY CONTAINMENT ===
# Prevent escaping the project directory

# Block pushd/popd to system paths
if echo "$command" | grep -qE 'pushd[[:space:]]+(/etc|/usr|/var|/root|/home|/tmp|~|\$HOME)'; then
  echo '{"decision": "block", "reason": "pushd to system directory blocked"}'
  exit 0
fi

# Block subshell directory escape: (cd /etc && ...)
if echo "$command" | grep -qE '\([[:space:]]*cd[[:space:]]+(/[a-zA-Z]|~)'; then
  echo '{"decision": "block", "reason": "Subshell directory escape blocked"}'
  exit 0
fi

# Block reading sensitive files via absolute paths
if echo "$command" | grep -qE '(cat|less|more|head|tail|vim|nano|vi|view|bat)[[:space:]]+.*/etc/(passwd|shadow|hosts|sudoers)'; then
  echo '{"decision": "block", "reason": "Reading sensitive system file blocked"}'
  exit 0
fi

# Block reading SSH/AWS credentials
if echo "$command" | grep -qE '(cat|less|more|head|tail)[[:space:]]+.*(~/\.ssh|~/\.aws|\$HOME/\.ssh|\$HOME/\.aws)'; then
  echo '{"decision": "block", "reason": "Reading sensitive credentials blocked"}'
  exit 0
fi

# Block path traversal attacks: ../../etc/passwd
if echo "$command" | grep -qE '\.\./\.\./\.\./\.\.'; then
  echo '{"decision": "block", "reason": "Excessive path traversal blocked - possible escape attempt"}'
  exit 0
fi

# Block cp/mv TO system paths (data exfiltration or system modification)
if echo "$command" | grep -qE '(cp|mv)[[:space:]]+.*[[:space:]]+(/etc/|/usr/|/var/|/tmp/|/root/|~/\.)'; then
  echo '{"decision": "block", "reason": "Copy/move to system path blocked"}'
  exit 0
fi

# Block cp/mv FROM sensitive paths (data theft)
if echo "$command" | grep -qE '(cp|mv)[[:space:]]+(~/\.ssh|~/\.aws|\$HOME/\.ssh|\$HOME/\.aws|/etc/)'; then
  echo '{"decision": "block", "reason": "Copy/move from sensitive path blocked"}'
  exit 0
fi

# Block ln (symlinks) to/from system paths (can bypass other checks)
if echo "$command" | grep -qE 'ln[[:space:]]+.*(/etc|/usr|~/\.|/root)'; then
  echo '{"decision": "block", "reason": "Symlink involving system path blocked"}'
  exit 0
fi

# Block find/locate searching outside project in dangerous ways
if echo "$command" | grep -qE 'find[[:space:]]+(/|/etc|/home|/root|~)[[:space:]]'; then
  echo '{"decision": "block", "reason": "find on system root blocked - use project-relative paths"}'
  exit 0
fi

# Block tar/zip extracting to or from system paths
if echo "$command" | grep -qE '(tar|unzip|gunzip)[[:space:]]+.*(-C|--directory)[[:space:]]*(/etc|/usr|/var|/root|~)'; then
  echo '{"decision": "block", "reason": "Archive extraction to system path blocked"}'
  exit 0
fi

# === ECHO/PRINTF/REDIRECTION BYPASS PREVENTION ===

# Block echo/printf writing to system files
if echo "$command" | grep -qE '(echo|printf)[[:space:]].*>[[:space:]]*(/etc/|/usr/|/var/|/root/)'; then
  echo '{"decision": "block", "reason": "echo/printf to system file blocked"}'
  exit 0
fi

# Block echo/printf to shell config files
if echo "$command" | grep -qE '(echo|printf)[[:space:]].*>[[:space:]]*(~/\.bashrc|~/\.profile|~/\.bash_profile|\$HOME/\.bashrc)'; then
  echo '{"decision": "block", "reason": "echo/printf to shell config blocked"}'
  exit 0
fi

# Block piping to bash/sh/eval (arbitrary code execution)
if echo "$command" | grep -qE '\|[[:space:]]*(bash|sh|zsh)([[:space:]]|$)'; then
  echo '{"decision": "block", "reason": "Pipe to shell interpreter blocked - potential code injection"}'
  exit 0
fi

# Block base64 decode piped to execution
if echo "$command" | grep -qE 'base64[[:space:]]+-d.*\|.*(bash|sh)'; then
  echo '{"decision": "block", "reason": "base64 decode to shell blocked - obfuscation attempt"}'
  exit 0
fi

# Block tee to system paths (another way to write files)
if echo "$command" | grep -qE 'tee[[:space:]]+.*(/etc/|/usr/|/var/|~/\.bashrc|~/\.profile)'; then
  echo '{"decision": "block", "reason": "tee to system path blocked"}'
  exit 0
fi

# Block eval command anywhere in command
if echo "$command" | grep -qE '(^|;[[:space:]]*)eval[[:space:]]'; then
  echo '{"decision": "block", "reason": "eval command blocked - arbitrary code execution risk"}'
  exit 0
fi

# Block source/dot command on remote or generated content
if echo "$command" | grep -qE '(^source[[:space:]]|^\.[[:space:]]).*(/tmp/|/var/tmp/|http|ftp)'; then
  echo '{"decision": "block", "reason": "source/dot on untrusted path blocked"}'
  exit 0
fi

# Block awk/sed writing to system files
if echo "$command" | grep -qE '(awk|sed)[[:space:]]+-i[[:space:]]+.*(/etc/|/usr/)'; then
  echo '{"decision": "block", "reason": "awk/sed in-place edit of system file blocked"}'
  exit 0
fi

# Block cron manipulation
if echo "$command" | grep -qE '(crontab[[:space:]]+-|/etc/cron)'; then
  echo '{"decision": "block", "reason": "Cron manipulation blocked"}'
  exit 0
fi

# Block at/batch scheduling
if echo "$command" | grep -qE '^(at|batch)[[:space:]]'; then
  echo '{"decision": "block", "reason": "Job scheduling blocked in isolated execution"}'
  exit 0
fi

# Block nohup (persistence mechanism)
if echo "$command" | grep -qE '^nohup[[:space:]]'; then
  echo '{"decision": "block", "reason": "nohup blocked - background persistence not allowed"}'
  exit 0
fi

# Block creating executable scripts in /tmp (common attack pattern)
if echo "$command" | grep -qE '>[[:space:]]*/tmp/.*\.sh'; then
  echo '{"decision": "block", "reason": "Creating script in /tmp blocked"}'
  exit 0
fi

if echo "$command" | grep -qE 'chmod[[:space:]]+\+x[[:space:]]+/tmp/'; then
  echo '{"decision": "block", "reason": "Making /tmp file executable blocked"}'
  exit 0
fi

# === APPROVED ===
echo '{"decision": "approve", "reason": "Command passed safety checks"}'

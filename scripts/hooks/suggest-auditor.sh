#!/bin/bash
# KGP PostToolUse hook (Edit|Write) — after a plugin-config file is edited,
# suggest the matching auditor agent. Silent for all other files.

KGP_HOOK_INPUT=$(cat 2>/dev/null) || exit 0
export KGP_HOOK_INPUT

python3 -c '
import json, os, sys

try:
    data = json.loads(os.environ.get("KGP_HOOK_INPUT", "{}"))
    path = (data.get("tool_input") or {}).get("file_path", "") or ""
except Exception:
    sys.exit(0)

suggestion = None
if path.endswith("SKILL.md"):
    suggestion = "A SKILL.md was just modified — consider a quick audit via the skill-auditor agent (/KGP:core:audit-skill)."
elif "/commands/" in path and path.endswith(".md"):
    suggestion = "A slash command file was just modified — consider the slash-command-auditor agent (/KGP:core:audit-slash-command)."
elif "/agents/" in path and path.endswith(".md"):
    suggestion = "A subagent config was just modified — consider the subagent-auditor agent (/KGP:core:audit-subagent)."

if suggestion:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": "[KGP hint] " + suggestion + " Skip if mid-batch; audit once at the end."
        }
    }))
sys.exit(0)
' 2>/dev/null

exit 0

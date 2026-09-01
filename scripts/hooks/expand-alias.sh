#!/bin/bash
# KGP UserPromptSubmit hook — expand a bare communication alias into its full instruction.
# Fires ONLY when the entire prompt is exactly one alias. Silent for every other prompt.
# Never blocks a prompt.
#
# Separate from suggest-skill.sh on purpose: that script exits for prompts under six words,
# and every alias here is one word.

KGP_HOOK_INPUT=$(cat 2>/dev/null) || exit 0
export KGP_HOOK_INPUT

python3 -c '
import json, os, sys

try:
    data = json.loads(os.environ.get("KGP_HOOK_INPUT", "{}"))
    prompt = (data.get("prompt") or "").strip().lower()
except Exception:
    sys.exit(0)

ALIASES = {
    "scr": "Simplify, compress, and repeat your response.",
    "eli": "Explain this like I am 18. Simplify your language further than the baseline. Shorten your response.",
    "foc": "Focus on what matters most here. What is the true signal and value? Boil the response down to the one thing to focus on.",
    "ref": "Rewrite your response with reference codes (D1 decisions, O1 options, F1 findings, R1 risks, Q1 questions, A1 actions).",
}

# Exact match only. Inside a longer message these are ordinary words.
if prompt in ALIASES:
    print("[KGP alias] " + ALIASES[prompt])

sys.exit(0)
' 2>/dev/null

exit 0

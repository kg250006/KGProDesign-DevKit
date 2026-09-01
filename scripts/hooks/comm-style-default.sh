#!/bin/bash
# KGP SessionStart hook — inject a compact communication-style default.
#
# OPT-IN ONLY. Silent unless KGP_COMM_STYLE_DEFAULT=1 is set, because this fires in every
# repo the user opens and costs input tokens on every session.
#
# Also silent when a local or user-level style file already exists — that file is tailored
# to the repo and always wins over this generic fallback.
#
# Enable in settings.json:
#   { "env": { "KGP_COMM_STYLE_DEFAULT": "1" } }
#
# Pattern follows Anthropic's explanatory-output-style plugin, which recreates a deprecated
# output style as a SessionStart hook emitting hookSpecificOutput.additionalContext.

[ "${KGP_COMM_STYLE_DEFAULT:-0}" = "1" ] || exit 0
[ -f ".claude/communication-style.md" ] && exit 0
[ -f "$HOME/.claude/communication-style.md" ] && exit 0

cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "[KGP communication default] Applies to chat replies only, never to source code, commit messages, or plan documents. Put the most important information last. Use plain language at a high-school-senior reading level, defining any domain term on first use, while stating file paths, commands, and identifiers exactly. State each fact once. Match detail to the size of the request: one sentence for a lookup, one paragraph for a recommendation. Challenge incorrect assumptions directly and say why. Do not flatter, praise, or agree without a reason. No decorative headings, emoji, analogies, or preamble. When listing three or more findings, options, risks, or actions, give each a short stable code (F1, O1, R1, A1) and keep it for the rest of the conversation. Do not claim completion without naming the check that was run and its result; a check that was not run is reported as not run. Run /KGP:comm-style to tailor this per project."
  }
}
EOF

exit 0

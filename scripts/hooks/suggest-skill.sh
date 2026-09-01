#!/bin/bash
# KGP UserPromptSubmit hook — inject a one-line skill/command hint when the
# prompt clearly matches a plugin capability. Silent (exit 0, no output) in
# every other case. Never blocks a prompt.

KGP_HOOK_INPUT=$(cat 2>/dev/null) || exit 0
export KGP_HOOK_INPUT

python3 -c '
import json, os, re, sys

try:
    data = json.loads(os.environ.get("KGP_HOOK_INPUT", "{}"))
    prompt = (data.get("prompt") or "").strip()
except Exception:
    sys.exit(0)

p = prompt.lower()

# Do not hint when the user already invoked a slash command or named a PRP file
if p.startswith("/") or "/kgp:" in p or (".md" in p and "prp" in p):
    sys.exit(0)
# Keep quiet on very short conversational prompts
if len(p.split()) < 6:
    sys.exit(0)

def has(*pats):
    return any(re.search(pat, p) for pat in pats)

hint = None

# Priority order: deploy > debug > design > spec/PRP
if has(r"\bdeploy\b", r"\bgo live\b", r"\bpublish (the )?(site|website|app)\b", r"\bship (it|this|to prod)"):
    hint = "Deployment intent detected — consider /KGP:deploy (deployment-expert skill: Netlify, Azure VM, FTP, GitHub production)."
elif has(r"\bwhy (is|does|isn.?t|won.?t)\b", r"\bnot working\b", r"\bkeeps? (crashing|failing|breaking)\b", r"\broot cause\b"):
    hint = "Debugging intent detected — consider /KGP:dev:debug (debug-like-expert skill: evidence, hypotheses, systematic testing)."
elif has(r"\b(design|redesign|mock ?up|landing page|hero section)\b") and has(r"\b(build|create|make|design|implement)\b"):
    hint = ("Design work detected — design-token-first: kgprodesign-branding skill for KGP properties, "
            "frontend-design skill (if installed) for component generation, ui-visual-testing for the screenshot-critique-refine QA loop.")
elif has(r"\b(build|implement|create|add)\b.*\b(feature|system|integration|module|workflow|app|api)\b") and len(p.split()) >= 15:
    hint = "Feature-sized request detected — consider /KGP:prp-create to spec it as a PRP (intent-lock + validation gates), then /KGP:prp-execute."

elif has(r"\btoo (verbose|long|wordy|technical)\b", r"\bshorter (replies|responses|answers)\b",
         r"\bbe (more )?concise\b", r"\bsimplify (your|the) (response|replies|language|answers)\b",
         r"\bstop explaining so much\b", r"\bcommunication style\b", r"\bless verbose\b"):
    hint = ("Verbosity/communication-style intent detected — consider /KGP:comm-style to install a "
            "per-project communication ruleset (concise, plain language, reference codes, aliases).")

if hint:
    print("[KGP hint] " + hint + " Ignore if the user intent is better served directly.")
sys.exit(0)
' 2>/dev/null

exit 0

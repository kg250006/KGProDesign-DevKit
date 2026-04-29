#!/usr/bin/env bash
# Static validation for KGProDesign-DevKit v2.2.0 native PRP execution.
# Validates YAML frontmatter, JSON manifests, deletions of obsolete files,
# absence of obsolete language, and structural elements introduced in v2.2.0.
# No Claude CLI or plugin installation required.

set -u

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PLUGIN_ROOT"

PASS=0
FAIL=0
FAILURES=()

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); FAILURES+=("$1"); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

section() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }

# --------------------------------------------------------------------
section "1. YAML frontmatter parse — surviving commands + skills"

YAML_TARGETS=(
  "commands/prp-execute.md"
  "commands/prp-create.md"
  "commands/prp-validate.md"
  "commands/help.md"
  "commands/team-invoke.md"
  "skills/agent-teams/SKILL.md"
)

for f in "${YAML_TARGETS[@]}"; do
  if [ ! -f "$f" ]; then
    fail "$f — file missing"
    continue
  fi
  first_line=$(head -n 1 "$f")
  if [ "$first_line" != "---" ]; then
    fail "$f — missing opening frontmatter delimiter"
    continue
  fi
  fm=$(awk '/^---$/{c++; next} c==1{print} c==2{exit}' "$f")
  if [ -z "$fm" ]; then
    fail "$f — empty or malformed frontmatter"
    continue
  fi
  if ! printf "%s\n" "$fm" | grep -qE '^description:'; then
    fail "$f — frontmatter missing 'description:' key"
    continue
  fi
  pass "$f — frontmatter parses"
done

# --------------------------------------------------------------------
section "2. JSON validity — plugin.json + hooks.json + marketplace.json"

validate_json() {
  local path="$1"
  if [ ! -f "$path" ]; then
    fail "$path — file missing"
    return
  fi
  if command -v jq >/dev/null 2>&1; then
    if jq -e . "$path" >/dev/null 2>&1; then
      pass "$path — valid JSON (jq)"
    else
      fail "$path — invalid JSON (jq)"
    fi
  elif command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$path" >/dev/null 2>&1; then
      pass "$path — valid JSON (python3)"
    else
      fail "$path — invalid JSON (python3)"
    fi
  else
    fail "$path — no jq/python3 to validate"
  fi
}

validate_json ".claude-plugin/plugin.json"
validate_json ".claude-plugin/marketplace.json"
validate_json "hooks/hooks.json"

# v2.2.0 version invariants
if command -v jq >/dev/null 2>&1; then
  ver=$(jq -r '.version' .claude-plugin/plugin.json 2>/dev/null)
  if [ "$ver" = "2.2.0" ]; then
    pass "plugin.json version is 2.2.0"
  else
    fail "plugin.json version is '$ver' (expected 2.2.0)"
  fi

  mkt_ver=$(jq -r '.metadata.version' .claude-plugin/marketplace.json 2>/dev/null)
  if [ "$mkt_ver" = "$ver" ]; then
    pass "marketplace.json metadata.version ($mkt_ver) matches plugin.json"
  else
    fail "marketplace.json metadata.version ($mkt_ver) does not match plugin.json ($ver)"
  fi

  mkt_plugin_ver=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json 2>/dev/null)
  if [ "$mkt_plugin_ver" = "$ver" ]; then
    pass "marketplace.json plugins[0].version ($mkt_plugin_ver) matches plugin.json"
  else
    fail "marketplace.json plugins[0].version ($mkt_plugin_ver) does not match plugin.json ($ver)"
  fi

  if jq -e '.keywords | index("agent-teams")' .claude-plugin/plugin.json >/dev/null 2>&1; then
    pass "plugin.json keywords include 'agent-teams'"
  else
    fail "plugin.json keywords missing 'agent-teams'"
  fi

  if jq -e '.keywords | index("iterative-development")' .claude-plugin/plugin.json >/dev/null 2>&1; then
    fail "plugin.json keywords still include 'iterative-development' (should have been removed in v2.2.0)"
  else
    pass "plugin.json keywords do NOT include 'iterative-development'"
  fi

  desc=$(jq -r '.description' .claude-plugin/plugin.json 2>/dev/null)
  if printf "%s" "$desc" | grep -qiE 'three-tier|ralph loop|marketplace'; then
    fail "plugin.json description still contains obsolete language: $desc"
  else
    pass "plugin.json description has no obsolete language"
  fi
fi

# hooks.json shape — empty hooks object
if command -v jq >/dev/null 2>&1; then
  hook_count=$(jq '.hooks | length' hooks/hooks.json 2>/dev/null)
  if [ "$hook_count" = "0" ]; then
    pass "hooks.json hooks object is empty"
  else
    fail "hooks.json has $hook_count hooks registered (expected 0)"
  fi
fi

# --------------------------------------------------------------------
section "3. v2.2.0 deletions — confirm removal"

DELETED=(
  "commands/prp-execute-batch.md"
  "commands/prp-execute-isolated.md"
  "scripts/prp-orchestrator.sh"
  "scripts/prp-orchestrator.ps1"
  "scripts/prp-batch-runner.sh"
  "scripts/prp-batch-runner.ps1"
  "scripts/prp-to-tasks.js"
  "scripts/tests/test-detection-logic.sh"
  "hooks/prp-safety-hook.sh"
  "hooks/prp-safety-hook.ps1"
  "hooks/prp-safety-hook.js"
  "templates/current-task.md.template"
)

for f in "${DELETED[@]}"; do
  if [ -e "$f" ]; then
    fail "$f — still exists (should have been deleted in v2.2.0)"
  else
    pass "$f — confirmed deleted"
  fi
done

# --------------------------------------------------------------------
section "4. Surviving structural files — confirm presence"

REQUIRED=(
  "commands/prp-execute.md"
  "commands/prp-create.md"
  "commands/prp-validate.md"
  "commands/team-invoke.md"
  "hooks/hooks.json"
  "skills/agent-teams/SKILL.md"
  "skills/agent-teams/references/playbooks.md"
  "skills/software-architect/SKILL.md"
  "templates/prp_base.md"
  "templates/prp_planning.md"
)

for f in "${REQUIRED[@]}"; do
  if [ -f "$f" ]; then
    pass "$f — present"
  else
    fail "$f — missing"
  fi
done

# --------------------------------------------------------------------
section "5. Obsolete-language sweep — repo-wide grep"

# Strings that should NOT appear in surviving docs (except documented exceptions
# in CLAUDE.md migration block and PRPs/ historical files).
OBSOLETE_PATTERN='ralph-loop|RALPH_TIER|prp-orchestrator|prp-batch-runner|prp-to-tasks|prp-safety-hook|prp-execute-isolated|prp-execute-batch|current-task\.md\.template'

# Targets to grep — surviving commands + top-level user docs + skills.
SURVEY_TARGETS=(
  "commands"
  "skills"
  "agents"
  "CLAUDE.md"
  "README.md"
  "INSTALL.md"
)

obsolete_hits=$(grep -rEn "$OBSOLETE_PATTERN" "${SURVEY_TARGETS[@]}" 2>/dev/null \
  | grep -vE 'rm -f' \
  | grep -vE 'removed (the forked|in v2|/KGP:|/\$PLUGIN_NAME:)' \
  | grep -vE '\*\*v2\.[02]\.0\*\*' \
  || true)

if [ -z "$obsolete_hits" ]; then
  pass "No obsolete-string hits in surviving docs (migration cleanup commands excluded)"
else
  fail "Obsolete strings found in surviving docs:"
  printf "%s\n" "$obsolete_hits" | head -20 | sed 's/^/    /'
fi

# Old sizing constants (2,400 lines / max 20 / max 15) should be gone from prp-create
# EXCEPT in code-comment context that documents the version bump (e.g. "# was 2400").
if grep -E '2,?400' commands/prp-create.md | grep -vE '#\s*was\s*2400|#\s*was\s*2,?400' >/dev/null 2>&1; then
  fail "commands/prp-create.md still references old line cap (2400) outside 'was N' comment context"
else
  pass "commands/prp-create.md old line-cap references are only in 'was N' comments"
fi

# --------------------------------------------------------------------
section "6. v2.2.0 prp-execute.md structural invariants"

PE="commands/prp-execute.md"
if [ -f "$PE" ]; then
  # Should NOT contain three-tier dispatch internals OR active references to removed flags.
  # Allow mentions in "are removed" / "no longer" negation context (the doc tells users
  # those flags are gone — that's correct, not a bug).
  for s in 'RALPH_TIER' 'Tier 1' 'Tier 2' 'Tier 3' 'marketplace'; do
    if grep -q "$s" "$PE"; then
      fail "prp-execute.md still contains '$s' (should be removed in v2.2.0)"
    else
      pass "prp-execute.md does not contain '$s'"
    fi
  done
  # Removed-flags references must only appear in negation context.
  for s in '--max-iterations' '--completion-promise' '--isolated'; do
    bad=$(grep -n -- "$s" "$PE" | grep -viE 'are removed|no longer|removed in|v2\.2\.0|prior versions' || true)
    if [ -n "$bad" ]; then
      fail "prp-execute.md references '$s' outside negation context"
      printf "%s\n" "$bad" | sed 's/^/    /'
    else
      pass "prp-execute.md '$s' mentions are only in negation context"
    fi
  done
  # Should contain new structural blocks
  for s in 'execution_discipline' 'operating_mode' 'ALL PRPs COMPLETE'; do
    if grep -q "$s" "$PE"; then
      pass "prp-execute.md contains '$s'"
    else
      fail "prp-execute.md missing '$s'"
    fi
  done
else
  fail "$PE — missing"
fi

# --------------------------------------------------------------------
section "7. v2.2.0 prp-create.md structural invariants"

PC="commands/prp-create.md"
if [ -f "$PC" ]; then
  # New sizing constants (use proper regex alternation in -E mode)
  for s in '5,?000' 'up to 40' 'up to 30'; do
    if grep -qE "$s" "$PC"; then
      pass "prp-create.md contains new sizing '$s'"
    else
      fail "prp-create.md missing new sizing '$s'"
    fi
  done
  # New structural blocks (B1, B2, B3, B5)
  for s in 'intent-anchors|intent_lock' 'decision_log|<decisions>' 'critique_pass' '[Cc]onfidence [Rr]ationale'; do
    if grep -qiE "$s" "$PC"; then
      pass "prp-create.md contains new block '$s'"
    else
      fail "prp-create.md missing new block '$s'"
    fi
  done
else
  fail "$PC — missing"
fi

# --------------------------------------------------------------------
section "8. Agent Teams skill — playbooks.md has all 4 recipes"

PLAYBOOKS="skills/agent-teams/references/playbooks.md"
if [ -f "$PLAYBOOKS" ]; then
  for r in implementation review research hypothesis; do
    if grep -qE "\`$r\`" "$PLAYBOOKS"; then
      pass "playbooks.md includes recipe '$r'"
    else
      fail "playbooks.md missing recipe '$r'"
    fi
  done
else
  fail "playbooks.md missing entirely"
fi

# --------------------------------------------------------------------
section "Summary"

total=$((PASS + FAIL))
printf "\n  Total: %d  Passed: \033[32m%d\033[0m  Failed: \033[31m%d\033[0m\n" "$total" "$PASS" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  printf "\n\033[31mFailures:\033[0m\n"
  for msg in "${FAILURES[@]}"; do
    printf "  - %s\n" "$msg"
  done
  exit 1
fi

printf "\n\033[32mAll static validation checks passed.\033[0m\n"
exit 0

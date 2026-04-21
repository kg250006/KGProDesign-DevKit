#!/usr/bin/env bash
# Tier 1 — Static validation for KGProDesign-DevKit v2.0.0 changes.
# Validates YAML frontmatter, JSON manifests, stale references, hooks shape,
# and argument-hint parity. No Claude CLI or plugin installation required.

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
section "1. YAML frontmatter parse — changed commands + new skill"

YAML_TARGETS=(
  "commands/prp-execute.md"
  "commands/prp-execute-batch.md"
  "commands/prp-create.md"
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
  # Extract between first two "---" lines and validate it parses
  fm=$(awk '/^---$/{c++; next} c==1{print} c==2{exit}' "$f")
  if [ -z "$fm" ]; then
    fail "$f — empty or malformed frontmatter"
    continue
  fi
  # Check required key: description
  if ! printf "%s\n" "$fm" | grep -qE '^description:'; then
    fail "$f — frontmatter missing 'description:' key"
    continue
  fi
  pass "$f — frontmatter parses"
done

# --------------------------------------------------------------------
section "2. JSON validity — plugin.json + hooks.json"

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
validate_json "hooks/hooks.json"

# Plugin version bump check — post-Ralph removal requires major >= 2
if command -v jq >/dev/null 2>&1; then
  ver=$(jq -r '.version' .claude-plugin/plugin.json 2>/dev/null)
  major="${ver%%.*}"
  if [ "$major" -ge 2 ] 2>/dev/null; then
    pass "plugin.json version is $ver (major >= 2)"
  else
    fail "plugin.json version is '$ver' (expected major >= 2 for v2.x)"
  fi

  # marketplace.json version should match plugin.json
  mkt_ver=$(jq -r '.metadata.version' .claude-plugin/marketplace.json 2>/dev/null)
  if [ "$mkt_ver" = "$ver" ]; then
    pass "marketplace.json version ($mkt_ver) matches plugin.json"
  else
    fail "marketplace.json version ($mkt_ver) does not match plugin.json ($ver)"
  fi

  # Keyword swap check
  if jq -e '.keywords | index("agent-teams")' .claude-plugin/plugin.json >/dev/null 2>&1; then
    pass "plugin.json keywords include 'agent-teams'"
  else
    fail "plugin.json keywords missing 'agent-teams'"
  fi

  if jq -e '.keywords | index("ralph-loop")' .claude-plugin/plugin.json >/dev/null 2>&1; then
    fail "plugin.json keywords still include 'ralph-loop' (should have been removed)"
  else
    pass "plugin.json keywords do NOT include 'ralph-loop'"
  fi
fi

# hooks.json shape — empty hooks object
if command -v jq >/dev/null 2>&1; then
  hook_count=$(jq '.hooks | length' hooks/hooks.json 2>/dev/null)
  if [ "$hook_count" = "0" ]; then
    pass "hooks.json hooks object is empty (as expected post-Ralph removal)"
  else
    fail "hooks.json has $hook_count hooks registered (expected 0)"
  fi
fi

# --------------------------------------------------------------------
section "3. Deleted files — confirm removal"

DELETED=(
  "commands/ralph-loop.md"
  "commands/cancel-ralph.md"
  "scripts/setup-ralph-loop.sh"
  "scripts/setup-ralph-loop.ps1"
  "scripts/ralph-auto.sh"
  "scripts/ralph-auto.ps1"
  "hooks/stop-hook.sh"
  "hooks/stop-hook.js"
  "hooks/stop-hook.ps1"
  "hooks/session-start-hook.sh"
  "hooks/session-start-hook.js"
  "hooks/session-start-hook.ps1"
)

for f in "${DELETED[@]}"; do
  if [ -e "$f" ]; then
    fail "$f — still exists (should have been deleted)"
  else
    pass "$f — confirmed deleted"
  fi
done

# --------------------------------------------------------------------
section "4. New files — confirm presence"

NEW_FILES=(
  "commands/team-invoke.md"
  "skills/agent-teams/SKILL.md"
  "skills/agent-teams/references/playbooks.md"
)

for f in "${NEW_FILES[@]}"; do
  if [ -f "$f" ]; then
    pass "$f — present"
  else
    fail "$f — missing"
  fi
done

# --------------------------------------------------------------------
section "5. Stale-reference sweep (docs that users will read)"

# Look for references to deleted commands in docs (ignoring migration notes
# that are SUPPOSED to mention the removed commands). We only flag cases
# that treat them as CURRENT rather than HISTORICAL.

DOC_TARGETS=(
  "README.md"
  "CLAUDE.md"
  "commands/help.md"
  "commands/prp-create.md"
  "commands/prp-execute.md"
  "commands/prp-execute-batch.md"
  "commands/prp-execute-isolated.md"
)

# Look for /KGP:ralph-loop or /KGP:cancel-ralph used as active syntax
# (not prefixed with "removed" / "deprecated" / "migration" context)
for f in "${DOC_TARGETS[@]}"; do
  [ -f "$f" ] || continue
  # Grep for /KGP:ralph-loop in a code fence line (common usage pattern)
  if grep -nE '^\s*/KGP:ralph-loop[[:space:]]' "$f" >/dev/null 2>&1; then
    fail "$f — appears to document /KGP:ralph-loop as active syntax"
  fi
  if grep -nE '^\s*/KGP:cancel-ralph[[:space:]]*$' "$f" >/dev/null 2>&1; then
    fail "$f — appears to document /KGP:cancel-ralph as active syntax"
  fi
done

# Make sure marketplace form `/ralph-loop` IS referenced in user-facing docs
if grep -qE '/ralph-loop' README.md; then
  pass "README.md references marketplace '/ralph-loop'"
else
  fail "README.md does not mention marketplace '/ralph-loop'"
fi

if grep -qE '/ralph-loop' commands/help.md; then
  pass "help.md references marketplace '/ralph-loop'"
else
  fail "help.md does not mention marketplace '/ralph-loop'"
fi

if grep -qE '/ralph-loop' commands/prp-execute.md; then
  pass "prp-execute.md emits marketplace '/ralph-loop' (not /KGP:ralph-loop)"
else
  fail "prp-execute.md does not mention '/ralph-loop'"
fi

# Sanity check: prp-execute.md must NOT emit /KGP:ralph-loop as active syntax.
# Allow references in negation context (e.g. "NOT /KGP:ralph-loop") since those
# are warning the reader away from the old form.
bad_hits=$(grep -nE '/KGP:ralph-loop' commands/prp-execute.md \
  | grep -viE '(NOT[[:space:]]*`?/KGP:ralph-loop|never[[:space:]]*`?/KGP:ralph-loop|not[[:space:]]*`?/KGP:ralph-loop)' \
  || true)
if [ -n "$bad_hits" ]; then
  fail "prp-execute.md references /KGP:ralph-loop outside negation context"
  printf "%s\n" "$bad_hits" | sed 's/^/    /'
else
  pass "prp-execute.md /KGP:ralph-loop mentions are only in negation context"
fi

# --------------------------------------------------------------------
section "6. --team / --isolated mutex documented consistently"

MUTEX_TARGETS=(
  "commands/prp-execute.md"
  "commands/prp-execute-batch.md"
  "CLAUDE.md"
  "README.md"
  "commands/help.md"
  "skills/agent-teams/SKILL.md"
)

for f in "${MUTEX_TARGETS[@]}"; do
  [ -f "$f" ] || { fail "$f — missing"; continue; }
  if grep -qiE '(mutually exclusive|mutex|not both)' "$f"; then
    pass "$f — mentions mutex"
  else
    fail "$f — does NOT mention --team/--isolated mutex"
  fi
done

# --------------------------------------------------------------------
section "7. Bash syntax check — RALPH_TIER detection block"

# Extract the detection bash block from prp-execute.md and parse it.
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

# Pull out the first ```bash ... ``` fence from prp-execute.md
awk '
  /^```bash$/ { inblock=1; next }
  /^```$/ && inblock { exit }
  inblock { print }
' commands/prp-execute.md > "$tmpfile"

if [ ! -s "$tmpfile" ]; then
  fail "Could not extract bash block from prp-execute.md"
else
  if bash -n "$tmpfile" 2>/dev/null; then
    pass "prp-execute.md detection bash block parses cleanly"
  else
    fail "prp-execute.md detection bash block has syntax errors"
    bash -n "$tmpfile" 2>&1 | sed 's/^/    /'
  fi
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

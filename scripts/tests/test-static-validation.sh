#!/usr/bin/env bash
# Static validation for KGProDesign-DevKit v2.16.0.
# Validates YAML frontmatter, JSON manifests, deletions of obsolete files,
# absence of obsolete language, and structural elements introduced in v2.2.0.
# No Claude CLI or plugin installation required.

set -u

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PLUGIN_ROOT"

PASS=0
FAIL=0
SKIPPED=0
FAILURES=()

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); FAILURES+=("$1"); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

skip() { SKIPPED=$((SKIPPED + 1)); printf "  \033[33mSKIP\033[0m %s\n" "$1"; }

section() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }

# --------------------------------------------------------------------
# JSON readers with a jq-free fallback.
#
# Every JSON assertion below used to sit behind `if command -v jq`, so on a
# machine without jq the whole group reported SKIP and proved nothing. That is
# how the plugin version was allowed to drift from 2.3.0 to 2.5.0 unnoticed:
# the suite said "all checks passed" while the version invariants never ran.
#
# Python is already a hard dependency of this repo's tools/ directory, so the
# fallback adds no new requirement. jq stays preferred where it is present.

_json_py() {
  # Print the Python interpreter to use, or nothing when there is none.
  command -v python3 2>/dev/null || command -v python 2>/dev/null || true
}

_json_have_reader() {
  command -v jq >/dev/null 2>&1 && return 0
  [ -n "$(_json_py)" ]
}

# Walk a dotted path with at most one indexed segment per step. The three
# real call sites are ".version", ".metadata.version", and ".plugins[0].version",
# so this handles an indexed segment explicitly rather than implementing a
# general JSONPath parser.
_JSON_WALK='import json,re,sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
for seg in sys.argv[2].lstrip(".").split("."):
    if not seg:
        continue
    m = re.match(r"^([^\[\]]*)(?:\[(\d+)\])?$", seg)
    if m is None:
        sys.exit(1)
    key, idx = m.group(1), m.group(2)
    if key:
        d = d[key]
    if idx is not None:
        d = d[int(idx)]
'

json_get() {
  # json_get <file> <dotted.path> -- print the value, empty on any failure.
  local file="$1" path="$2" py
  if command -v jq >/dev/null 2>&1; then
    jq -r "$path" "$file" 2>/dev/null
    return
  fi
  py="$(_json_py)"
  [ -n "$py" ] || return 0
  "$py" -c "${_JSON_WALK}"'
print(str(d).lower() if isinstance(d, bool) else d)' "$file" "$path" 2>/dev/null
}

json_len() {
  # json_len <file> <dotted.path> -- print the element count, empty on failure.
  local file="$1" path="$2" py
  if command -v jq >/dev/null 2>&1; then
    jq "$path | length" "$file" 2>/dev/null
    return
  fi
  py="$(_json_py)"
  [ -n "$py" ] || return 0
  "$py" -c "${_JSON_WALK}"'
print(len(d))' "$file" "$path" 2>/dev/null
}

json_has() {
  # json_has <file> <dotted.path> -- exit 0 when the path resolves to a
  # non-null value, non-zero otherwise. Prints nothing.
  local file="$1" path="$2" py
  if command -v jq >/dev/null 2>&1; then
    jq -e "$path" "$file" >/dev/null 2>&1
    return
  fi
  py="$(_json_py)"
  [ -n "$py" ] || return 1
  "$py" -c "${_JSON_WALK}"'
sys.exit(0 if d is not None else 1)' "$file" "$path" >/dev/null 2>&1
}

json_has_item() {
  # json_has_item <file> <dotted.path> <value> -- exit 0 when the array at
  # <path> contains <value>. Prints nothing.
  local file="$1" path="$2" want="$3" py
  if command -v jq >/dev/null 2>&1; then
    jq -e --arg w "$want" "$path | index(\$w)" "$file" >/dev/null 2>&1
    return
  fi
  py="$(_json_py)"
  [ -n "$py" ] || return 1
  "$py" -c "${_JSON_WALK}"'
sys.exit(0 if sys.argv[3] in (d or []) else 1)' "$file" "$path" "$want" >/dev/null 2>&1
}

# --------------------------------------------------------------------
section "1. YAML frontmatter parse — surviving commands + skills"

YAML_TARGETS=(
  "commands/prp-execute.md"
  "commands/prp-create.md"
  "commands/prp-validate.md"
  "commands/help.md"
  "commands/team-invoke.md"
  "skills/agent-teams/SKILL.md"
  "commands/comm-style.md"
  "skills/communication-style/SKILL.md"
  "commands/tools/status.md"
  "commands/tools/cron.md"
  "commands/tools/schedule.md"
  "commands/tools/jiggler.md"
  "skills/desktop-tools/SKILL.md"
  "skills/kgp-hosting/SKILL.md"
  "commands/migrate-netlify.md"
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
  elif [ -n "$(_json_py)" ]; then
    if "$(_json_py)" -c "import json,sys; json.load(open(sys.argv[1],encoding='utf-8'))" "$path" >/dev/null 2>&1; then
      pass "$path — valid JSON (python)"
    else
      fail "$path — invalid JSON (python)"
    fi
  else
    fail "$path — no jq/python to validate"
  fi
}

validate_json ".claude-plugin/plugin.json"
validate_json ".claude-plugin/marketplace.json"
validate_json "hooks/hooks.json"

# v2.16.0 version invariants
if _json_have_reader; then
  ver=$(json_get .claude-plugin/plugin.json ".version")
  if [ "$ver" = "2.16.0" ]; then
    pass "plugin.json version is 2.16.0"
  else
    fail "plugin.json version is '$ver' (expected 2.16.0)"
  fi

  mkt_ver=$(json_get .claude-plugin/marketplace.json ".metadata.version")
  if [ "$mkt_ver" = "$ver" ]; then
    pass "marketplace.json metadata.version ($mkt_ver) matches plugin.json"
  else
    fail "marketplace.json metadata.version ($mkt_ver) does not match plugin.json ($ver)"
  fi

  mkt_plugin_ver=$(json_get .claude-plugin/marketplace.json ".plugins[0].version")
  if [ "$mkt_plugin_ver" = "$ver" ]; then
    pass "marketplace.json plugins[0].version ($mkt_plugin_ver) matches plugin.json"
  else
    fail "marketplace.json plugins[0].version ($mkt_plugin_ver) does not match plugin.json ($ver)"
  fi

  if json_has_item .claude-plugin/plugin.json ".keywords" "agent-teams"; then
    pass "plugin.json keywords include 'agent-teams'"
  else
    fail "plugin.json keywords missing 'agent-teams'"
  fi

  if json_has_item .claude-plugin/plugin.json ".keywords" "iterative-development"; then
    fail "plugin.json keywords still include 'iterative-development' (should have been removed in v2.2.0)"
  else
    pass "plugin.json keywords do NOT include 'iterative-development'"
  fi

  desc=$(json_get .claude-plugin/plugin.json ".description")
  if printf "%s" "$desc" | grep -qiE 'three-tier|ralph loop|marketplace'; then
    fail "plugin.json description still contains obsolete language: $desc"
  else
    pass "plugin.json description has no obsolete language"
  fi
else
  skip "plugin.json/marketplace.json version invariants - neither jq nor python available"
  skip "plugin.json keyword assertions - neither jq nor python available"
  skip "plugin.json description language sweep - neither jq nor python available"
fi

# hooks.json shape — v2.3.0 auto-invocation hooks registered
if _json_have_reader; then
  hook_count=$(json_len hooks/hooks.json ".hooks")
  if [ "$hook_count" = "3" ]; then
    pass "hooks.json registers 3 hook events"
  else
    fail "hooks.json has $hook_count hook events registered (expected 3: UserPromptSubmit, SessionStart, PostToolUse)"
  fi

  for evt in UserPromptSubmit SessionStart PostToolUse; do
    if json_has hooks/hooks.json ".hooks.${evt}"; then
      pass "hooks.json registers ${evt}"
    else
      fail "hooks.json missing ${evt}"
    fi
  done
else
  skip "hooks.json event-count and event-presence checks - neither jq nor python available"
fi

# hook scripts exist and are executable
for hs in scripts/hooks/suggest-skill.sh scripts/hooks/session-start.sh scripts/hooks/suggest-auditor.sh scripts/hooks/expand-alias.sh scripts/hooks/comm-style-default.sh; do
  if [ -x "$hs" ]; then
    pass "$hs — present and executable"
  else
    fail "$hs — missing or not executable"
  fi
done

# hook scripts never fail and stay silent on malformed input
for hs in scripts/hooks/suggest-skill.sh scripts/hooks/suggest-auditor.sh scripts/hooks/expand-alias.sh scripts/hooks/comm-style-default.sh; do
  out=$(echo 'not json' | "./$hs" 2>/dev/null); rc=$?
  if [ $rc -eq 0 ] && [ -z "$out" ]; then
    pass "$hs — exit 0 and silent on malformed input"
  else
    fail "$hs — rc=$rc output='$out' on malformed input (expected silent exit 0)"
  fi
done

# expand-alias.sh actually expands a bare alias
out=$(echo '{"prompt":"ref"}' | ./scripts/hooks/expand-alias.sh 2>/dev/null)
if printf "%s" "$out" | grep -q "reference codes"; then
  pass "expand-alias.sh - expands a bare alias"
else
  fail "expand-alias.sh - did not expand 'ref' (got: '$out')"
fi

# expand-alias.sh stays silent when the alias is inside a longer message
out=$(echo '{"prompt":"please ref the findings"}' | ./scripts/hooks/expand-alias.sh 2>/dev/null)
if [ -z "$out" ]; then
  pass "expand-alias.sh - silent when alias is not the whole message"
else
  fail "expand-alias.sh - expanded inline 'ref' (got: '$out')"
fi

# comm-style-default.sh is opt-in and stays off without the env var
out=$(./scripts/hooks/comm-style-default.sh 2>/dev/null)
if [ -z "$out" ]; then
  pass "comm-style-default.sh - silent without KGP_COMM_STYLE_DEFAULT=1"
else
  fail "comm-style-default.sh - emitted output while opt-in flag was unset"
fi

# A personal communication rule must never be committable, and must never be paired with an
# @ import (files in .claude/rules/ auto-load; an import would load the content twice).
if [ -f .claude/rules/communication.local.md ]; then
  if git check-ignore -q .claude/rules/communication.local.md 2>/dev/null; then
    pass "personal communication rule is git-excluded"
  else
    fail "personal communication rule is NOT excluded - it would be committed"
  fi
  if git ls-files --error-unmatch .claude/rules/communication.local.md >/dev/null 2>&1; then
    fail "personal communication rule is tracked by git"
  else
    pass "personal communication rule is not tracked"
  fi
fi

# No @ import may reference a .claude/rules file from any memory file.
stray=$(grep -lE '^@.*rules/communication' CLAUDE.md CLAUDE.local.md .claude.local.md 2>/dev/null || true)
if [ -z "$stray" ]; then
  pass "no redundant @ import for the auto-loaded communication rule"
else
  fail "redundant @ import found in: $stray (rules/*.md already auto-load)"
fi

# The dotted .claude.local.md is not a real Claude Code memory file; never write one.
if [ -e .claude.local.md ]; then
  fail ".claude.local.md exists - that filename is never loaded by Claude Code (use CLAUDE.local.md)"
else
  pass "no bogus .claude.local.md present"
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
  "commands/toolkit"
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
  "commands/comm-style.md"
  "skills/communication-style/SKILL.md"
  "skills/communication-style/templates/communication-style.md.template"
  "skills/communication-style/workflows/setup.md"
  "skills/communication-style/references/base-ruleset.md"
  "skills/communication-style/references/model-tics.md"
  "tools/CronLike/cronlike.py"
  "tools/CronLike/schedule_config.py"
  "tools/CronLike/scheduler.py"
  "tools/CronLike/runner.py"
  "tools/CronLike/schedule.example.json"
  "tools/CronLike/README.md"
  "tools/CronLike/SCHEDULE.md"
  "tools/MouseJiggler/mouse_jiggler.py"
  "tools/MouseJiggler/README.md"
  "scripts/tools/plugin-root.sh"
  "scripts/tools/toolctl.sh"
  "scripts/tools/launch.py"
  "commands/tools/status.md"
  "commands/tools/cron.md"
  "commands/tools/schedule.md"
  "commands/tools/jiggler.md"
  "skills/desktop-tools/SKILL.md"
  "skills/desktop-tools/references/tool-registry.md"
  "skills/desktop-tools/references/cronlike.md"
  "skills/desktop-tools/references/mousejiggler.md"
  "skills/desktop-tools/references/scheduling-patterns.md"
  "skills/desktop-tools/references/install-and-update.md"
  "skills/desktop-tools/references/troubleshooting.md"
  "skills/desktop-tools/workflows/operate.md"
  "skills/desktop-tools/workflows/configure-schedule.md"
  "skills/desktop-tools/workflows/diagnose.md"
  "skills/desktop-tools/workflows/add-tool.md"
  "skills/desktop-tools/templates/tool-reference.md.template"
  "skills/kgp-hosting/SKILL.md"
  "skills/kgp-hosting/references/commands.md"
  "skills/kgp-hosting/references/site-anatomy.md"
  "skills/kgp-hosting/references/troubleshooting.md"
  "skills/kgp-hosting/references/functions.md"
  "commands/migrate-netlify.md"
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
  | grep -vE ':[0-9]+: +\.claude/' \
  | grep -vE 'removed (the forked|in v2|/KGP:|/\$PLUGIN_NAME:)' \
  | grep -vE '\*\*v2\.[023]\.0\*\*' \
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
section "9. Desktop tools — anti-drift and path invariants"

# A. Scheduling references must POINT at SCHEDULE.md, never restate it.
DT_REFS="skills/desktop-tools/references"
if [ -d "$DT_REFS" ]; then
  for f in "$DT_REFS"/cronlike.md "$DT_REFS"/scheduling-patterns.md; do
    if [ ! -f "$f" ]; then
      fail "$f — missing"
    elif grep -q "SCHEDULE.md" "$f"; then
      pass "$(basename "$f") points at SCHEDULE.md"
    else
      fail "$(basename "$f") never references SCHEDULE.md — it must point, not restate"
    fi
  done
else
  fail "skills/desktop-tools/references/ missing entirely"
fi

# B. THE anti-drift assertion. A field-definition table inside the skill is a
# second copy of SCHEDULE.md's contract, which drifts from the parser silently
# and only surfaces months later as a job that quietly stopped firing.
if [ -d "skills/desktop-tools" ]; then
  if grep -rEq '^\|.*[Ff]ield.*\|.*[Rr]equired' skills/desktop-tools/; then
    fail "skills/desktop-tools/ contains a field-definition table — SCHEDULE.md is the only field reference"
    grep -rEn '^\|.*[Ff]ield.*\|.*[Rr]equired' skills/desktop-tools/ | head -3
  else
    pass "skills/desktop-tools/ has no duplicated field-definition table"
  fi
else
  fail "skills/desktop-tools/ missing entirely"
fi

# C. No version-stamped plugin path may be committed. The plugin cache is
# versioned, so any captured absolute path breaks on the next update.
if grep -rEq 'cache/KGP/KGP/[0-9]+\.[0-9]+\.[0-9]+' commands/tools scripts/tools 2>/dev/null; then
  fail "a versioned plugin path is committed under commands/tools or scripts/tools"
  grep -rEn 'cache/KGP/KGP/[0-9]+\.[0-9]+\.[0-9]+' commands/tools scripts/tools | head -3
else
  pass "no version-stamped plugin paths in commands/tools or scripts/tools"
fi

# D. The autostart shim must survive a plugin update, so it may not bake in a version.
if [ -f "scripts/tools/launch.py" ]; then
  if grep -vE '^\s*#' scripts/tools/launch.py | grep -Eq '[0-9]+\.[0-9]+\.[0-9]+'; then
    fail "scripts/tools/launch.py contains a hardcoded version outside comments"
  else
    pass "scripts/tools/launch.py bakes in no version"
  fi
else
  fail "scripts/tools/launch.py missing"
fi

# E. Every tool directory must have a registry row, so a tool cannot be added
# half-way. The registry and toolctl.sh's REGISTRY block are two copies of one fact.
REG="skills/desktop-tools/references/tool-registry.md"
if [ -f "$REG" ] && [ -d "tools" ]; then
  for d in tools/*/; do
    name="$(basename "$d")"
    if grep -q "tools/$name/" "$REG"; then
      pass "tool-registry.md has a row for tools/$name"
    else
      fail "tools/$name has no row in tool-registry.md"
    fi
    if grep -q "tools/$name|" scripts/tools/toolctl.sh 2>/dev/null; then
      pass "toolctl.sh REGISTRY has a row for tools/$name"
    else
      fail "tools/$name has no row in toolctl.sh REGISTRY"
    fi
  done
else
  fail "$REG or tools/ missing"
fi

# --------------------------------------------------------------------
section "10. KGP Host skill — public-repo safety and routing"

# This repo is public; the skill's source repo is private. No host-specific detail may leak.
KH="skills/kgp-hosting"
if [ -d "$KH" ]; then
  # Keep this pattern identical to the guard in KGP-WebHosting-Tools scripts/install-skill.sh.
  if grep -rEn '([0-9]{1,3}\.){3}[0-9]{1,3}|/home[0-9]*/|/Users/|hostgator\.com|kgprodux|cpanel_user *=|kgp_[A-Za-z]*token' "$KH"; then
    fail "$KH contains host-specific details (IPs, home paths, cPanel hosts, or tokens)"
  else
    pass "$KH carries no IPs, home paths, cPanel hosts, or tokens"
  fi
  for tag in "<prerequisites>" "<guardrails>" "<quick_start>" "<success_criteria>"; do
    if grep -q "$tag" "$KH/SKILL.md"; then pass "kgp-hosting SKILL.md has $tag"; else fail "kgp-hosting SKILL.md missing $tag"; fi
  done
else
  fail "$KH missing entirely"
fi

if grep -q "Skill(kgp-hosting)" commands/deploy.md && grep -q "kgp.toml" commands/deploy.md; then
  pass "/KGP:deploy routes kgp.toml repos to kgp-hosting"
else
  fail "/KGP:deploy does not route kgp.toml repos to kgp-hosting"
fi

if grep -q "references/functions.md" "$KH/SKILL.md" && grep -q "kgp_send_email" "$KH/references/functions.md"; then
  pass "kgp-hosting documents PHP functions (references/functions.md)"
else
  fail "kgp-hosting does not link or document references/functions.md"
fi

if grep -q "kgp-hosting skill" scripts/hooks/suggest-skill.sh; then
  pass "suggest-skill.sh has a kgp-hosting branch"
else
  fail "suggest-skill.sh has no kgp-hosting branch"
fi

# Every kgp example in the skill follows its own --json --yes rule.
if grep -rhoE '`kgp [^`]*--json[^`]*`' "$KH" | grep -v -- '--yes' | grep -q .; then
  fail "$KH has kgp examples with --json but without --yes"
else
  pass "$KH kgp examples all pass --json --yes"
fi

# deployment-expert hands kgp.toml repos to kgp-hosting, found from a subfolder.
KT="$(mktemp -d)"
mkdir -p "$KT/sub" && touch "$KT/kgp.toml" "$KT/sub/netlify.toml"
kp=$(cd "$KT/sub" && bash "$PLUGIN_ROOT/skills/deployment-expert/scripts/detect-platform.sh" 2>/dev/null)
rm -rf "$KT"
if [ "$kp" = "kgp-host" ]; then
  pass "detect-platform.sh reports kgp-host for a kgp.toml repo"
else
  fail "detect-platform.sh reports '$kp' for a kgp.toml repo (expected kgp-host)"
fi

if grep -q "KGP Host" skills/deployment-expert/references/corporate-accessibility.md \
   && grep -q "preload" skills/deployment-expert/workflows/hardening-remediate.md \
   && grep -q "sitepage.app" skills/deployment-expert/scripts/assess-hardening.sh; then
  pass "corporate hardening pass covers KGP Host (headers, no preload, shared subdomain)"
else
  fail "corporate hardening pass does not cover KGP Host"
fi

# --------------------------------------------------------------------
section "Summary"

total=$((PASS + FAIL))
printf "\n  Total: %d  Passed: \033[32m%d\033[0m  Failed: \033[31m%d\033[0m  Skipped: \033[33m%d\033[0m\n" "$total" "$PASS" "$FAIL" "$SKIPPED"

if [ "$SKIPPED" -gt 0 ]; then
  printf "\n\033[33m%d check group(s) skipped - install jq or python for full coverage.\033[0m\n" "$SKIPPED"
fi

if [ "$FAIL" -gt 0 ]; then
  printf "\n\033[31mFailures:\033[0m\n"
  for msg in "${FAILURES[@]}"; do
    printf "  - %s\n" "$msg"
  done
  exit 1
fi

printf "\n\033[32mAll static validation checks passed.\033[0m\n"
exit 0

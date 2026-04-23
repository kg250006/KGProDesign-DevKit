#!/usr/bin/env bash
# Tier 2 — Mocked detection logic for prp-execute.md's RALPH_TIER preflight.
# Extracts the detection block from prp-execute.md and exercises it against
# stubbed `claude` / `jq` / settings files to verify all 3 tiers resolve.
#
# No real Claude CLI calls, no marketplace plugin required.

set -u

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PLUGIN_ROOT"

PASS=0
FAIL=0
FAILURES=()

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); FAILURES+=("$1"); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }

# ------------------------------------------------------------------
# Extract the detection block into a standalone script.
# ------------------------------------------------------------------
DETECT_SCRIPT=$(mktemp)
trap 'rm -rf "$DETECT_SCRIPT" "$STUB_DIR" "$FAKE_HOME"' EXIT

awk '
  /^```bash$/ { inblock=1; next }
  /^```$/ && inblock { exit }
  inblock { print }
' commands/prp-execute.md > "$DETECT_SCRIPT"

if [ ! -s "$DETECT_SCRIPT" ]; then
  printf "\033[31mCould not extract detection bash block from commands/prp-execute.md\033[0m\n"
  exit 2
fi

# ------------------------------------------------------------------
# Run the detection block in a controlled environment and capture tier.
# Args:
#   $1 = PATH to use
#   $2 = HOME to use (for ~/.claude/settings.json fallback)
#   $3 = CWD to use (for .claude/settings.json / .local.json fallback)
# Echoes the resolved tier (1, 2, 3, or empty).
# ------------------------------------------------------------------
run_detection() {
  local use_path="$1"
  local use_home="$2"
  local use_cwd="$3"
  (
    cd "$use_cwd"
    PATH="$use_path" HOME="$use_home" bash -c '
      source "'"$DETECT_SCRIPT"'" >/dev/null 2>&1
      echo "$RALPH_TIER"
    '
  )
}

# ------------------------------------------------------------------
# Build a stub directory with a configurable `claude` and `jq`.
# ------------------------------------------------------------------
STUB_DIR=$(mktemp -d)
FAKE_HOME=$(mktemp -d)
mkdir -p "$FAKE_HOME/.claude"

make_stub() {
  local name="$1"
  local body="$2"
  cat > "$STUB_DIR/$name" <<EOF
#!/usr/bin/env bash
$body
EOF
  chmod +x "$STUB_DIR/$name"
}

# Real jq is preferred if available; otherwise tests requiring jq will be skipped.
HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAVE_JQ=1
  REAL_JQ="$(command -v jq)"
fi

# ------------------------------------------------------------------
section "Case 1 — Tier 1 via claude+jq (ralph-loop enabled)"

if [ "$HAVE_JQ" -eq 1 ]; then
  # claude stub emits JSON array with ralph-loop enabled
  make_stub claude 'cat <<JSON
[{"name":"ralph-loop","enabled":true}]
JSON'
  # Use real jq for this case (pass-through)
  ln -sf "$REAL_JQ" "$STUB_DIR/jq"

  tier=$(run_detection "$STUB_DIR:/usr/bin:/bin" "$FAKE_HOME" "$FAKE_HOME")
  if [ "$tier" = "1" ]; then
    pass "ralph-loop enabled + jq present → RALPH_TIER=1"
  else
    fail "expected tier 1, got '$tier'"
  fi
  rm -f "$STUB_DIR/claude" "$STUB_DIR/jq"
else
  fail "jq not installed on this host — skipping Case 1"
fi

# ------------------------------------------------------------------
section "Case 2 — Tier 2: claude+jq present, plugin NOT installed"

if [ "$HAVE_JQ" -eq 1 ]; then
  make_stub claude 'cat <<JSON
[]
JSON'
  ln -sf "$REAL_JQ" "$STUB_DIR/jq"

  # Clean fake home of any settings referencing ralph-loop
  rm -f "$FAKE_HOME/.claude/settings.json"

  tier=$(run_detection "$STUB_DIR:/usr/bin:/bin" "$FAKE_HOME" "$FAKE_HOME")
  if [ "$tier" = "2" ]; then
    pass "empty plugin list + jq present → RALPH_TIER=2"
  else
    fail "expected tier 2, got '$tier'"
  fi
  rm -f "$STUB_DIR/claude" "$STUB_DIR/jq"
else
  fail "jq not installed — skipping Case 2"
fi

# ------------------------------------------------------------------
section "Case 3 — Tier 3: jq missing (detection primitives unavailable)"

# Build an isolated PATH dir with symlinks to everything the detection
# block needs EXCEPT jq. This works regardless of where the host's jq lives.
ISOLATED_PATH=$(mktemp -d)
for binary in bash grep command-v-never-used; do
  real=$(command -v "$binary" 2>/dev/null || true)
  [ -n "$real" ] && ln -sf "$real" "$ISOLATED_PATH/$binary"
done
# Also link the basic POSIX helpers the block may use
for helper in cat sed awk head tail; do
  real=$(command -v "$helper" 2>/dev/null || true)
  [ -n "$real" ] && ln -sf "$real" "$ISOLATED_PATH/$helper"
done
# Deliberately NO jq symlink.

make_stub claude 'echo "[]"'
rm -f "$FAKE_HOME/.claude/settings.json"

# stub dir + isolated dir (no jq anywhere)
tier=$(run_detection "$STUB_DIR:$ISOLATED_PATH" "$FAKE_HOME" "$FAKE_HOME")
rm -rf "$ISOLATED_PATH"
if [ "$tier" = "3" ]; then
  pass "jq absent → RALPH_TIER=3"
else
  fail "expected tier 3, got '$tier'"
fi
rm -f "$STUB_DIR/claude"

# ------------------------------------------------------------------
section "Case 4 — Tier 3: claude missing"

# Stub out jq but remove claude. Use real jq if available.
if [ "$HAVE_JQ" -eq 1 ]; then
  ln -sf "$REAL_JQ" "$STUB_DIR/jq"
  # No claude stub
  rm -f "$STUB_DIR/claude"
  rm -f "$FAKE_HOME/.claude/settings.json"

  # Include /bin and /usr/bin so bash/grep/etc. work inside the subshell,
  # but exclude claude's usual install dir — since there's no stub, and
  # claude is NOT at /bin or /usr/bin on this host, claude will be absent.
  tier=$(run_detection "$STUB_DIR:/bin:/usr/bin" "$FAKE_HOME" "$FAKE_HOME")
  if [ "$tier" = "3" ]; then
    pass "claude absent → RALPH_TIER=3"
  else
    fail "expected tier 3, got '$tier'"
  fi
  rm -f "$STUB_DIR/jq"
else
  fail "jq not installed — skipping Case 4"
fi

# ------------------------------------------------------------------
section "Case 5 — Settings fallback (claude broken, settings has ralph-loop)"

if [ "$HAVE_JQ" -eq 1 ]; then
  # claude stub returns garbage / exits non-zero
  make_stub claude 'echo "not json" >&2; exit 1'
  ln -sf "$REAL_JQ" "$STUB_DIR/jq"

  # Seed ~/.claude/settings.json with ralph-loop
  cat > "$FAKE_HOME/.claude/settings.json" <<'EOF'
{
  "enabledPlugins": {
    "ralph-loop@claude-plugins-official": true
  }
}
EOF

  tier=$(run_detection "$STUB_DIR:/usr/bin:/bin" "$FAKE_HOME" "$FAKE_HOME")
  if [ "$tier" = "1" ]; then
    pass "settings fallback detects ralph-loop → RALPH_TIER=1"
  else
    fail "expected tier 1 via settings fallback, got '$tier'"
  fi
  rm -f "$STUB_DIR/claude" "$STUB_DIR/jq" "$FAKE_HOME/.claude/settings.json"
else
  fail "jq not installed — skipping Case 5"
fi

# ------------------------------------------------------------------
section "Case 6 — Hard-fail safety: broken claude, no settings"

if [ "$HAVE_JQ" -eq 1 ]; then
  make_stub claude 'echo "broken" >&2; exit 127'
  ln -sf "$REAL_JQ" "$STUB_DIR/jq"
  rm -f "$FAKE_HOME/.claude/settings.json"

  tier=$(run_detection "$STUB_DIR:/usr/bin:/bin" "$FAKE_HOME" "$FAKE_HOME")
  if [ "$tier" = "2" ] || [ "$tier" = "3" ]; then
    pass "broken claude + no settings → tier $tier (graceful fallback, did not hard-fail)"
  else
    fail "expected tier 2 or 3 on broken claude, got '$tier'"
  fi
  rm -f "$STUB_DIR/claude" "$STUB_DIR/jq"
else
  fail "jq not installed — skipping Case 6"
fi

# ------------------------------------------------------------------
section "Case 7 — Project-level settings fallback (.claude/settings.local.json)"

if [ "$HAVE_JQ" -eq 1 ]; then
  # claude stub returns empty so primary path misses
  make_stub claude 'echo "[]"'
  ln -sf "$REAL_JQ" "$STUB_DIR/jq"
  rm -f "$FAKE_HOME/.claude/settings.json"

  # Create a fake project dir with a .claude/settings.local.json referencing ralph-loop
  PROJECT_CWD=$(mktemp -d)
  mkdir -p "$PROJECT_CWD/.claude"
  cat > "$PROJECT_CWD/.claude/settings.local.json" <<'EOF'
{
  "enabledPlugins": {
    "ralph-loop@claude-plugins-official": true
  }
}
EOF

  tier=$(run_detection "$STUB_DIR:/usr/bin:/bin" "$FAKE_HOME" "$PROJECT_CWD")
  if [ "$tier" = "1" ]; then
    pass "project-level settings.local.json triggers Tier 1"
  else
    fail "expected tier 1 via project settings, got '$tier'"
  fi
  rm -rf "$PROJECT_CWD"
  rm -f "$STUB_DIR/claude" "$STUB_DIR/jq"
else
  fail "jq not installed — skipping Case 7"
fi

# ------------------------------------------------------------------
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

printf "\n\033[32mAll detection-logic checks passed.\033[0m\n"
exit 0

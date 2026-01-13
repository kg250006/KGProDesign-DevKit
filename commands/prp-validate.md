---
description: "[KGP] Validate PRP for Ralph Loop compatibility and auto-fix issues using software-architect skill"
argument-hint: <path-to-prp.md> [--fix] [--strict]
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, AskUserQuestion]
---

<agent_discovery>
## Agent Discovery for Validation

Before validating, discover available agents to verify agent assignments in PRPs:

```
Glob: agents/*.md
```

**Valid Agent Names (from discovered agents):**
Build a registry of valid agent names. Standard agents include:
- backend-engineer
- frontend-engineer
- data-engineer
- qa-engineer
- devops-engineer
- document-specialist
- project-coordinator

Use this registry in step_3_task_validation to verify agent assignments are valid.
</agent_discovery>

<objective>
Validate PRP at $ARGUMENTS for Ralph Loop compatibility. Detect issues, categorize by severity, and automatically fix problems using pattern-based fixes or the software-architect skill.

This ensures PRPs can be executed by `/$PLUGIN_NAME:prp-execute` without errors.
</objective>

<options>
Parse $ARGUMENTS for:
- **PRP file path**: First non-flag argument (required)
- **--fix**: Auto-fix issues without prompting (default: prompt before fixing)
- **--strict**: Fail on any warning, not just blocking issues
</options>

<process>

<step_1_load_prp>
**Load and Parse PRP**

Read the PRP file:
```
Read: [PRP file path from $ARGUMENTS]
```

Identify XML structure elements:
- `<prp>` root with name attribute
- `<phases>` container
- `<phase>` elements with tasks
- `<validation>` section
- `<success-criteria>` section

If PRP cannot be parsed or is empty, report BLOCKED immediately.
</step_1_load_prp>

<step_2_structure_validation>
**Structure Validation**

Check for required top-level elements:

| Element | Required | Check |
|---------|----------|-------|
| `<prp name="...">` | Yes | Root tag with name attribute |
| `<phases>` | Yes | Contains at least one `<phase>` |
| `<phase id="N">` | Yes | Each phase has id and contains `<tasks>` |
| `<tasks>` | Yes | Each phase has at least one task |
| `<validation>` | Yes | Has at least one validation level |
| `<success-criteria>` | Yes | Has at least one criterion |

**Severity:**
- Missing `<prp>`, `<phases>`, or `<tasks>`: **BLOCKING**
- Missing `<validation>` or `<success-criteria>`: **FIXABLE**

Track issues:
```
STRUCTURE_ISSUES = []
For each missing element:
  - Add to STRUCTURE_ISSUES with severity
```
</step_2_structure_validation>

<step_3_task_validation>
**Task Completeness Validation**

For each `<task>` in each `<phase>`:

**Required Attributes:**
| Attribute | Format | Default if Missing |
|-----------|--------|-------------------|
| id | "N.N" (e.g., "1.1", "2.3") | Generate based on phase.task position |
| agent | One of: backend-engineer, frontend-engineer, data-engineer, qa-engineer, devops-engineer, document-specialist | Infer from description |
| effort | S, M, L, or XL | Default to "M" |
| value | H, M, or L | Default to "M" |

**Required Children:**
| Element | Check | If Missing |
|---------|-------|------------|
| `<description>` | Non-empty text | **BLOCKING** |
| `<acceptance-criteria>` | At least one `<criterion>` | **FIXABLE** - generate from description |
| `<files>` | Optional but recommended | **WARNING** |
| `<handoff>` | Optional but recommended | **WARNING** |

**Agent Inference Logic:**
If agent attribute missing, infer from description keywords using discovered agents:
- "API", "endpoint", "service", "auth", "backend" → backend-engineer
- "UI", "component", "page", "style", "CSS", "frontend" → frontend-engineer
- "schema", "migration", "query", "database", "data" → data-engineer
- "test", "security", "review", "QA", "coverage" → qa-engineer
- "CI/CD", "deploy", "Docker", "infrastructure", "monitoring" → devops-engineer
- "documentation", "README", "docs", "technical writing" → document-specialist
- "planning", "sprint", "coordination", "task breakdown" → project-coordinator

**Validation:** Ensure inferred/assigned agent exists in the agent_discovery registry.

Track issues:
```
TASK_ISSUES = []
For each task issue:
  - Add task ID, issue type, severity, suggested fix
```
</step_3_task_validation>

<step_4_validation_commands_check>
**Validation Commands Check**

Check `<validation>` section for:

| Level | Required | Check |
|-------|----------|-------|
| syntax | Recommended | Has non-empty command |
| unit | Recommended | Has non-empty command |
| integration | Optional | Has non-empty command |

**Command Quality Checks:**
- Command is not placeholder text (TODO, TBD, [command], etc.)
- Command does not contain "..." or "[...]"
- Command references real tools (npm, yarn, pytest, etc.)

**Severity:**
- No validation section at all: **BLOCKING**
- Empty commands: **FIXABLE** - detect project and suggest
- Placeholder commands: **FIXABLE** - replace with detected commands

**Project Detection for Auto-fix:**
```bash
# Detect project type
if [ -f "package.json" ]; then
  # Node.js project - check for lint/test scripts
  grep -q '"lint"' package.json && echo "npm run lint"
  grep -q '"typecheck"' package.json && echo "npm run typecheck"
  grep -q '"test"' package.json && echo "npm test"
fi

if [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  # Python project
  echo "ruff check --fix"
  echo "pytest"
fi
```
</step_4_validation_commands_check>

<step_5_placeholder_check>
**Placeholder Detection**

Scan entire PRP for placeholder patterns:

| Pattern | Severity |
|---------|----------|
| TODO | **FIXABLE** |
| TBD | **FIXABLE** |
| [placeholder] | **FIXABLE** |
| [...] or ... | **FIXABLE** |
| path/to/file | **FIXABLE** |
| example.com (in non-example context) | **WARNING** |
| FIXME | **WARNING** |

Track locations:
```
PLACEHOLDERS = []
For each placeholder found:
  - Add line number, content, suggested action
```
</step_5_placeholder_check>

<step_6_categorize_issues>
**Categorize All Issues**

Group issues by severity:

**BLOCKING** (must fix before execution):
- Missing `<prp>` root structure
- Missing `<phases>` or `<tasks>` containers
- Tasks without descriptions
- No validation section

**FIXABLE** (can auto-fix):
- Missing task attributes (agent, effort, value)
- Vague acceptance criteria
- Placeholder text
- Missing validation commands

**WARNING** (optional improvements):
- Missing `<handoff>` sections
- Suboptimal effort/value rankings
- Missing `<files>` in tasks
- FIXME markers

Calculate severity counts:
```
BLOCKING_COUNT = len([i for i in issues if i.severity == "BLOCKING"])
FIXABLE_COUNT = len([i for i in issues if i.severity == "FIXABLE"])
WARNING_COUNT = len([i for i in issues if i.severity == "WARNING"])
```
</step_6_categorize_issues>

<step_7_fix_issues>
**Auto-Fix Workflow**

**Decision Logic:**
```
IF --fix flag present:
  Proceed with fixes immediately
ELIF BLOCKING_COUNT > 0 OR FIXABLE_COUNT > 0:
  Ask user: "Found X issues (Y blocking, Z fixable). Fix automatically?"
  IF user confirms:
    Proceed with fixes
  ELSE:
    Report issues only
ELSE:
  Report warnings only
```

**Simple Fixes (use Edit tool directly):**

1. **Missing task ID:**
   ```
   Generate ID based on phase number and task position
   Edit: Add id="N.N" to task tag
   ```

2. **Missing agent attribute:**
   ```
   Infer agent from description keywords
   Edit: Add agent="[inferred-agent]" to task tag
   ```

3. **Missing effort/value:**
   ```
   Edit: Add effort="M" value="M" to task tag
   Mark for review in output
   ```

4. **Missing validation commands:**
   ```
   Detect project type from package.json/pyproject.toml
   Edit: Add appropriate commands to <validation> section
   ```

5. **Placeholder file paths:**
   ```
   Search codebase for similar patterns
   Edit: Replace with actual paths
   ```

**Complex Fixes (invoke software-architect skill):**

For issues requiring context or decisions:
1. Invoke `/$PLUGIN_NAME:software-architect`
2. Describe the specific issue
3. Let the skill regenerate the section with proper structure
4. The skill will:
   - Research codebase patterns
   - Ask clarifying questions if needed
   - Generate properly structured content
   - Update the PRP file

**Issues requiring software-architect:**
- Missing entire `<validation>` section
- Missing entire `<phases>` structure
- Tasks with no description
- Vague acceptance criteria needing context
- File paths that need codebase research
</step_7_fix_issues>

<step_8_revalidate>
**Post-Fix Revalidation**

After applying fixes:
1. Re-read the PRP file
2. Run validation checks again
3. Confirm issues are resolved
4. Update status

If new issues discovered during fix:
- Add to issue list
- Continue fixing if simple
- Report if complex
</step_8_revalidate>

<step_9_report>
**Generate Report**

Calculate readiness score:
```
BASE_SCORE = 100
BLOCKING_PENALTY = 30 per issue
FIXABLE_PENALTY = 10 per issue (unfixed)
WARNING_PENALTY = 2 per issue

READINESS_SCORE = BASE_SCORE - penalties
READINESS_SCORE = max(0, READINESS_SCORE)  # Floor at 0
```

Determine overall status:
```
IF BLOCKING_COUNT > 0:
  STATUS = "BLOCKED"
ELIF FIXABLE_COUNT > 0 AND not fixed:
  STATUS = "NEEDS_FIXES"
ELIF all issues fixed:
  STATUS = "FIXED"
ELSE:
  STATUS = "READY"
```
</step_9_report>

</process>

<output_format>
## PRP Validation Report

**File:** [path to PRP]
**Status:** READY | FIXED | NEEDS_FIXES | BLOCKED

---

### Structure Validation
| Element | Status | Details |
|---------|--------|---------|
| `<prp>` root | PASS/FAIL | |
| `<phases>` | PASS/FAIL | X phases found |
| `<tasks>` | PASS/FAIL | X tasks total |
| `<validation>` | PASS/FAIL | X levels defined |
| `<success-criteria>` | PASS/FAIL | X criteria defined |

### Task Completeness
| Check | Status | Details |
|-------|--------|---------|
| All tasks have IDs | PASS/FAIL | X/Y complete |
| All tasks have agents | PASS/FAIL | X/Y assigned |
| All tasks have effort/value | PASS/FAIL | X/Y ranked |
| All tasks have acceptance criteria | PASS/FAIL | X/Y complete |

### Validation Commands
| Level | Status | Command |
|-------|--------|---------|
| syntax | PASS/FAIL | [command] |
| unit | PASS/FAIL | [command] |
| integration | PASS/FAIL/N/A | [command] |

### Placeholder Check
- Placeholders found: X
- Locations: [list if any]

---

### Issues Summary

**BLOCKING (X):**
- [ ] Issue description with location

**FIXABLE (X):**
- [x] Issue description (FIXED) or
- [ ] Issue description (needs manual fix)

**WARNINGS (X):**
- [ ] Suggestion for improvement

---

### Fixes Applied
1. [Description of fix] at [location]
2. [Description of fix] at [location]

### Remaining Issues
1. [Issue requiring manual intervention]

---

### Readiness Score: XX/100

| Category | Impact |
|----------|--------|
| Structure | +X/-Y |
| Tasks | +X/-Y |
| Validation | +X/-Y |
| Placeholders | +X/-Y |

---

### Verdict

**[STATUS]**

[If READY:]
PRP is ready for execution. Run:
```
/$PLUGIN_NAME:prp-execute [path-to-prp]
```

[If FIXED:]
Issues were auto-fixed. Review changes and run:
```
/$PLUGIN_NAME:prp-execute [path-to-prp]
```

[If NEEDS_FIXES:]
Address remaining issues manually or run with --fix flag:
```
/$PLUGIN_NAME:prp-validate [path-to-prp] --fix
```

[If BLOCKED:]
Critical issues prevent execution. Address these first:
- [List of blocking issues]

Consider regenerating with software-architect skill:
```
/$PLUGIN_NAME:prp-create "[feature description]"
```
</output_format>

<software_architect_integration>
When invoking the software-architect skill for complex fixes:

1. Invoke `/$PLUGIN_NAME:software-architect`
2. Signal intent: "Fix PRP issues" or "Regenerate section"
3. Provide context:
   - Current PRP content
   - Specific issues found
   - What needs regeneration
4. The skill will:
   - Research codebase if needed
   - Generate properly structured content
   - Output the fixed content
5. Apply the fix using Edit tool
6. Continue validation
</software_architect_integration>

<success_criteria>
- All structure elements validated
- All tasks checked for completeness
- Validation commands verified as non-placeholder
- No placeholder text remains
- Simple issues auto-fixed with Edit tool
- Complex issues delegated to software-architect
- Clear pass/fail status reported
- Readiness score calculated
- Actionable next steps provided
</success_criteria>

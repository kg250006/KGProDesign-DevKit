---
description: "[KGP] Pre-flight validation of PRP to ensure all context and dependencies are available before execution"
argument-hint: <path-to-prp.md>
allowed-tools: [Read, Bash, Glob, Grep, WebFetch]
---

<objective>
Validate PRP at $ARGUMENTS before execution to ensure success conditions are met.

This catches missing dependencies, broken URLs, and incomplete context BEFORE you start implementing.
</objective>

<process>

<step_1_load>
**Load PRP**

Read the PRP file:
```
Read: $ARGUMENTS
```

Parse sections:
- Goal and success criteria
- Context (documentation URLs, codebase patterns)
- Implementation tasks
- Validation commands
</step_1_load>

<step_2_file_validation>
**Validate File References**

For each file mentioned in the PRP:
```
Glob: Check if file exists
Read: Verify content matches expected patterns
```

Track:
- Files found: X/Y
- Missing files: [list]
- Changed files: [list if different from expected]
</step_2_file_validation>

<step_3_url_validation>
**Validate URLs**

For each documentation URL:
```
WebFetch: Test accessibility
```

Track:
- URLs accessible: X/Y
- Broken URLs: [list]
- Redirect URLs: [list if redirected]
</step_3_url_validation>

<step_4_dependency_validation>
**Validate Dependencies**

Check required packages/tools:
```bash
# Node.js
npm list [package] 2>/dev/null

# Python
pip show [package] 2>/dev/null

# System tools
which [tool] 2>/dev/null
```

Track:
- Dependencies available: X/Y
- Missing: [list]
</step_4_dependency_validation>

<step_5_environment_validation>
**Validate Environment**

Check for required:
- Environment variables
- API keys (existence, not values)
- External service connectivity

```bash
# Check env vars
echo $REQUIRED_VAR

# Test connectivity
curl -s -o /dev/null -w "%{http_code}" https://api.example.com/health
```
</step_5_environment_validation>

<step_6_completeness_validation>
**Validate PRP Completeness**

Check for:
- [ ] Goal is specific and measurable
- [ ] Success criteria are testable
- [ ] All tasks have clear descriptions
- [ ] Validation commands are provided
- [ ] No TODO/TBD markers remaining
</step_6_completeness_validation>

<step_7_risk_assessment>
**Risk Assessment**

Identify potential issues:
- Complexity score (1-10)
- Known failure patterns
- External dependencies that could fail
</step_7_risk_assessment>

</process>

<output_format>
## PRP Validation Report

**File:** $ARGUMENTS
**Status:** READY | NEEDS_ATTENTION | BLOCKED

### Context Validation
| Check | Status | Details |
|-------|--------|---------|
| Files referenced | X/X found | |
| URLs accessible | X/X responding | |
| Examples current | YES/NO | |

### Dependencies
| Check | Status | Details |
|-------|--------|---------|
| Packages | X/X available | |
| External services | X/X accessible | |
| API keys | X/X configured | |

### Completeness
- Goal specific: YES/NO
- Criteria testable: YES/NO
- Tasks clear: YES/NO
- Validation defined: YES/NO

### Risk Assessment
- **Complexity:** X/10
- **Failure patterns:** X identified
- **External risks:** [list]

### Readiness Score: XX/100

### Recommended Actions
- [ ] Action 1 to address issue
- [ ] Action 2 to address issue

### Verdict
[READY: Proceed with `/prp-execute`]
[NEEDS_ATTENTION: Address issues first]
[BLOCKED: Cannot proceed until resolved]
</output_format>

<success_criteria>
- Readiness score >= 80 for execution
- No BLOCKED dependencies
- All file references valid
- PRP sections complete
</success_criteria>

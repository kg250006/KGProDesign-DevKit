---
description: "[KGP] Execute a PRP file with full validation and iterative refinement at each step"
argument-hint: <path-to-prp.md>
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebSearch, TodoWrite]
---

<objective>
Implement feature using PRP at: $ARGUMENTS

Execute with discipline:
1. Follow the PRP exactly
2. Validate at each step
3. Fix failures before proceeding
4. Report completion status
</objective>

<process>

<step_1_load>
**Load PRP**

Read the specified PRP file completely:
```
Read: $ARGUMENTS
```

Extract and understand:
- Goal and success criteria
- Implementation tasks
- Validation commands
- Context and patterns
</step_1_load>

<step_2_preflight>
**Pre-flight Check**

Verify all prerequisites:
- [ ] Referenced files exist
- [ ] Dependencies are available
- [ ] External URLs accessible (if needed)
- [ ] No blocking issues

If pre-flight fails, report issues before proceeding.
</step_2_preflight>

<step_3_plan>
**Plan Execution**

Use TodoWrite to create task list from PRP:
```
For each task in Implementation Blueprint:
- Create todo item
- Mark dependencies
- Set initial status
```
</step_3_plan>

<step_4_execute>
**Execute Tasks**

For each task:
1. Mark task as in_progress
2. Read relevant files
3. Implement following PRP guidance
4. Use patterns specified in context
5. Run Level 1 validation (lint/types)
6. Fix any failures
7. Mark task complete

**Validation Protocol (per task):**
```bash
# Level 1: Syntax
npm run lint 2>/dev/null || ruff check --fix 2>/dev/null
npm run typecheck 2>/dev/null || mypy . 2>/dev/null
```

If validation fails:
1. Read error message completely
2. Understand root cause
3. Fix the issue
4. Re-run validation
5. Only proceed when passing
</step_4_execute>

<step_5_validate>
**Final Validation**

Run complete validation loop from PRP:

Level 1: Syntax & Style
```bash
[Commands from PRP]
```

Level 2: Unit Tests
```bash
[Commands from PRP]
```

Level 3: Integration Tests
```bash
[Commands from PRP]
```
</step_5_validate>

<step_6_checklist>
**Complete Checklist**

Go through Final Checklist from PRP:
- [ ] Each success criterion met
- [ ] All validation levels pass
- [ ] No regressions

Re-read PRP to verify completeness.
</step_6_checklist>

<step_7_report>
**Report Status**

Provide execution report.
</step_7_report>

</process>

<output_format>
## PRP Execution Report

### PRP: [name]
### Status: COMPLETE | PARTIAL | BLOCKED

### Tasks Completed
- [x] Task 1 - Brief description
- [x] Task 2 - Brief description
- [ ] Task 3 (if incomplete: reason)

### Validation Results
| Level | Status | Details |
|-------|--------|---------|
| Syntax/Lint | PASS/FAIL | |
| Types | PASS/FAIL | |
| Unit Tests | X/Y passing | |
| Integration | PASS/FAIL | |

### Files Modified
- `path/to/file1.ts` - [what changed]
- `path/to/file2.ts` - [what changed]

### Success Criteria
- [x] Criterion 1
- [x] Criterion 2
- [ ] Criterion 3 (if not met: why)

### Notes
[Any deviations, discoveries, or issues]

### Next Steps
[If partial: what remains]
[If complete: suggested follow-up]
</output_format>

<success_criteria>
- All PRP checklist items completed
- All validation gates passing
- No regressions in existing tests
- Implementation matches PRP specifications
</success_criteria>

<objective>
Update the `/prp-validate` command at `commands/dev/prp-validate.md` to validate PRPs specifically for Ralph Loop compatibility and automatically fix issues using the software-architect skill.

The updated command should:
1. Validate PRP structure matches what Ralph Loop expects (XML with phases, tasks, validation)
2. Check that all task attributes are present (id, agent, effort, value, acceptance-criteria)
3. Verify validation commands exist and are executable
4. Identify and FIX inconsistencies using the software-architect skill rather than just reporting them
5. Ensure the PRP can be executed without errors by /prp-execute

This matters because Ralph Loop requires well-structured PRPs with all fields populated. Validation catches issues before wasting iterations on incomplete specs.
</objective>

<context>
Read and understand these files:
- @commands/dev/prp-validate.md (current implementation to update)
- @skills/software-architect/SKILL.md (skill for fixing PRPs)
- @skills/software-architect/templates/prp-template.md (expected PRP structure)
- @skills/software-architect/references/prp-best-practices.md (quality standards)
- @commands/ralph-loop.md (consumer requirements)
- @commands/dev/prp-execute.md (how PRPs are fed to Ralph Loop)

**Ralph Loop PRP requirements:**
- XML structure with `<prp>`, `<phases>`, `<phase>`, `<tasks>`, `<task>` tags
- Each task needs: id, agent, effort, value attributes
- Each task needs: description, files, acceptance-criteria children
- `<validation>` section with executable commands
- `<success-criteria>` section for completion detection
- No placeholder text (TODO, TBD, [placeholder])

**Software-architect skill capabilities:**
- Can regenerate missing sections of PRPs
- Can add missing task attributes
- Can improve vague acceptance criteria
- Can add missing validation commands
</context>

<requirements>

<validation_checks>
The command should validate these aspects:

**1. Structure Validation:**
- PRP has root `<prp>` tag with name attribute
- Contains `<phases>` with at least one `<phase>`
- Each phase has `<tasks>` with at least one `<task>`
- Has `<validation>` section
- Has `<success-criteria>` section

**2. Task Completeness:**
For each `<task>`:
- Has id attribute (format: "N.N" like "1.1", "2.3")
- Has agent attribute (one of: backend-engineer, frontend-engineer, data-engineer, qa-engineer, devops-engineer, document-specialist)
- Has effort attribute (S, M, L, or XL)
- Has value attribute (H, M, or L)
- Has `<description>` child with non-empty text
- Has `<acceptance-criteria>` with at least one `<criterion>`

**3. Validation Commands:**
- Has at least one validation level (syntax, unit, or integration)
- Commands are non-empty strings
- Commands don't contain placeholders

**4. No Placeholders:**
- No TODO, TBD, [placeholder], or similar markers anywhere
- No "..." or "[...]" patterns
- All file paths are specific (not "path/to/file.ts")

**5. Handoff Completeness (optional but recommended):**
- Tasks have `<handoff>` with `<expects>` and `<produces>`
</validation_checks>

<auto_fix_workflow>
When issues are found:

1. **Categorize issues by severity:**
   - BLOCKING: Missing structure, no tasks, no validation
   - FIXABLE: Missing attributes, vague criteria, placeholders
   - WARNING: Missing handoffs, suboptimal effort/value rankings

2. **For BLOCKING issues:**
   - Report issue clearly
   - Invoke software-architect skill to regenerate the section
   - The skill will ask clarifying questions if needed

3. **For FIXABLE issues:**
   - Attempt automatic fix using patterns from prp-best-practices.md
   - For missing agent: Infer from task description
   - For missing effort/value: Default to M/M and flag for review
   - For vague criteria: Rewrite to be specific

4. **For WARNINGS:**
   - Report but don't block
   - Suggest improvements

5. **After all fixes:**
   - Revalidate the PRP
   - Report final status
</auto_fix_workflow>

<software_architect_integration>
When fixes require context or decisions:

1. Load @skills/software-architect/SKILL.md
2. Describe the specific issue needing fix
3. Let the skill's workflow handle the regeneration
4. The skill will:
   - Research codebase if needed
   - Ask clarifying questions
   - Generate properly structured content
   - Update the PRP file
</software_architect_integration>

</requirements>

<implementation>

**Command frontmatter to update:**
```yaml
---
description: "[KGP] Validate PRP for Ralph Loop compatibility and auto-fix issues using software-architect skill"
argument-hint: <path-to-prp.md> [--fix] [--strict]
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, AskUserQuestion]
---
```

**Options:**
- `--fix` (default behavior): Attempt to fix issues automatically
- `--strict`: Fail on any warning, not just blocking issues
- No flag: Validate and report, prompt before fixing

**Logic structure:**
```xml
<process>
<step_1_load_prp>
Read PRP file from $ARGUMENTS
Parse to identify XML structure
Extract all sections for validation
</step_1_load_prp>

<step_2_structure_validation>
Check for required top-level elements:
- <prp> root with name attribute
- <phases> container
- <validation> section
- <success-criteria> section

Report: PASS/FAIL for each
</step_2_structure_validation>

<step_3_task_validation>
For each task in each phase:
- Check all required attributes
- Check all required children
- Identify missing or placeholder content

Build list of issues with task IDs
</step_3_task_validation>

<step_4_validation_commands_check>
For each validation level:
- Verify command exists
- Check command is not placeholder
- Optionally: Test command executability with dry-run

Report: PASS/FAIL for validation section
</step_4_validation_commands_check>

<step_5_fix_issues>
IF issues found AND (--fix flag OR user confirms):
  For each issue:
    IF simple fix (missing attribute):
      Apply fix directly with Edit tool
    ELSE (needs context):
      Invoke software-architect skill

  Revalidate after fixes
ELSE:
  Report issues without fixing
</step_5_fix_issues>

<step_6_report>
Output validation report with:
- Overall status: READY / NEEDS_FIXES / FIXED
- Issues found and fixed
- Remaining issues if any
- Readiness score for Ralph Loop
- Next step recommendation
</step_6_report>
</process>
```

**Example fixes:**
```xml
<!-- Missing agent - infer from description -->
<task id="1.1" effort="M" value="H">
  <description>Create API endpoint for users</description>
</task>
<!-- Fix: Add agent="backend-engineer" -->

<!-- Vague criteria - make specific -->
<criterion>Feature works correctly</criterion>
<!-- Fix: Rewrite based on task description -->
<criterion>GET /api/users returns 200 with array of user objects</criterion>

<!-- Placeholder path - needs context -->
<file action="create">path/to/service.ts</file>
<!-- Fix: Invoke software-architect to determine actual path -->
```
</implementation>

<output>
Save the updated command to: `./commands/dev/prp-validate.md`

The file should completely replace the existing content with the Ralph Loop validation and auto-fix workflow.
</output>

<verification>
After updating, verify:
1. Command file exists at commands/dev/prp-validate.md
2. Command validates all required PRP elements
3. Command categorizes issues by severity
4. Command can auto-fix simple issues with Edit tool
5. Command invokes software-architect for complex fixes
6. Command reports clear validation status
7. Command provides readiness score for Ralph Loop
</verification>

<success_criteria>
- Updated command validates full PRP XML structure
- Detects all categories of issues (structure, tasks, validation, placeholders)
- Automatically fixes simple issues without user intervention
- Invokes software-architect skill for complex issues
- Reports clear pass/fail status with details
- Provides actionable next steps
- PRPs passing validation can be executed by /prp-execute without errors
</success_criteria>

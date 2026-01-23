# PRP Template

Use this template structure when generating PRPs. Copy and fill in all sections.

```xml
<prp name="[feature-name]" version="1.0">

<metadata>
  <created>[YYYY-MM-DD]</created>
  <author>software-architect skill</author>
  <target-branch>main</target-branch>
  <estimated-effort>[S|M|L|XL]</estimated-effort>
  <confidence-score>[1-10]</confidence-score>
</metadata>

<goal>
[Specific, measurable end state. What exists when this PRP is complete?]
</goal>

<context>
  <business-value>
    [Why this matters. Business impact, user benefit, problems solved.]
  </business-value>

  <prerequisites>
    <prerequisite>[Dependency or setup required before starting]</prerequisite>
  </prerequisites>

  <out-of-scope>
    <item>[Explicitly excluded functionality]</item>
  </out-of-scope>
</context>

<codebase-analysis>
  <existing-patterns>
    <pattern file="[path/to/file.ts]" usage="[What to copy/follow]"/>
  </existing-patterns>

  <affected-files>
    <file action="modify" path="[src/path/file.ts]" reason="[Why modifying]"/>
    <file action="create" path="[src/path/new-file.ts]" reason="[What it contains]"/>
  </affected-files>

  <dependencies>
    <dependency name="[package-name]" version="[^1.0.0]" purpose="[Why needed]"/>
  </dependencies>

  <gotchas>
    <gotcha>[Known issue or quirk to watch for]</gotcha>
  </gotchas>
</codebase-analysis>

<phases>

  <phase id="1" name="Foundation">
    <description>[What this phase accomplishes]</description>

    <tasks>
      <task id="1.1" agent="[agent-type]" effort="[S|M|L|XL]" value="[H|M|L]" timeout="[default|extended]">
        <description>[Clear, actionable description of what to do]</description>

        <files>
          <file action="[create|modify|delete]">[path/to/file.ts]</file>
        </files>

        <pseudocode>
// Follow pattern from [existing file]
// Key implementation details:
[Pseudocode matching project style]
        </pseudocode>

        <acceptance-criteria>
          <criterion>[Specific, verifiable outcome]</criterion>
          <criterion>[Another verifiable outcome]</criterion>
        </acceptance-criteria>

        <handoff>
          <expects>[What this task needs from previous tasks]</expects>
          <produces>[What this task provides to next tasks]</produces>
        </handoff>
      </task>

      <task id="1.2" agent="[agent-type]" effort="[S|M|L|XL]" value="[H|M|L]">
        <!-- Repeat structure -->
      </task>
    </tasks>
  </phase>

  <phase id="2" name="Core Implementation">
    <description>[What this phase accomplishes]</description>
    <tasks>
      <!-- Tasks for this phase -->
    </tasks>
  </phase>

  <phase id="3" name="Integration">
    <description>[What this phase accomplishes]</description>
    <tasks>
      <!-- Tasks for this phase -->
    </tasks>
  </phase>

  <phase id="4" name="Testing & Validation">
    <description>[What this phase accomplishes]</description>
    <tasks>
      <!-- Test implementation tasks -->
    </tasks>
  </phase>

</phases>

<validation>
  <level name="syntax" run-after="each-task">
    <command>[lint command for this project]</command>
    <command>[typecheck command for this project]</command>
  </level>

  <level name="unit" run-after="phase">
    <command>[unit test command]</command>
  </level>

  <level name="integration" run-after="all">
    <command>[integration test command]</command>
    <command>[build command]</command>
  </level>
</validation>

<success-criteria>
  <criterion priority="P0">[Must be true for completion]</criterion>
  <criterion priority="P0">[Another must-have]</criterion>
  <criterion priority="P1">[Should be true]</criterion>
</success-criteria>

<anti-patterns>
  <avoid>[Pattern to avoid during implementation]</avoid>
  <avoid>[Another pattern to avoid]</avoid>
</anti-patterns>

</prp>
```

## Agent Types Reference

| Agent | Use For |
|-------|---------|
| backend-engineer | API, services, business logic, auth |
| frontend-engineer | UI, components, state, styling |
| data-engineer | Schema, migrations, queries |
| qa-engineer | Tests, security review |
| devops-engineer | CI/CD, infrastructure |
| document-specialist | Documentation |

## Effort Sizing Reference

| Size | Time | Complexity |
|------|------|------------|
| S | < 15 min | Single file, clear pattern |
| M | 15-30 min | 2-3 files, some decisions |
| L | 30-60 min | Multiple files, new patterns |
| XL | 1+ hours | Significant complexity |

## Value Ranking Reference

| Value | Meaning |
|-------|---------|
| H | Core functionality, blocking, user-facing |
| M | Important, not blocking, enhances experience |
| L | Nice to have, polish, optimization |

## Timeout Reference

| Timeout | When to Use |
|---------|-------------|
| default | Standard tasks (300s) |
| extended | Test execution, E2E tests, builds, large codebases (600s) |

**Tasks that should use `timeout="extended"`:**
- Running test suites (`npm test`, `pytest`, `jest`)
- E2E/integration tests (`playwright`, `cypress`)
- Build commands (`npm run build`, `cargo build`)
- Database migrations with large datasets
- Any task running multiple test files

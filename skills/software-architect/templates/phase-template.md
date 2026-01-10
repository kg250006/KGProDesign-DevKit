# Phase Template

Use this template for defining phases within a PRP.

```xml
<phase id="[N]" name="[Phase Name]">
  <description>
    [What this phase accomplishes. What state is the codebase in after this phase completes?]
  </description>

  <entry-criteria>
    <criterion>[What must be true before starting this phase]</criterion>
    <criterion>[Previous phase completion or external dependency]</criterion>
  </entry-criteria>

  <tasks>
    <task id="[N.1]" agent="[agent-type]" effort="[S|M|L|XL]" value="[H|M|L]">
      <description>[Clear, actionable task description]</description>

      <files>
        <file action="[create|modify|delete]">[path/to/file]</file>
      </files>

      <pseudocode>
[Implementation hints matching project style]
      </pseudocode>

      <acceptance-criteria>
        <criterion>[Verifiable outcome]</criterion>
      </acceptance-criteria>

      <handoff>
        <expects>[Input from previous task]</expects>
        <produces>[Output for next task]</produces>
      </handoff>
    </task>

    <task id="[N.2]" agent="[agent-type]" effort="[S|M|L|XL]" value="[H|M|L]">
      <!-- Repeat structure -->
    </task>
  </tasks>

  <exit-criteria>
    <criterion>[What must be true when phase is complete]</criterion>
    <criterion>[Validation that passed]</criterion>
  </exit-criteria>

  <validation>
    <command>[Validation command to run after phase]</command>
  </validation>
</phase>
```

## Common Phase Patterns

### Phase 1: Foundation
```xml
<phase id="1" name="Foundation">
  <description>
    Setup dependencies, types, and infrastructure for the feature.
  </description>
  <tasks>
    <!-- Typical tasks: -->
    <!-- - Install/configure dependencies -->
    <!-- - Create type definitions -->
    <!-- - Database schema/migrations -->
    <!-- - Configuration changes -->
  </tasks>
</phase>
```

### Phase 2: Core Implementation
```xml
<phase id="2" name="Core Implementation">
  <description>
    Build the main business logic and data layer.
  </description>
  <tasks>
    <!-- Typical tasks: -->
    <!-- - Service layer -->
    <!-- - Repository/data access -->
    <!-- - Core business logic -->
    <!-- - Validation layer -->
  </tasks>
</phase>
```

### Phase 3: API Layer
```xml
<phase id="3" name="API Layer">
  <description>
    Expose functionality through API endpoints.
  </description>
  <tasks>
    <!-- Typical tasks: -->
    <!-- - Route definitions -->
    <!-- - Request handlers -->
    <!-- - Request/response schemas -->
    <!-- - Error handling -->
  </tasks>
</phase>
```

### Phase 4: Frontend
```xml
<phase id="4" name="Frontend">
  <description>
    Build user interface components.
  </description>
  <tasks>
    <!-- Typical tasks: -->
    <!-- - UI components -->
    <!-- - State management -->
    <!-- - Form handling -->
    <!-- - API integration -->
  </tasks>
</phase>
```

### Phase 5: Integration
```xml
<phase id="5" name="Integration">
  <description>
    Wire up components and complete end-to-end flows.
  </description>
  <tasks>
    <!-- Typical tasks: -->
    <!-- - Connect frontend to backend -->
    <!-- - Wire up navigation/routing -->
    <!-- - Add error boundaries -->
    <!-- - Integration configuration -->
  </tasks>
</phase>
```

### Phase 6: Testing & Polish
```xml
<phase id="6" name="Testing & Polish">
  <description>
    Comprehensive testing and final refinements.
  </description>
  <tasks>
    <!-- Typical tasks: -->
    <!-- - Unit tests -->
    <!-- - Integration tests -->
    <!-- - E2E tests -->
    <!-- - Documentation -->
    <!-- - Performance optimization -->
  </tasks>
</phase>
```

## Phase Dependencies

Phases should be sequential with clear handoffs:

```
Phase 1 (Foundation)
    ↓
Phase 2 (Core) ← depends on types/schema from Phase 1
    ↓
Phase 3 (API) ← depends on services from Phase 2
    ↓
Phase 4 (Frontend) ← depends on API from Phase 3
    ↓
Phase 5 (Integration) ← depends on all previous
    ↓
Phase 6 (Testing) ← tests everything
```

For parallel work, note it in the phase description:
```xml
<description>
  This phase can run in parallel with Phase 4 (Frontend).
  No dependencies between them.
</description>
```

# Workflow: Convert PRD to PRP

<objective>
Transform a codebase-agnostic PRD into a codebase-specific PRP that can be executed by Ralph Loop. This bridges the gap between specification and implementation by mapping abstract requirements to concrete tasks in the current codebase.
</objective>

<required_reading>
Before converting, read these references:
- @references/prp-best-practices.md
- @references/effort-estimation.md
</required_reading>

<process>

<step_1_load_prd>
**Load and Parse PRD**

Read the specified PRD file:
```
Read: [PRD path provided by user]
```

Extract key elements:
- Functional requirements (what the system must do)
- Non-functional requirements (performance, security, etc.)
- Data models and entity relationships
- API contracts (endpoints, schemas)
- Edge cases and error handling
- Success metrics

Create a mental map of requirements to implementation tasks.
</step_1_load_prd>

<step_2_analyze_codebase>
**Deep Codebase Analysis**

Map PRD requirements to existing code:

```
Glob: Find files matching PRD entity names
Grep: Search for related functionality
Read: Examine existing implementations
```

For each PRD requirement, identify:
- **Existing code to modify** (extend existing features)
- **Patterns to follow** (how similar things are done)
- **New code to create** (following conventions)
- **Dependencies needed** (packages, services)

Build a mapping table:
```
| PRD Requirement | Implementation Approach | Files Affected |
|-----------------|-------------------------|----------------|
| F1: User Auth   | Extend auth middleware  | src/auth/*.ts  |
| F2: Data Export | New service, follow patterns | src/services/export.ts |
```
</step_2_analyze_codebase>

<step_3_map_requirements>
**Map Requirements to Tasks**

Convert each PRD requirement into concrete implementation tasks:

**For each Functional Requirement:**
1. Identify files to modify/create
2. Determine agent assignment
3. Write specific pseudocode
4. Define file-level acceptance criteria

**For each Non-Functional Requirement:**
1. Identify implementation approach
2. Add validation/test tasks
3. Include in appropriate phase

**For each API Contract:**
1. Create endpoint implementation task
2. Create request validation task
3. Create response formatting task
4. Create test task

**For each Data Model:**
1. Create schema/migration task
2. Create repository/service task
3. Create validation task
</step_3_map_requirements>

<step_4_structure_phases>
**Structure into Phases**

Organize tasks into logical implementation phases:

**Phase 1: Foundation**
- Database schema changes
- Type definitions
- Configuration
- Dependencies

**Phase 2: Core Backend**
- Services and business logic
- Repository layer
- Validation layer

**Phase 3: API Layer**
- Endpoint handlers
- Request/response handling
- Error responses

**Phase 4: Frontend (if applicable)**
- Components
- State management
- Forms and validation

**Phase 5: Integration**
- Wire up components
- End-to-end flows
- Documentation

**Phase 6: Testing & Polish**
- Unit tests
- Integration tests
- Edge case handling
- Performance optimization

Adjust phases based on project structure and feature scope.
</step_4_structure_phases>

<step_5_add_details>
**Add Implementation Details**

For each task, enhance with codebase-specific information:

```xml
<task id="1.1" agent="backend-engineer" effort="M" value="H">
  <description>Implement user service with CRUD operations</description>

  <!-- Specific files from this codebase -->
  <files>
    <file action="create">src/services/user-service.ts</file>
    <file action="modify">src/services/index.ts</file>
  </files>

  <!-- Pseudocode following THIS project's patterns -->
  <pseudocode>
// Follow pattern from src/services/product-service.ts
import { UserRepository } from '../repositories/user-repository';
import { CreateUserDTO, UpdateUserDTO } from '../types/user';

export class UserService {
  constructor(private repo: UserRepository) {}

  async create(dto: CreateUserDTO): Promise<User> {
    // Validate using existing validator pattern
    await this.validate(dto);
    // Use repository pattern like other services
    return this.repo.create(dto);
  }
}
  </pseudocode>

  <!-- Verifiable acceptance criteria -->
  <acceptance-criteria>
    <criterion>UserService class exists with create, read, update, delete methods</criterion>
    <criterion>Service is exported from src/services/index.ts</criterion>
    <criterion>TypeScript compiles without errors</criterion>
  </acceptance-criteria>

  <!-- Link to original PRD requirement -->
  <traces>
    <prd-requirement ref="F1">User Account Management</prd-requirement>
  </traces>
</task>
```
</step_5_add_details>

<step_6_add_validation>
**Add Project-Specific Validation**

Configure validation commands for this project's toolchain:

```xml
<validation>
  <level name="syntax" run-after="each-task">
    <!-- Detected from package.json or equivalent -->
    <command>npm run lint -- --fix</command>
    <command>npm run typecheck</command>
  </level>

  <level name="unit" run-after="phase">
    <command>npm test -- --coverage --passWithNoTests</command>
  </level>

  <level name="integration" run-after="all">
    <command>npm run test:e2e</command>
    <command>npm run build</command>
  </level>
</validation>
```

Detect the actual tools from:
- package.json scripts
- pyproject.toml
- Makefile
- CI configuration
</step_6_add_validation>

<step_7_add_traceability>
**Add Requirement Traceability**

Link every task back to its source requirement:

```xml
<traceability>
  <mapping>
    <prd-requirement id="F1">
      <tasks>1.1, 1.2, 2.1, 3.1, 3.2</tasks>
    </prd-requirement>
    <prd-requirement id="F2">
      <tasks>2.2, 2.3, 3.3</tasks>
    </prd-requirement>
  </mapping>

  <coverage>
    <covered>F1, F2, F3, NF1, NF2</covered>
    <not-covered reason="future">F4, F5</not-covered>
  </coverage>
</traceability>
```

This ensures:
- Every PRD requirement has implementing tasks
- Tasks trace back to business value
- Gaps are explicitly acknowledged
</step_7_add_traceability>

<step_8_generate>
**Generate PRP Document**

Use @templates/prp-template.md but include:
- Reference to source PRD
- Traceability matrix
- Coverage report

```xml
<prp name="feature-name" version="1.0">
  <source>
    <prd path="PRDs/PRD-feature-name.md" version="1.0"/>
    <generated>YYYY-MM-DD</generated>
  </source>

  <!-- Rest of PRP structure -->
</prp>
```
</step_8_generate>

<step_9_save>
**Save and Link**

```bash
# Create directory if needed
mkdir -p PRPs

# Save PRP
Write: PRPs/PRP-{feature-name}.md
```

Report conversion summary with traceability coverage.
</step_9_save>

</process>

<output_format>
## PRP Generated from PRD

**Source PRD:** `PRDs/PRD-{feature-name}.md`
**Generated PRP:** `PRPs/PRP-{feature-name}.md`

**Conversion Summary:**
- Functional Requirements Mapped: X/Y (Z%)
- Non-Functional Requirements Mapped: A/B
- Total Tasks Generated: N across M phases
- Agent Distribution: [backend: X, frontend: Y, ...]

**Traceability Matrix:**
| Requirement | Tasks | Coverage |
|-------------|-------|----------|
| F1 | 1.1, 1.2, 2.1 | Full |
| F2 | 2.2, 3.1 | Full |
| NF1 | 5.1 | Partial |

**Deferred to Future:**
- F4: Out of scope for MVP
- F5: Requires external integration not available

**Execute with:**
```bash
/$PLUGIN_NAME:ralph-loop PRPs/PRP-{feature-name}.md
```
</output_format>

<success_criteria>
- Every PRD requirement maps to at least one task
- Traceability matrix is complete
- Implementation uses actual codebase patterns
- Validation commands work in this project
- Coverage gaps are explicitly documented
</success_criteria>

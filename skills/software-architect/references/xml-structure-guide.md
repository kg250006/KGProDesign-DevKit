# XML Structure Guide

<purpose>
Guidelines for using XML tags in PRPs and PRDs to enable machine parsing and maintain consistency.
</purpose>

<why_xml>

## Why XML Structure?

### 1. Machine Parseable
Ralph Loop and other tools can reliably extract:
- Task lists with IDs
- Agent assignments
- Acceptance criteria
- Validation commands

### 2. Claude-Optimized
Claude was trained with XML in its training data. Structured prompts with XML tags produce more consistent outputs.

### 3. Human Readable
Unlike JSON, XML with proper indentation is easy to read and edit.

### 4. Self-Documenting
Tag names describe content: `<acceptance-criteria>` is clearer than `"ac": []`

</why_xml>

<conventions>

## Tag Naming Conventions

### Use Lowercase with Hyphens
```xml
<!-- Good -->
<acceptance-criteria>
<user-story>
<api-contract>

<!-- Bad -->
<AcceptanceCriteria>
<user_story>
<apiContract>
```

### Use Semantic Names
```xml
<!-- Good: Describes what it contains -->
<prerequisites>
<success-metrics>
<edge-cases>

<!-- Bad: Too generic -->
<data>
<items>
<list>
```

### Consistent Pluralization
```xml
<!-- Container uses plural -->
<phases>
  <!-- Items use singular -->
  <phase id="1">
</phases>

<tasks>
  <task id="1.1">
</tasks>
```

</conventions>

<common_patterns>

## Common XML Patterns

### Lists with IDs

```xml
<tasks>
  <task id="1.1" agent="backend-engineer" effort="M" value="H">
    <description>Create user service</description>
  </task>
  <task id="1.2" agent="backend-engineer" effort="S" value="H">
    <description>Add unit tests</description>
  </task>
</tasks>
```

### Nested Structures

```xml
<phases>
  <phase id="1" name="Foundation">
    <description>Setup and dependencies</description>
    <tasks>
      <task id="1.1">...</task>
    </tasks>
  </phase>
</phases>
```

### Key-Value Pairs

```xml
<metadata>
  <created>2024-01-15</created>
  <author>software-architect</author>
  <status>draft</status>
</metadata>
```

### File References

```xml
<files>
  <file action="create" path="src/services/user-service.ts"/>
  <file action="modify" path="src/api/routes.ts"/>
</files>
```

### Acceptance Criteria

```xml
<acceptance-criteria>
  <criterion id="AC1">User can login with email and password</criterion>
  <criterion id="AC2">Invalid credentials show error message</criterion>
</acceptance-criteria>
```

### Requirements with Dependencies

```xml
<requirement id="F3" priority="P0">
  <title>Password Reset</title>
  <description>...</description>
  <dependencies>
    <dependency ref="F1">User registration</dependency>
    <dependency ref="NF2">Email service</dependency>
  </dependencies>
</requirement>
```

</common_patterns>

<prp_structure>

## PRP XML Structure

```xml
<prp name="feature-name" version="1.0">
  <metadata>...</metadata>
  <goal>...</goal>
  <context>...</context>
  <codebase-analysis>...</codebase-analysis>
  <phases>
    <phase id="N" name="Phase Name">
      <tasks>
        <task id="N.M" agent="..." effort="..." value="...">
          <description>...</description>
          <files>...</files>
          <pseudocode>...</pseudocode>
          <acceptance-criteria>...</acceptance-criteria>
          <handoff>...</handoff>
        </task>
      </tasks>
    </phase>
  </phases>
  <validation>...</validation>
  <success-criteria>...</success-criteria>
</prp>
```

### Required Attributes

| Element | Attribute | Values |
|---------|-----------|--------|
| prp | name | kebab-case identifier |
| prp | version | semver (1.0, 1.1, etc) |
| phase | id | sequential number (1, 2, 3) |
| phase | name | human-readable name |
| task | id | phase.task (1.1, 1.2, 2.1) |
| task | agent | agent type from allowed list |
| task | effort | S, M, L, XL |
| task | value | H, M, L |
| file | action | create, modify, delete |
| file | path | relative file path |

</prp_structure>

<prd_structure>

## PRD XML Structure

```xml
<prd name="feature-name" version="1.0">
  <metadata>...</metadata>
  <executive-summary>
    <problem>...</problem>
    <solution>...</solution>
    <success-metrics>...</success-metrics>
    <scope>...</scope>
  </executive-summary>
  <user-stories>
    <story id="US1" priority="P0" persona="...">
      <narrative>...</narrative>
      <acceptance-criteria>...</acceptance-criteria>
      <edge-cases>...</edge-cases>
    </story>
  </user-stories>
  <requirements>
    <functional>
      <requirement id="F1" priority="P0" category="...">...</requirement>
    </functional>
    <non-functional>
      <requirement id="NF1" category="...">...</requirement>
    </non-functional>
  </requirements>
  <technical-design>
    <data-model>...</data-model>
    <api-contracts>...</api-contracts>
    <integrations>...</integrations>
  </technical-design>
  <edge-cases>...</edge-cases>
</prd>
```

### Required Attributes

| Element | Attribute | Values |
|---------|-----------|--------|
| prd | name | kebab-case identifier |
| prd | version | semver |
| story | id | US1, US2, etc |
| story | priority | P0, P1, P2, P3 |
| story | persona | user type |
| requirement | id | F1, F2 (functional) or NF1, NF2 (non-functional) |
| requirement | priority | P0, P1, P2, P3 |
| requirement | category | core, integration, performance, security, etc |

</prd_structure>

<markdown_in_xml>

## Markdown Within XML

Use markdown for content formatting within XML elements:

```xml
<description>
Create the **UserService** class with the following methods:

- `create(input: CreateUserInput): Promise<User>`
- `findById(id: string): Promise<User | null>`
- `update(id: string, input: UpdateUserInput): Promise<User>`

Follow patterns from `src/services/base-service.ts`.
</description>

<pseudocode>
```typescript
// Follow pattern from existing services
export class UserService extends BaseService<User> {
  async create(input: CreateUserInput): Promise<User> {
    // Validate input
    // Create entity
    // Return result
  }
}
```
</pseudocode>
```

### What Works
- Bold, italic, strikethrough
- Bullet and numbered lists
- Code blocks with language hints
- Links (for documentation references)
- Horizontal rules

### What to Avoid
- Headers (use XML structure instead)
- Tables (use XML `<table>` or lists)
- Complex nesting

</markdown_in_xml>

<validation>

## XML Validation Tips

### 1. Balance Tags
Every opening tag needs a closing tag:
```xml
<task id="1.1">
  <description>...</description>
</task>  <!-- Don't forget this -->
```

### 2. Escape Special Characters
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`

Or use CDATA for code blocks:
```xml
<pseudocode><![CDATA[
if (x < 10 && y > 5) {
  return true;
}
]]></pseudocode>
```

### 3. Attribute Quoting
Always use double quotes:
```xml
<task id="1.1" agent="backend-engineer">
```

### 4. Consistent Indentation
Use 2 spaces for readability:
```xml
<phase id="1">
  <tasks>
    <task id="1.1">
      <description>...</description>
    </task>
  </tasks>
</phase>
```

</validation>

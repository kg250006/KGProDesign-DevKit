---
description: "[KGP] Generate a comprehensive Product Requirement Prompt from feature requirements with research and context"
argument-hint: <feature description or requirements file>
allowed-tools: [Read, Write, Glob, Grep, WebSearch, WebFetch, AskUserQuestion]
---

<objective>
Generate a complete PRP (Product Requirement Prompt) for: $ARGUMENTS

A PRP provides ALL context needed for one-pass implementation success. The goal is comprehensive context so the executing agent can implement without ambiguity.
</objective>

<context>
Check for existing PRPs: !`ls PRPs/active/ PRPs/completed/ 2>/dev/null | head -10`
Project structure: !`find . -maxdepth 2 -type d | grep -v node_modules | head -20`
</context>

<process>

<step_1_clarify>
**Clarify Requirements**

If $ARGUMENTS is vague, use AskUserQuestion to gather:
- What specific functionality is needed?
- Who will use this feature?
- What are the acceptance criteria?
- Are there any constraints or dependencies?
</step_1_clarify>

<step_2_research_codebase>
**Research Codebase**

Search for related patterns:
```
Glob: Find similar features/implementations
Grep: Search for related code patterns
Read: Examine key files that will be affected
```

Document:
- Existing patterns to follow
- Files that need modification
- Dependencies to consider
</step_2_research_codebase>

<step_3_research_external>
**External Research**

If the feature involves external libraries or APIs:
- Search documentation
- Find implementation examples
- Note common pitfalls
- Include relevant URLs in context
</step_3_research_external>

<step_4_generate_prp>
**Generate PRP**

Create PRP following this structure:

```markdown
# PRP: [Feature Name]

## Goal
[Specific end state to achieve - what should exist when done]

## Why
[Business value, user impact, problems solved]

## What
[User-visible behavior and technical requirements]

## Success Criteria
- [ ] Specific measurable outcome 1
- [ ] Specific measurable outcome 2
- [ ] Specific measurable outcome 3

## Context

### Documentation
- [URL 1]: Relevant section
- [URL 2]: Relevant section

### Codebase Patterns
- `path/to/file.ts`: Pattern to follow
- `path/to/example.ts`: Reference implementation

### Known Gotchas
- [Issue 1]: How to handle
- [Issue 2]: How to avoid

## Implementation Blueprint

### Data Models
[If applicable - schema definitions]

### Tasks (in order)
1. **Task 1**: Description
   - Files: `path/to/file`
   - Approach: Pseudocode or description

2. **Task 2**: Description
   - Files: `path/to/file`
   - Approach: Pseudocode or description

### Integration Points
- [How this connects to existing code]

## Validation Loop

### Level 1: Syntax & Style
```bash
# Commands to run
npm run lint
npm run typecheck
```

### Level 2: Unit Tests
```bash
# Test commands
npm test -- --coverage
```

### Level 3: Integration Tests
```bash
# Integration verification
curl -X POST http://localhost:3000/api/...
```

## Final Checklist
- [ ] All success criteria met
- [ ] Level 1 validation passes
- [ ] Level 2 validation passes
- [ ] Level 3 validation passes
- [ ] No regressions in existing tests
```
</step_4_generate_prp>

<step_5_save>
**Save PRP**

Create directory and save:
```
PRPs/active/{feature-name}/prp.md
```

Report location and confidence score (1-10) for one-pass success.
</step_5_save>

</process>

<quality_checklist>
Before saving, verify:
- [ ] All necessary context included
- [ ] Validation gates are executable
- [ ] References existing patterns
- [ ] Clear implementation path
- [ ] Error handling documented
- [ ] Success criteria are measurable
</quality_checklist>

<output_format>
## PRP Created

**Location:** `PRPs/active/{feature-name}/prp.md`

**Confidence Score:** X/10
[Explanation of confidence level]

**Ready for execution with:** `/prp-execute PRPs/active/{feature-name}/prp.md`
</output_format>

<success_criteria>
- PRP saved to correct location
- All template sections completed
- Confidence score >= 7 for complex features
- Executing agent needs no clarification
</success_criteria>

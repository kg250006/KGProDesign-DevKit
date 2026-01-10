---
description: "[KGP] Create hierarchical project plans with phases, tasks, dependencies, and verification criteria"
argument-hint: [project or feature description]
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
---

<objective>
Create a project plan for: $ARGUMENTS

Plans are hierarchical structures optimized for Claude execution:
- Briefs → Roadmaps → Phase Plans → Tasks
</objective>

<process>

<step_1_clarify>
**Clarify Scope**

Determine plan level:
- **Brief:** High-level project overview
- **Roadmap:** Multi-phase project structure
- **Phase Plan:** Single phase with tasks
- **Task Plan:** Detailed task breakdown
</step_1_clarify>

<step_2_research>
**Research Context**

Gather information:
- Current codebase state
- Existing patterns to follow
- Dependencies and constraints
- Related documentation
</step_2_research>

<step_3_generate>
**Generate Plan**

**For Brief:**
```markdown
# Project Brief: [Name]

## Objective
[What we're building and why]

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Phases
1. Phase 1: [Name] - [Brief description]
2. Phase 2: [Name] - [Brief description]

## Constraints
- [Constraint 1]
- [Constraint 2]

## Dependencies
- [Dependency 1]
```

**For Phase Plan:**
```markdown
# Phase Plan: [Name]

## Objective
[What this phase accomplishes]

## Prerequisites
- [ ] Required before starting

## Tasks

### Task 1: [Name]
**Description:** [What to do]
**Files:** [Files affected]
**Verification:**
- [ ] How to verify completion

### Task 2: [Name]
**Description:** [What to do]
**Files:** [Files affected]
**Verification:**
- [ ] How to verify completion

## Phase Completion Criteria
- [ ] All tasks complete
- [ ] All verifications pass
- [ ] No regressions
```

**For Task Plan:**
```markdown
# Task: [Name]

## Objective
[Specific outcome]

## Approach
1. Step 1
2. Step 2
3. Step 3

## Files to Modify
- `path/to/file1` - [what to change]
- `path/to/file2` - [what to change]

## Verification
```bash
# Commands to verify
npm test
npm run lint
```

## Success Criteria
- [ ] Specific outcome 1
- [ ] Specific outcome 2
```
</step_3_generate>

<step_4_save>
**Save Plan**

Save to appropriate location:
- `.planning/briefs/[name].md`
- `.planning/roadmaps/[name].md`
- `.planning/phases/[phase-name]/PLAN.md`
- `.planning/tasks/[task-name].md`
</step_4_save>

</process>

<output_format>
## Plan Created

**Type:** Brief | Roadmap | Phase | Task
**File:** `.planning/[type]/[name].md`

**Next steps:**
- [What to do with this plan]
</output_format>

<success_criteria>
- Clear objective stated
- Appropriate detail level
- Verification criteria included
- Dependencies mapped
- Claude can execute without clarification
</success_criteria>

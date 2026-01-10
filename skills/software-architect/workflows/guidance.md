# Workflow: Document Type Guidance

<objective>
Help decide whether to create a PRP, PRD, or both based on the current situation and goals.
</objective>

<decision_matrix>

## Quick Decision Guide

| Situation | Create | Reason |
|-----------|--------|--------|
| I have requirements and want to implement now | **PRP** | Direct to execution |
| I need to document for stakeholder approval | **PRD** | Codebase-agnostic for review |
| I'm exploring an idea before committing | **PRD** | Clarify before implementing |
| I have a PRD and want to implement | **PRP from PRD** | Convert to executable |
| Feature for multiple codebases/teams | **PRD** | Portable specification |
| Solo developer, single codebase | **PRP** | Skip intermediate step |
| Complex feature needing alignment | **PRD** then **PRP** | Full documentation chain |

</decision_matrix>

<comparison>

## PRP vs PRD Comparison

| Aspect | PRP (Product Requirement Prompt) | PRD (Product Requirement Document) |
|--------|----------------------------------|-----------------------------------|
| **Purpose** | Implementation blueprint | Stakeholder specification |
| **Audience** | Claude/Ralph Loop, developers | Product team, stakeholders, any team |
| **Specificity** | Codebase-specific | Codebase-agnostic |
| **Content** | File paths, pseudocode, agent assignments | User stories, requirements, API contracts |
| **Output** | Executable tasks | Transferable specification |
| **Lifecycle** | Lives until feature is done | Lives as documentation |
| **Best for** | Immediate implementation | Planning, approval, handoff |

</comparison>

<scenarios>

## Common Scenarios

### Scenario 1: "I have a feature request from the product team"
**Recommendation:** Start with **PRD**

Why:
- Formalizes requirements before coding
- Gets stakeholder alignment
- Documents for future reference
- Can convert to PRP when ready

### Scenario 2: "I know exactly what I need to build"
**Recommendation:** Create **PRP** directly

Why:
- Skip unnecessary documentation overhead
- Get to implementation faster
- Still have structured task breakdown
- Works directly with Ralph Loop

### Scenario 3: "This feature will be used in multiple projects"
**Recommendation:** Create **PRD** only

Why:
- Each project will have different implementations
- PRD is portable across codebases
- Each team creates their own PRP
- Maintains consistency of requirements

### Scenario 4: "Large feature with many unknowns"
**Recommendation:** **PRD** then **PRP**

Why:
- PRD clarifies scope and requirements
- Stakeholder review catches issues early
- PRP benefits from clearer requirements
- Reduces implementation rework

### Scenario 5: "Quick bug fix or small enhancement"
**Recommendation:** Neither (just do it)

Why:
- Over-documentation slows down small changes
- Direct implementation is appropriate
- Document only if pattern will repeat

### Scenario 6: "Technical refactoring / migration"
**Recommendation:** **PRP** only

Why:
- No user-facing requirements (no PRD needed)
- Focus on implementation tasks
- Document technical approach
- Still benefit from structured breakdown

</scenarios>

<questions>

## Clarifying Questions

Answer these to determine the right document:

1. **Who needs to approve this?**
   - Just me → PRP
   - Stakeholders/product team → PRD

2. **Will this be implemented in other codebases?**
   - Yes → PRD
   - No → PRP (unless approval needed)

3. **How well-defined are the requirements?**
   - Clear and specific → PRP
   - Vague or exploratory → PRD first

4. **What's the scope?**
   - Small (< 1 day) → Maybe neither
   - Medium (1-5 days) → PRP
   - Large (> 1 week) → PRD then PRP

5. **Is this a one-time implementation?**
   - Yes → PRP
   - Pattern for future use → PRD for documentation

</questions>

<output_format>
Based on your answers, I recommend:

**Document Type:** PRP / PRD / PRD then PRP / Neither

**Reasoning:**
[Explain based on scenario match]

**Next Step:**
[What to do now]
</output_format>

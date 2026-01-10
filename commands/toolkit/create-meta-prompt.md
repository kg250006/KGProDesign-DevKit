---
description: "[KGP] Create multi-stage prompts for Claude-to-Claude pipelines (research → plan → implement)"
argument-hint: [workflow description]
allowed-tools: [Read, Write, Glob, AskUserQuestion]
---

<objective>
Create a multi-stage prompt pipeline for: $ARGUMENTS

Meta-prompts enable staged workflows where each stage produces outputs for the next stage to consume.
</objective>

<stages>
**Common Pipeline Patterns:**

1. **Research → Plan → Implement**
   - Stage 1: Gather information, explore options
   - Stage 2: Design approach based on research
   - Stage 3: Execute plan

2. **Analyze → Decide → Act**
   - Stage 1: Analyze current state
   - Stage 2: Make decision based on analysis
   - Stage 3: Take action

3. **Parallel Research → Synthesize → Execute**
   - Stage 1: Multiple parallel research tasks
   - Stage 2: Combine findings
   - Stage 3: Execute based on synthesis
</stages>

<process>

<step_1_design>
**Design Pipeline**

Determine:
- How many stages?
- What does each stage produce?
- What dependencies exist between stages?
- Parallel or sequential execution?
</step_1_design>

<step_2_generate>
**Generate Stage Prompts**

For each stage, create a prompt file:

**Stage 1 (Research):**
```xml
<objective>
Research [topic] to inform the next stage.
</objective>

<scope>
[What to research]
[Sources to check]
</scope>

<output>
Save findings to: `./pipeline/[name]/stage-1-research.md`

Structure:
- Key findings
- Options identified
- Recommendations
</output>

<next_stage>
Findings will be used by Stage 2 to create implementation plan.
</next_stage>
```

**Stage 2 (Plan):**
```xml
<objective>
Create implementation plan based on research.
</objective>

<input>
Load research from: @./pipeline/[name]/stage-1-research.md
</input>

<requirements>
[What the plan should include]
</requirements>

<output>
Save plan to: `./pipeline/[name]/stage-2-plan.md`
</output>

<next_stage>
Plan will be executed in Stage 3.
</next_stage>
```

**Stage 3 (Implement):**
```xml
<objective>
Execute the implementation plan.
</objective>

<input>
Load plan from: @./pipeline/[name]/stage-2-plan.md
</input>

<process>
Follow the plan step by step.
</process>

<output>
[Implementation artifacts]
</output>

<verification>
[How to verify success]
</verification>
```
</step_2_generate>

<step_3_orchestration>
**Create Orchestration**

Create pipeline runner:

```markdown
# Pipeline: [Name]

## Stages
1. `./pipeline/[name]/stage-1-research.md` - Research
2. `./pipeline/[name]/stage-2-plan.md` - Plan
3. `./pipeline/[name]/stage-3-implement.md` - Implement

## Execution
Sequential: Each stage depends on previous.

Run with:
/run-prompt ./pipeline/[name]/stage-1-research.md
/run-prompt ./pipeline/[name]/stage-2-plan.md
/run-prompt ./pipeline/[name]/stage-3-implement.md
```
</step_3_orchestration>

<step_4_save>
**Save Pipeline**

Save to:
```
./pipeline/[name]/
  README.md          # Orchestration
  stage-1-research.md
  stage-2-plan.md
  stage-3-implement.md
```
</step_4_save>

</process>

<output_format>
## Meta-Prompt Pipeline Created

**Directory:** `./pipeline/[name]/`
**Stages:** X stages (sequential/parallel)

**Run with:**
```
/run-prompt ./pipeline/[name]/stage-1-research.md
```
Or run all stages sequentially.
</output_format>

<success_criteria>
- Each stage has clear inputs/outputs
- Dependencies are explicit
- Outputs are saved to files
- Pipeline is runnable
</success_criteria>

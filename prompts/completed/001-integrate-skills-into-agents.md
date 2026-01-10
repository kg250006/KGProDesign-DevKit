<objective>
Update all agent configurations in the `agents/` directory to reference and leverage relevant skills from the `skills/` directory. When an agent's work would benefit from specialized methodology (debugging, visual testing, architecture planning, etc.), the agent should invoke the corresponding skill.

This improves agent effectiveness by ensuring they use expert methodologies rather than ad-hoc approaches.
</objective>

<context>
@CLAUDE.md - Project conventions
@agents/ - All agent configuration files
@skills/*/SKILL.md - Available skill definitions

**Available Skills:**
- `skills/debug-like-expert` - Methodical debugging with hypothesis testing, evidence gathering, root cause analysis
- `skills/ui-visual-testing` - Puppeteer-based UI validation, DOM inspection, console monitoring, screenshots
- `skills/software-architect` - PRPs (codebase-specific implementation plans) and PRDs (portable specifications)
- `skills/create-plans` - Hierarchical project planning for solo agentic development
- `skills/create-hooks` - Claude Code hook configuration
- `skills/create-subagents` - Subagent creation guidance
- `skills/create-slash-commands` - Slash command creation
- `skills/create-agent-skills` - Skill creation guidance
- `skills/create-meta-prompts` - Multi-stage prompt pipelines

**Agent → Skill Mappings to Implement:**

| Agent | Skills to Reference | When to Invoke |
|-------|---------------------|----------------|
| backend-engineer | debug-like-expert, software-architect | Debugging complex issues; creating PRPs/PRDs for API design |
| frontend-engineer | debug-like-expert, ui-visual-testing, software-architect | Debugging UI issues; visual regression testing; architecture planning |
| qa-engineer | debug-like-expert, ui-visual-testing | Root cause analysis for bugs; automated UI validation |
| data-engineer | debug-like-expert | Debugging schema/query issues |
| devops-engineer | debug-like-expert, create-plans | Infrastructure debugging; deployment planning |
| document-specialist | software-architect | Creating PRDs and PRPs |
| project-coordinator | create-plans, software-architect | Project planning; requirement documentation |
| subagent-auditor | (meta-update) | Should recommend skill integration as audit criterion |
</context>

<requirements>
1. **For each applicable agent**, add a new XML section that:
   - Lists relevant skills the agent should leverage
   - Explains WHEN to invoke each skill
   - Shows HOW to invoke the skill (via Skill tool or direct reference)

2. **Skill Integration Section Format**:
   ```xml
   <skill_integration>
   When your work involves specialized methodologies, invoke the appropriate skill:

   **Available Skills:**

   <skill name="skill-name" trigger="when to use">
   Invoke via: `/skill-name` or reference `@skills/skill-name/SKILL.md`
   Use when: [specific trigger conditions]
   </skill>

   ...
   </skill_integration>
   ```

3. **Preserve existing agent structure** - add skill integration as a new section, don't restructure the entire agent

4. **Update subagent-auditor** to:
   - Add "skill utilization" as an evaluation criterion
   - Check whether agents reference relevant skills
   - Flag agents that could benefit from skill integration but don't use it
</requirements>

<implementation>
For each agent file, add a `<skill_integration>` section after the existing content (but before any closing tags if using pure XML).

**Example for backend-engineer:**
```xml
<skill_integration>
When your work involves specialized methodologies, invoke the appropriate skill for expert guidance:

<skill name="debug-like-expert" trigger="debugging complex issues">
Invoke when: Standard troubleshooting fails, issues require systematic root cause analysis, or you're debugging code you wrote (cognitive bias risk).
Usage: Reference @skills/debug-like-expert/SKILL.md for methodical investigation protocol.
</skill>

<skill name="software-architect" trigger="designing implementation plans">
Invoke when: Creating PRPs for complex features, designing API contracts, or documenting technical requirements.
Usage: Use `/prp-create` for codebase-specific plans or `/prd-create` for portable specifications.
</skill>
</skill_integration>
```

**For agents using markdown headings (not pure XML):**
Add as a new markdown section:
```markdown
## Skill Integration

When your work involves specialized methodologies, invoke the appropriate skill:

### debug-like-expert
- **Trigger**: Debugging complex issues where standard troubleshooting fails
- **Invoke**: Reference `@skills/debug-like-expert/SKILL.md`
- **Purpose**: Methodical investigation with hypothesis testing and verification
```
</implementation>

<file_changes>
Modify these files (in order):

1. `agents/backend-engineer.md` - Add: debug-like-expert, software-architect
2. `agents/frontend-engineer.md` - Add: debug-like-expert, ui-visual-testing, software-architect
3. `agents/qa-engineer.md` - Add: debug-like-expert, ui-visual-testing
4. `agents/data-engineer.md` - Add: debug-like-expert
5. `agents/devops-engineer.md` - Add: debug-like-expert, create-plans
6. `agents/document-specialist.md` - Add: software-architect
7. `agents/project-coordinator.md` - Add: create-plans, software-architect
8. `agents/subagent-auditor.md` - Add skill utilization evaluation criterion
</file_changes>

<validation>
After completing changes:

1. **Verify each agent file** has the skill integration section added correctly
2. **Check subagent-auditor** includes skill utilization in evaluation areas
3. **Run a syntax check** - ensure all XML tags are properly closed
4. **Verify no existing content was accidentally removed**

Verification command:
```bash
# Check all agent files have skill_integration or "Skill Integration"
grep -l -E "(skill_integration|Skill Integration)" agents/*.md

# Should return all 8 modified files
```
</validation>

<success_criteria>
- [ ] All 7 role-based agents have skill integration sections
- [ ] subagent-auditor has skill utilization as evaluation criterion
- [ ] Skill triggers are specific and actionable (not vague)
- [ ] Integration sections match existing agent structure (XML vs markdown)
- [ ] No existing agent content was removed or broken
- [ ] All file modifications are syntactically valid
</success_criteria>

<output>
After completing all modifications, provide:
1. Summary of changes made to each file
2. Verification results from the bash command
3. Any issues encountered and how they were resolved
</output>

# CLAUDE.md - KGProDesign-DevKit Reference

This file provides guidance to Claude Code when working in projects using the KGProDesign-DevKit plugin.

## Core Principles

### 1. Keep It Simple (KISS)
- Choose straightforward solutions over complex ones
- Simple solutions are easier to understand, maintain, and debug
- If it takes more than 3 steps to explain, simplify it

### 2. Always Test and Verify
- Your work is not complete until tests pass
- Run verification after every significant change
- Use the appropriate testing commands for your stack

### 3. Clean Up Documentation Regularly
- Update CLAUDE.md when workflows change
- Remove outdated commands/agents
- Keep examples current and working

---

## PRP Workflow

### What is a PRP?
Product Requirement Prompt - A structured specification that Claude executes to implement features with validation gates.

### PRP Lifecycle
```
1. Create PRP    → /$PLUGIN_NAME:prp-create (gather requirements)
2. Validate PRP  → /$PLUGIN_NAME:prp-validate (pre-flight checks)
3. Execute PRP   → /$PLUGIN_NAME:prp-execute (Claude implements)
4. Verify        → Run tests, review changes
5. Commit        → /$PLUGIN_NAME:commit
```

### PRP Creation
```bash
/$PLUGIN_NAME:prp-create "Add user authentication with OAuth2"
```
Claude will:
1. Ask clarifying questions
2. Research existing patterns in codebase
3. Generate structured PRP document
4. Save to PRPs/active/ directory

### PRP Execution
```bash
/$PLUGIN_NAME:prp-execute PRPs/active/auth-oauth2/prp.md
```
Claude will:
1. Parse the PRP specification
2. Implement step by step
3. Run validation at each step
4. Report completion status

### Programmatic PRP Execution
For CI/CD or batch processing, use the `prp_runner.py` script:

```bash
# Interactive mode
uv run scripts/prp_runner.py --prp feature-name --interactive

# Headless mode with JSON output
uv run scripts/prp_runner.py --prp-path PRPs/active/feature.md --output-format json

# Stream JSON for real-time progress
uv run scripts/prp_runner.py --prp feature-name --output-format stream-json
```

### Ralph Loop (Iterative Development)

Ralph Loop is an iterative self-referential development loop that feeds Claude's output back as input until completion.

```bash
# Basic usage
/$PLUGIN_NAME:ralph-loop "Build a REST API for todos" --completion-promise 'DONE' --max-iterations 20

# Fresh context mode (prevents context rot for long tasks)
/$PLUGIN_NAME:ralph-loop "Complex refactoring" --fresh-context --max-iterations 30 --completion-promise 'TASK COMPLETE'

# Resume an interrupted loop
/$PLUGIN_NAME:ralph-loop --resume
```

**Options:**
- `--max-iterations N` - Maximum iterations before auto-stop (default: 20)
- `--completion-promise 'TEXT'` - Promise phrase to output when complete
- `--max-retries N` - Max retries per task before marking blocked (default: 0/disabled)
- `--fresh-context` - Enable session isolation mode (fresh context each iteration)
- `--resume` - Resume from previous progress file

**Fresh Context Mode:**
For long-running tasks (10+ iterations), `--fresh-context` enables session isolation:
- Each iteration ends the session cleanly with zero context
- Progress tracked in `.claude/ralph-progress.md`
- Use `--resume` or `ralph-auto.sh` wrapper for continuation
- Prevents context rot for complex multi-phase tasks

**Monitoring:**
```bash
# View current iteration
head -10 .claude/ralph-loop.local.md

# View progress (fresh-context mode)
cat .claude/ralph-progress.md
```

---

## Framework Templates

Pre-built CLAUDE.md templates for common tech stacks in `templates/frameworks/`:

| Template | Stack | Use Case |
|----------|-------|----------|
| `CLAUDE-NEXTJS-15.md` | Next.js 15 + React 19 + TypeScript | Full-stack web apps |
| `CLAUDE-REACT.md` | React 19 + TypeScript | Frontend SPAs |
| `CLAUDE-ASTRO.md` | Astro 5 + Islands Architecture | Content-heavy sites |
| `CLAUDE-NODE.md` | Node.js 23 + Fastify | Backend APIs |
| `CLAUDE-PYTHON-BASIC.md` | Python + FastAPI + UV | Python APIs |
| `CLAUDE-JAVA-GRADLE.md` | Java 21 + Spring Boot + Gradle | Enterprise Java |
| `CLAUDE-JAVA-MAVEN.md` | Java 21 + Spring Boot + Maven | Enterprise Java |

### Using Framework Templates
Copy the appropriate template to your project root:

```bash
cp templates/frameworks/CLAUDE-NEXTJS-15.md /your/project/CLAUDE.md
```

Or reference it in your project's CLAUDE.md:

```markdown
# Project CLAUDE.md

## Framework Reference
@~/.claude/plugins/KGProDesign-DevKit/templates/frameworks/CLAUDE-NEXTJS-15.md

## Project-specific overrides
...
```

---

## Available Agents

### frontend-engineer
**Purpose:** Full-stack frontend development (UI, components, performance)

**When to use:**
- Building UI components
- Implementing designs from mockups
- Accessibility improvements
- State management

**Invocation:**
```bash
# Via Task tool in Claude Code
```

### backend-engineer
**Purpose:** Server-side development (API, business logic, services)

**When to use:**
- API design and implementation
- Business logic development
- Authentication/authorization
- Service integration

### data-engineer
**Purpose:** Database and data layer (schema, migrations, optimization)

**When to use:**
- Schema design and updates
- Migration planning
- Query optimization
- Data modeling

### qa-engineer
**Purpose:** Quality assurance (testing, security, code review)

**When to use:**
- Before merging PRs
- After implementing complex features
- For security-sensitive changes
- Test strategy planning

### project-coordinator
**Purpose:** Project management and Agile workflows

**When to use:**
- Sprint planning
- Task breakdown and estimation
- Progress tracking
- Risk assessment

### document-specialist
**Purpose:** Technical documentation and content creation

**When to use:**
- PRD/PRP creation
- API documentation
- README updates
- Technical guides

### devops-engineer
**Purpose:** Infrastructure and deployment

**When to use:**
- CI/CD pipeline setup
- Docker configuration
- Infrastructure as Code
- Performance monitoring

### config-auditor (Optional)
**Purpose:** Plugin configuration validation

**When to use:**
- Validating new skills
- Auditing command quality
- Checking agent configurations
- Best practices compliance

---

## Commands Reference

### Core Commands

#### /context-prime
Initializes Claude's understanding of the current project.

```bash
/context-prime
```
**What it does:**
1. Reads project structure
2. Identifies tech stack
3. Loads relevant CLAUDE.md files
4. Prepares optimal context

#### /create
Universal scaffolding command.

```bash
/create <type> [name]
```
**Types:** component, service, api, model, test, prp, hook, command, agent, feature

**What it does:**
1. Detects project patterns
2. Generates consistent structure
3. Includes tests and exports

#### /debug
Expert debugging with hypothesis testing.

```bash
/debug [issue description]
```
**What it does:**
1. Gathers evidence
2. Forms hypotheses
3. Tests systematically
4. Documents root cause

### PRP Commands

#### /$PLUGIN_NAME:prp-create
Generate PRP from requirements.

```bash
/$PLUGIN_NAME:prp-create "Feature description"
```

#### /$PLUGIN_NAME:prp-execute
Execute PRP with validation.

```bash
/$PLUGIN_NAME:prp-execute <path-to-prp.md>
```

#### /$PLUGIN_NAME:prp-validate
Pre-flight PRP validation.

```bash
/$PLUGIN_NAME:prp-validate <path-to-prp.md>
```

#### /$PLUGIN_NAME:prp-execute-isolated
Execute PRP with hard session isolation - each task runs in a fresh Claude session.

```bash
# Basic usage
/$PLUGIN_NAME:prp-execute-isolated PRPs/feature.md

# With retry configuration
/$PLUGIN_NAME:prp-execute-isolated PRPs/feature.md --max-retries 5

# With longer timeout
/$PLUGIN_NAME:prp-execute-isolated PRPs/feature.md --timeout 600
```

**When to use:**
- PRPs with 10+ tasks (prevents context rot)
- When deterministic execution is required
- When previous runs showed Claude "optimizing" by combining tasks

**How it works:**
1. External shell script orchestrates (not Claude)
2. Each task written to `.claude/current-task.md`
3. Fresh Claude session spawned per task
4. Claude sees ONLY current task (not full PRP)
5. Progress logged to `.claude/prp-progress.md`

**Comparison:**

| Aspect | prp-execute | prp-execute-isolated |
|--------|-------------|---------------------|
| **Context** | Shared (one session) | Isolated (fresh per task) |
| **Control** | Claude decides | Script controls |
| **Task visibility** | Claude sees all tasks | Claude sees only current |
| **Use case** | Quick, interactive | Complex, deterministic |

### Workflow Commands

#### /commit
Smart git commit with conventional format.

```bash
/commit
```

#### /pr
Create pull request.

```bash
/pr
```

#### /review
Code review for staged changes.

```bash
/review
```

### Meta-Prompting Commands

#### /create-prompt
Create prompts for other Claude instances.

```bash
/create-prompt
```

#### /run-prompt
Delegate prompts to fresh contexts.

```bash
/run-prompt <prompt-file>
```

### Creation Toolkit Commands

#### /create-hook
Configure Claude Code hooks (PreToolUse, PostToolUse, Stop, etc.).

#### /create-subagent
Create specialized subagents with role definition.

#### /create-slash-command
Create slash commands with YAML frontmatter.

#### /create-agent-skill
Create Claude Code skills with router pattern.

#### /create-plan
Create hierarchical project plans.

#### /create-meta-prompt
Create multi-stage prompts (Research → Plan → Implement).

### Analysis Commands

#### /consider
Unified decision framework.

```bash
/consider <framework> [problem]
```

**Available frameworks:**
- `first-principles` - Break down to fundamentals
- `5-whys` - Root cause by asking why repeatedly
- `inversion` - Solve problems backwards
- `pareto` - Apply 80/20 rule
- `second-order` - Consequences of consequences
- `opportunity-cost` - Analyze trade-offs
- `one-thing` - Highest-leverage action
- `occams-razor` - Simplest explanation
- `swot` - Strengths/weaknesses/opportunities/threats
- `eisenhower` - Urgent/important matrix
- `via-negativa` - Improve by removing
- `10-10-10` - Time horizon evaluation

#### /onboard
Project onboarding analysis for new engineers.

```bash
/onboard
```

### Utility Commands

#### /handoff
Create context handoff document.

```bash
/handoff
```

#### /resolve-conflicts
Git conflict resolution.

```bash
/resolve-conflicts
```

---

## Maintenance Processes

### Adding New Commands

1. Create `.claude/commands/[category]/command-name.md`
2. Follow YAML frontmatter format:
   ```yaml
   ---
   name: command-name
   description: Brief description
   tools: Read, Write, Bash, Grep, Glob
   ---
   ```
3. Document in CLAUDE.md
4. Test with `/command-name`

### Adding New Agents

1. Create `.claude/agents/agent-name.md`
2. Include frontmatter:
   ```yaml
   ---
   name: agent-name
   description: Detailed purpose
   tools: Read, Write, Bash, Task, etc.
   color: Blue
   ---
   ```
3. Define clear purpose and instructions
4. Document in CLAUDE.md

### Updating Documentation

**Weekly:**
- Review command effectiveness
- Update examples if needed
- Remove deprecated items

**Monthly:**
- Full documentation audit
- Verify all commands work
- Update version manifest

---

## Best Practices

### For All Development

1. **Start with context:** Always run `/context-prime` in new sessions
2. **Use agents for complexity:** Single commands for simple tasks, agents for complex
3. **Verify before commit:** Run `/review` before committing
4. **Test incrementally:** Don't batch large changes

### For PRP Workflow

1. **Be specific in requirements:** Vague PRPs produce vague results
2. **Review before executing:** PRPs are editable - refine them
3. **Break large features:** Multiple small PRPs beat one large PRP
4. **Save successful PRPs:** Build a library of working patterns

### Session Isolation Philosophy

For complex PRPs (10+ tasks), every task should run in a completely separate session:

**HARD LINE:** Each task gets its own fresh context window. No judgment. No optimization. Even if a task is 2% of context, it gets its own fresh window.

**Why this matters:**
- **Prevents context rot** - Claude's performance degrades as context fills
- **Ensures deterministic execution** - Same PRP always executes the same way
- **Removes Claude's ability to "optimize"** - Claude cannot decide to combine tasks
- **Reproducible results** - Fresh context means consistent behavior

**Commands comparison:**

| Command | Isolation | Control | Best For |
|---------|-----------|---------|----------|
| `prp-execute` | Shared context | Claude decides | Quick PRPs (< 5 tasks) |
| `prp-execute-isolated` | Fresh per task | Script controls | Complex PRPs (10+ tasks) |

### For Code Review

1. **Review early:** Don't wait until PR time
2. **Focus on business logic:** Syntax is the easy part
3. **Track patterns:** Note recurring issues for CLAUDE.md

---

## Troubleshooting

### Command Not Found
```bash
# Verify installation
ls ~/.claude/commands/

# Restart Claude session
Ctrl+D
claude
```

### Agent Not Available
```bash
# Check agent file exists
ls ~/.claude/agents/

# Verify frontmatter format
cat ~/.claude/agents/agent-name.md
```

### Context Issues
```bash
# Clear and reinitialize
/clear
/context-prime
```

---

## Configuration

### settings.local.json
```json
{
  "toolPermissions": {
    "allowlist": ["bash", "write", "read", "edit"]
  }
}
```

### Project-Specific CLAUDE.md
Create project-specific CLAUDE.md in your project root:

```markdown
# Project CLAUDE.md

## Project-specific context
- Framework: Next.js 15
- Database: PostgreSQL with Prisma ORM
- Testing: Vitest + Playwright

## Import plugin documentation
@~/.claude/plugins/KGProDesign-DevKit/CLAUDE.md
```

---

Last Updated: 2025-12-31
Maintained by: KGProDesign

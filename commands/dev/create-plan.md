---
description: Create hierarchical project plans for solo agentic development (briefs, roadmaps, phase plans)
argument-hint: [what to plan]
allowed-tools:
  - Skill(create-plans)
  - Read
  - Bash
  - Write
  - Glob
---

<agent_discovery>
## Agent Discovery for Planning

Before creating the plan, scan for available specialized agents to inform task assignments:

```
Glob: agents/*.md
```

When creating plans, consider which agents are available for task delegation:
| Agent | Specialization | Best For |
|-------|---------------|----------|
| backend-engineer | Server-side development | APIs, auth, services, business logic |
| frontend-engineer | UI development | Components, accessibility, state management |
| data-engineer | Data layer | Schema design, migrations, query optimization |
| qa-engineer | Quality assurance | Testing, security, code review |
| devops-engineer | Infrastructure | CI/CD, Docker, deployment |
| document-specialist | Documentation | PRDs, README, technical guides |
| project-coordinator | Project management | Sprint planning, task breakdown |

Include agent recommendations in task definitions so execution commands can delegate appropriately.
</agent_discovery>

Invoke the create-plans skill for: $ARGUMENTS

When generating plan tasks, assign appropriate agents based on task type to enable efficient delegation during execution.

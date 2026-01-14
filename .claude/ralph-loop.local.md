---
active: true
iteration: 1
max_iterations: 27
completion_promise: "PRP COMPLETE"
started_at: "2026-01-14T20:48:27Z"
---

Execute PRP: Isolated PRP Execution with External Orchestrator

GOAL: Create a new command `/$PLUGIN_NAME:prp-execute-isolated` that enforces hard session isolation by using an external shell script orchestrator. Each PRP task runs in a completely fresh Claude session with zero context sharing. Claude becomes the worker, not the orchestrator - physically preventing context bleed between tasks.

TASKS:
- Phase 1: Task Extraction Infrastructure
- Task 1.1: Create prp-to-tasks.js - Node.js script to extract tasks from PRP XML (agent: backend-engineer)
- Task 1.2: Test prp-to-tasks.js against existing PRP file (agent: qa-engineer)

- Phase 2: Bash Orchestrator
- Task 2.1: Create prp-orchestrator.sh - Main bash orchestrator script (agent: backend-engineer)
- Task 2.2: Add help function and make script executable (agent: backend-engineer)

- Phase 3: PowerShell Orchestrator
- Task 3.1: Create prp-orchestrator.ps1 - PowerShell orchestrator for Windows (agent: backend-engineer)

- Phase 4: Slash Command Integration
- Task 4.1: Create prp-execute-isolated.md slash command (agent: backend-engineer)

- Phase 5: Documentation Update
- Task 5.1: Update CLAUDE.md with new prp-execute-isolated command (agent: document-specialist)
- Task 5.2: Update commands/help.md with prp-execute-isolated info (agent: document-specialist)

- Phase 6: Testing and Validation
- Task 6.1: Create test PRP with 3 simple tasks (agent: qa-engineer)
- Task 6.2: Run end-to-end test with orchestrator (agent: qa-engineer)
- Task 6.3: Verify bash script syntax (agent: qa-engineer)

VALIDATION (run after each task):
- bash -n scripts/prp-orchestrator.sh 2>/dev/null || true
- node --check scripts/prp-to-tasks.js 2>/dev/null || true

COMPLETION CRITERIA:
When ALL of these are true, output <promise>PRP COMPLETE</promise>:
- [ ] prp-to-tasks.js extracts tasks from PRP XML correctly
- [ ] prp-orchestrator.sh spawns fresh Claude per task
- [ ] prp-orchestrator.ps1 provides Windows parity
- [ ] prp-execute-isolated command invokes orchestrator
- [ ] Each task runs in complete isolation (no context sharing)
- [ ] Progress tracking works (.claude/prp-progress.md)
- [ ] Retry logic functions correctly
- [ ] CLAUDE.md documents the new approach
- [ ] Test PRP validates isolation end-to-end

AVAILABLE AGENTS (use Task tool with subagent_type to delegate):
- backend-engineer: APIs, auth, services, business logic, scripts
- qa-engineer: Testing, security, code review
- document-specialist: Documentation, PRDs, technical writing
- devops-engineer: CI/CD, Docker, infrastructure

INSTRUCTIONS:
1. Read the full PRP at PRPs/PRP-prp-execute-isolated.md
2. For each task, consider delegating to the most appropriate agent using Task tool
3. Work through tasks in phase order
4. Run validation after completing each task
5. If validation fails, fix before proceeding
6. After all tasks complete, verify ALL success criteria
7. ONLY output the promise when genuinely complete
8. You can see your previous work in files and git history

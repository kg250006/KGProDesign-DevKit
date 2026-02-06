---
name: regression-test
description: Run automated regression tests across any project. Supports frontend, backend, E2E, and coverage enhancement. Designed for headless execution.
argument-hint: [--frontend|--backend|--coverage|--fix|--resume] [keywords...]
allowed-tools: Skill(regression-testing), Read, Bash, Grep, Glob, Write, Edit, Task
---

Invoke the regression-testing skill for: $ARGUMENTS

## Quick Reference

### Full Regression (default)
```bash
/regression-test
```
Runs all tests: unit, integration, E2E

### Targeted Testing
```bash
/regression-test --frontend     # UI/React/frontend tests only
/regression-test --backend      # API/service/backend tests only
/regression-test auth login     # Tests matching keywords
```

### Coverage Enhancement
```bash
/regression-test --coverage
```
Assess current coverage and enhance to target (100% if < 60%)

### Fix Mode
```bash
/regression-test --fix
```
Debug and fix failing tests from previous run using debug-like-expert skill

### Resume
```bash
/regression-test --resume
```
Resume from `.claude/regression-progress.md` checkpoint

## Designed for Headless Execution

This command is designed to run autonomously without user interaction:
- No questions asked during execution
- Progress tracked in `.claude/regression-progress.md`
- Failures logged for fix phase
- Context recovery if session resets

## Integration with Other Skills

- **debug-like-expert**: Invoked for failing test root cause analysis
- **ui-visual-testing**: Invoked for visual regression testing
- **qa-engineer**: Task agent for complex test strategy

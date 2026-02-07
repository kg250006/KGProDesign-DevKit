---
name: run-regression
description: "[KGP] Run automated regression tests across any project. Supports frontend, backend, E2E, and coverage enhancement."
argument-hint: [--frontend|--backend|--coverage|--fix|--resume] [keywords...]
allowed-tools: Skill(regression-testing), Read, Bash, Grep, Glob, Write, Edit, Task
---

Invoke the KGP plugin regression-testing skill for: $ARGUMENTS

## Quick Reference

### Full Regression (default)
```bash
/run-regression
```
Runs all tests: unit, integration, E2E

### Targeted Testing
```bash
/run-regression --frontend     # UI/React/frontend tests only
/run-regression --backend      # API/service/backend tests only
/run-regression auth login     # Tests matching keywords
```

### Coverage Enhancement
```bash
/run-regression --coverage
```
Assess current coverage and enhance to target (100% if < 60%)

### Fix Mode
```bash
/run-regression --fix
```
Debug and fix failing tests from previous run using debug-like-expert skill

### Resume
```bash
/run-regression --resume
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

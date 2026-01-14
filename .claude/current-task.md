# Current Task: 1.3

You are executing a single task from a PRP. Focus ONLY on this task.

## Task Description
Create a file test-output/test-task-3.txt. Verify you cannot see task 1 or 2 in your context.

## Files to Modify
- [create] test-output/test-task-3.txt

## Implementation Guide
```
# Write file - should have NO context from tasks 1-2
echo "Task 3 executed at $(date)" > test-output/test-task-3.txt
```

## Acceptance Criteria
- File test-output/test-task-3.txt exists
- Task completed without context from previous tasks

## Instructions
1. Complete this task fully
2. Validate your work (run tests if applicable)
3. Exit when done - the orchestrator handles the next task

## CRITICAL CONSTRAINTS
- DO NOT read the full PRP file
- DO NOT ask about other tasks
- DO NOT try to optimize by combining tasks
- Focus ONLY on this single task

---
command: fix-issue-simple
description: Fix GitHub issue using general simple steps
ARGUMENTS: <issue_number>
---

Please analyze and fix GitHub issue #$ARGUMENTS.

Follow these steps:

1. Use `gh issue view $ARGUMENTS` to get issue details
2. Search codebase for relevant files using appropriate tools
3. Understand the root cause
4. Implement fix with tests
5. Verify fix resolves issue
6. Create descriptive commit
7. Comment on issue with fix summary

Remember: Always write tests to prevent regression.

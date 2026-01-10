---
description: Create multiple git worktrees based on user arguments
---

Please create multiple git worktrees based on the user's arguments.

## Expected Arguments Format:

The user will provide arguments in one of these formats:

- Single worktree: `branch-name` or `branch-name:directory-name`
- Multiple worktrees: `branch1,branch2,branch3` or `branch1:dir1,branch2:dir2,branch3:dir3`
- Mixed format: `branch1,branch2:custom-dir,branch3`

User request: $ARGUMENTS

## Step-by-step process:

1. **Parse Arguments**: Extract branch names and optional directory names from user input
2. **Validate Repository**: Check that we're in a git repository
3. **Check Existing Branches**: Verify which branches exist locally and remotely
4. **Create Missing Branches**: Create any branches that don't exist yet (based on current branch)
5. **Create Worktrees**: For each branch, create a worktree with the specified or default directory name
6. **Verify Creation**: List all worktrees to confirm successful creation

## Rules:

- If no directory name is specified, use the branch name as the directory name
- Create branches if they don't exist (branch from current HEAD)
- Place worktrees in `../` relative to current repository (parallel directories)
- Handle existing worktrees gracefully (skip if already exists)
- Provide clear feedback on what was created vs what already existed

## Commands to use:

- `git status` - Verify we're in a git repo
- `git branch -a` - List all branches
- `git worktree list` - Show existing worktrees
- `git worktree add <path> <branch>` - Create new worktree
- `git checkout -b <branch>` - Create new branch if needed

## Example Usage:

- `/create-worktrees feature-auth` → Creates ../feature-auth with feature-auth branch
- `/create-worktrees main,develop,feature-x` → Creates 3 worktrees in parallel directories
- `/create-worktrees main:main-dir,develop:dev-dir` → Creates worktrees with custom directory names

Begin by asking the user for their worktree arguments if not provided, then proceed with the creation process.

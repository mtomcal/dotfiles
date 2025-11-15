---
description: Show detailed status of all git worktrees
---

Display comprehensive status information for all active git worktrees, including uncommitted changes, branch status, and sync state.

## Your Task

1. **Show all worktrees**
   - Run: `git worktree list`

2. **For each worktree, display:**
   - Branch name and worktree path
   - Git status (uncommitted changes)
   - Number of commits ahead/behind remote (if applicable)
   - Last commit information

3. **Provide summary**
   - Total active worktrees
   - Worktrees with uncommitted changes
   - Worktrees that need attention

## Example

User: "/worktree-status"

Your response:
```
Git Worktree Status Report
==========================

Main Worktree: /home/user/project [main]
├─ Status: clean
├─ Branch: main (up to date with origin/main)
└─ Last commit: feat: add authentication (2 hours ago)

Feature Worktree: trees/feature-auth [feature-auth]
├─ Status: 3 files modified
├─ Changes:
│  M src/auth/login.js
│  M src/auth/middleware.js
│  M tests/auth.test.js
├─ Branch: feature-auth (2 commits ahead of main)
└─ Last commit: feat: implement JWT authentication (30 minutes ago)

Feature Worktree: trees/refactor-db [refactor-db]
├─ Status: clean
├─ Branch: refactor-db (1 commit ahead of main)
└─ Last commit: refactor: migrate to TypeORM (1 hour ago)

Feature Worktree: trees/fix-bug-123 [fix-bug-123]
├─ Status: 1 file modified, ready to commit
├─ Changes:
│  M src/utils/validation.js
├─ Branch: fix-bug-123 (no commits yet, branched from main)
└─ Last commit: (none - new branch)

Summary:
--------
Total worktrees: 4 (1 main + 3 feature)
Worktrees with changes: 2
Worktrees ready to merge: 1 (refactor-db is clean)

Recommendations:
- feature-auth: Commit your changes before merging
- refactor-db: Ready to merge! Use /worktree-merge
- fix-bug-123: Commit your changes
```

## Implementation Commands

Run these commands to gather the status:

```bash
# List all worktrees
git worktree list

# For each worktree directory:
cd trees/<worktree-name>
git status -s                           # Show modified files
git log --oneline -1                   # Last commit
git rev-list --left-right --count HEAD...origin/main  # Commits ahead/behind
cd -
```

## Status Indicators

Use these indicators for clarity:
- ✅ Clean - no uncommitted changes
- ⚠️  Modified - uncommitted changes present
- 🔄 Ahead - commits not yet merged to main
- ⬇️ Behind - main has commits this branch doesn't have
- 🚀 Ready - clean status, ready to merge

## Notes

- This command is useful before deciding which worktrees to merge
- Helps identify stale worktrees that should be cleaned up
- Shows overall parallel development progress
- Use before running `/worktree-merge` to ensure worktrees are in good state

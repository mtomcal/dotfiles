---
description: Merge a completed git worktree back to main branch
---

Merge a completed git worktree back to the main branch and clean up the worktree. This command helps you safely integrate work done in a parallel worktree.

## Your Task

1. **Identify which worktree to merge**
   - If user didn't specify, list available worktrees: `wtp list` or `git worktree list`
   - Ask user which worktree/branch they want to merge

2. **Check the worktree status**
   - Verify no uncommitted changes: `cd trees/<branch-name> && git status`
   - If there are uncommitted changes, ask user to commit or stash them first

3. **Run tests if applicable**
   - If the project has tests, suggest running them first
   - Ask user: "Should I run tests before merging? (project-specific test command)"

4. **Switch to main branch and update**
   ```bash
   git checkout main
   git pull origin main
   ```

5. **Merge the worktree branch**
   ```bash
   git merge <branch-name>
   ```

6. **Handle merge conflicts if they occur**
   - If conflicts exist, inform the user and list conflicted files
   - Offer to help resolve conflicts
   - After resolution: `git add . && git commit`

7. **Ask about pushing**
   - Ask: "Would you like to push these changes to remote? (y/n)"
   - If yes: `git push origin main`

8. **Clean up the worktree**
   - Run: `wtp delete <branch-name>`
   - Or manually: `git worktree remove trees/<branch-name>` then `git branch -d <branch-name>`

9. **Confirm completion**
   - Show final git status
   - List remaining worktrees: `wtp list`

## Important Checks

**Before merging:**
- ✅ Worktree has no uncommitted changes
- ✅ All changes are committed and pushed to worktree branch
- ✅ Tests pass (if applicable)
- ✅ Main branch is up to date

**Safety features:**
- Always update main before merging (git pull)
- Check git status before deleting worktree
- Offer to keep worktree if merge has conflicts

## Example

User: "Merge the authentication feature worktree"

Your response:
```
I'll merge the feature-authentication worktree back to main.

Step 1: Checking worktree status...
[Runs: cd trees/feature-authentication && git status]
✓ No uncommitted changes

Step 2: Switching to main branch and updating...
[Runs: git checkout main && git pull origin main]
✓ Main branch is up to date

Step 3: Merging feature-authentication into main...
[Runs: git merge feature-authentication]
✓ Merge successful (no conflicts)

Step 4: Would you like to push these changes to remote? (y/n)
[Waits for user response]

[If user says yes]
Pushing to remote...
[Runs: git push origin main]
✓ Changes pushed successfully

Step 5: Cleaning up worktree...
[Runs: wtp delete feature-authentication]
✓ Worktree removed
✓ Branch deleted

Merge complete!

Summary:
- Branch 'feature-authentication' merged into main
- Changes pushed to remote
- Worktree cleaned up

Remaining active worktrees:
[Runs: wtp list]
```

## Merge Conflict Resolution

If conflicts occur:
```
⚠ Merge conflicts detected!

Conflicted files:
- src/auth/login.js
- src/auth/middleware.js

To resolve:
1. I can help review each conflict
2. You can manually edit the files
3. After resolving: git add . && git commit

Would you like me to read the conflicted files and suggest resolutions?
```

## Notes

- Always merge FROM main worktree, not from within the feature worktree
- Keep the worktree until merge is confirmed successful
- If merge is complex, consider creating a PR instead of direct merge
- For remote repositories, consider: `git push origin <branch-name>` before merging to create a PR
- Works in both Plan and Build modes

---
description: List all active git worktrees
---

Display all active git worktrees in the repository, showing their locations and branches.

## Your Task

1. **List all worktrees**
   - Run: `wtp list` (if wtp is available)
   - Or run: `git worktree list`

2. **Format the output clearly**
   - Show each worktree's path
   - Show which branch each worktree is on
   - Indicate the main worktree

3. **Provide helpful context**
   - Count total active worktrees
   - Suggest next actions if needed

## Example Output

```
Active worktrees:

/home/user/project                    [main]         (main worktree)
/home/user/project/trees/feature-auth [feature-auth]
/home/user/project/trees/refactor-db  [refactor-db]
/home/user/project/trees/fix-bug-123  [fix-bug-123]

Total: 4 worktrees (1 main + 3 feature worktrees)

Tip: Each worktree can run its own Claude Code instance for parallel development.
```

## Additional Information

If the user wants more detail, you can also show:

**Worktree status:**
```bash
for dir in trees/*/; do
  echo "=== $(basename $dir) ==="
  cd "$dir" && git status -s
  cd - > /dev/null
done
```

**Disk usage:**
```bash
du -sh trees/*
```

## Notes

- Main worktree is always listed first (the project root)
- Feature worktrees are typically in the `trees/` directory
- A branch can only be checked out in one worktree at a time
- Use `/worktree-status` for more detailed status of each worktree

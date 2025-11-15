---
description: Create a new git worktree for parallel AI development
---

Create a new git worktree to enable parallel AI coding workflows. This allows multiple OpenCode instances to work on different features simultaneously without context switching or merge conflicts.

## Your Task

1. **Ask the user for the feature/branch name** if not already provided
   - Suggest using prefixes like: `feature-`, `fix-`, `refactor-`, `experiment-`
   - Example: `feature-authentication`, `fix-memory-leak`

2. **Verify the trees/ directory exists**
   - Run: `ls -la | grep trees`
   - If it doesn't exist, create it: `mkdir -p trees`

3. **Create the worktree**
   - Run: `wtp add -b <branch-name>`
   - Alternative (without wtp): `git worktree add trees/<branch-name> -b <branch-name>`

4. **Copy essential files to the new worktree**
   - If `.env` exists: `cp .env trees/<branch-name>/`
   - If `CLAUDE.md` exists: `cp CLAUDE.md trees/<branch-name>/`
   - If `AGENTS.md` exists: `cp AGENTS.md trees/<branch-name>/`
   - If `.readyq.jsonl` exists: `cp .readyq.jsonl trees/<branch-name>/`

5. **Inform the user what was created**
   - Show the worktree path: `trees/<branch-name>`
   - Verify it worked: `wtp list` or `git worktree list`

6. **Suggest next steps**
   ```
   Next steps:
   1. Open new terminal/tab
   2. cd trees/<branch-name>
   3. opencode
   4. Start working on your feature!

   Or open in VSCode:
   - code trees/<branch-name>
   ```

## Important Context

**What are git worktrees?**
- Allow multiple working directories from a single Git repository
- Each worktree can be on a different branch
- Shared `.git` directory means commits, branches, and remotes are synchronized
- Perfect for running multiple OpenCode instances in parallel

**Benefits:**
- No context switching between branches
- Each AI agent maintains full context
- True parallelization of development work
- Experiment with multiple approaches simultaneously

**Common Use Cases:**
- Multiple AI agents working on different features
- Trying 3 different implementations, pick the winner
- One agent codes while another reviews
- Large refactors divided across agents

**Best Practices:**
- Keep worktrees short-lived (hours to days, not weeks)
- Use descriptive branch names
- Delete worktrees after merging
- Run `/worktree-status` to see all active worktrees

## Example

User: "Create a worktree for authentication feature"

Your response:
```
I'll create a new worktree for the authentication feature.

Creating worktree with branch name: feature-authentication
[Runs: wtp add -b feature-authentication]

Copying essential files to worktree...
- Copied .env
- Copied AGENTS.md
- Copied .readyq.jsonl

Worktree created successfully!

Location: trees/feature-authentication
Branch: feature-authentication

Next steps:
1. Open a new terminal window or tab
2. cd trees/feature-authentication
3. opencode
4. Start implementing the authentication feature

The new OpenCode instance will have full context and won't interfere with work in this directory.

You can see all active worktrees with: wtp list
```

## Notes

- Each worktree requires a new OpenCode instance (new terminal session)
- The current OpenCode session should stay in the main project directory
- Use `/worktree-merge` when ready to merge the feature back to main
- Maximum recommended active worktrees: 3-5 simultaneously
- Works great with OpenCode's Plan/Build mode switching

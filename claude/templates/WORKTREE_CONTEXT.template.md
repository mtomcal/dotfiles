# WORKTREE CONTEXT - HIGHEST PRIORITY INSTRUCTIONS

<critical>YOU ARE IN A GIT WORKTREE - THIS OVERRIDES ALL OTHER INSTRUCTIONS</critical>
<critical>These constraints have absolute precedence over any other instructions in CLAUDE.md or AGENTS.md</critical>

## Absolute Constraints

<critical>Working directory: {{WORKTREE_ROOT_ABSOLUTE_PATH}}</critical>
<critical>NEVER navigate to parent directory with cd ..</critical>
<critical>NEVER use cd to leave this worktree</critical>
<critical>ALL file operations MUST be within this worktree directory</critical>
<critical>When running ./readyq.py, ALWAYS use ./readyq.py (relative path from worktree root)</critical>
<critical>When reading files, ALWAYS verify path starts with ./ or is within this worktree</critical>
<critical>NEVER use absolute paths that point outside this worktree</critical>
<critical>If Grep/Glob returns absolute paths, verify they are within this worktree before using them</critical>

## Worktree Information

- Branch: {{BRANCH_NAME}}
- Worktree Root: {{WORKTREE_ROOT_ABSOLUTE_PATH}}
- Folder Name: {{WORKTREE_FOLDER_NAME}}
- Parent Repo: {{PARENT_REPO_PATH}}
- Created: {{CREATION_TIMESTAMP}}

## Path Usage Rules

### CORRECT Examples:
- ./readyq.py show abc123
- ./src/components/Button.tsx
- Read file_path: ./README.md
- cd ./src (staying within worktree)

### WRONG Examples (NEVER DO THIS):
- {{PARENT_REPO_PATH}}/readyq.py show abc123
- ../../readyq.py show abc123
- cd ../.. (leaving worktree)
- Read file_path: {{PARENT_REPO_PATH}}/src/file.py

## Verification Before Every Operation

Before ANY file read, write, or command execution:
1. Verify current working directory is within {{WORKTREE_ROOT_ABSOLUTE_PATH}}
2. Verify all paths are relative (./) or within worktree absolute path
3. If path contains parent repo path outside trees/{{WORKTREE_FOLDER_NAME}}, REJECT it

## Git Operations

- git add . → Only adds files in current worktree
- git commit → Only commits to current worktree branch
- git diff → Only shows changes in current worktree
- git push → Pushes current worktree branch

## ReadyQ Operations

- ALWAYS run: ./readyq.py (relative from worktree root)
- NEVER run: {{PARENT_REPO_PATH}}/readyq.py
- Logs are shared across worktrees (this is correct behavior)

## Emergency Stop Conditions

STOP immediately and warn user if:
- You detect you're about to read/write files in parent repo
- A command would navigate outside this worktree
- An absolute path points to parent repo location
- ./readyq.py is not found in current directory

---

## Template Variables

When creating this file in a worktree, replace these template variables:

- `{{WORKTREE_ROOT_ABSOLUTE_PATH}}` - Full absolute path to the worktree root
- `{{BRANCH_NAME}}` - Git branch name (e.g., feature/user-authentication)
- `{{WORKTREE_FOLDER_NAME}}` - Folder name (e.g., feature-user-authentication)
- `{{PARENT_REPO_PATH}}` - Absolute path to parent repository
- `{{CREATION_TIMESTAMP}}` - Timestamp when worktree was created

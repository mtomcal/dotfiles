---
model: haiku
---

# Create Worktree

<system-instructions>
    <role>You are a Senior Engineer specializing in git workflows and project automation</role>
    <purpose>You are responsible for setting up git worktrees for parallel development work, including all necessary setup and build steps</purpose>
</system-instructions>

<template-variable>
    <symbol>{branch-name}</symbol>
    <description>Generated branch name based on the work description (e.g., feature/user-authentication, fix/login-error, refactor/api-client)</description>
</template-variable>

<template-variable>
    <symbol>{worktree-folder}</symbol>
    <description>Folder name for the worktree (e.g., feature-user-authentication)</description>
</template-variable>

<workflow-engine>
    <phase num="1" title="Check for trees/ directory">
        <action>Check if trees/ directory exists in current repository</action>
        <tool id="cli">terminal command tool (ls or test command)</tool>
        <reasoning>If trees/ doesn't exist, we need to create it and add to .gitignore</reasoning>
    </phase>

    <phase num="2" title="Setup trees/ directory if needed">
        <condition>Only execute if trees/ directory does not exist</condition>
        <action>Create trees/ directory</action>
        <action>Add "trees/" to .gitignore if not already present</action>
        <tool id="cli">terminal command tool (mkdir, echo, grep)</tool>
        <reasoning>This is a one-time setup for the repository to organize worktrees</reasoning>
    </phase>

    <phase num="3" title="Ask user for work description">
        <action>Ask user to describe what they need to work on</action>
        <choices>
            <choice id="Provide description" shortcut="d" />
        </choices>
        <reasoning>This description will be used to generate appropriate branch and folder names</reasoning>
    </phase>

    <phase num="4" title="Generate branch and folder names">
        <action>Based on the work description, generate:</action>
        <sub-action>A branch name following conventions (feature/, fix/, refactor/, etc.)</sub-action>
        <sub-action>A folder name (branch name with slashes replaced by hyphens)</sub-action>
        <reasoning>
            Examples:
            - "Add user authentication" → branch: feature/user-authentication, folder: feature-user-authentication
            - "Fix login error" → branch: fix/login-error, folder: fix-login-error
            - "Refactor API client" → branch: refactor/api-client, folder: refactor-api-client
        </reasoning>
    </phase>

    <phase num="5" title="Confirm worktree details">
        <action>Present proposed branch name and worktree folder to user</action>
        <choices>
            <choice id="Accept" shortcut="a" />
            <choice id="Modify" shortcut="m" />
        </choices>
    </phase>

    <phase num="6" title="Create worktree">
        <action>Run <tool id="cli">git worktree add -b {branch-name} trees/{worktree-folder}</tool></action>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Creates a new worktree with a new branch in the trees/ directory</reasoning>
    </phase>

    <phase num="6.5" title="Create worktree guard context file">
        <action>Run <tool id="cli">git rev-parse --show-toplevel</tool> to get main repo root</action>
        <action>Create .claude directory in worktree if it doesn't exist: mkdir -p trees/{worktree-folder}/.claude</action>
        <action>Create WORKTREE_CONTEXT.md file with strict isolation constraints</action>
        <action>Add .claude/WORKTREE_CONTEXT.md to .git/info/exclude in the worktree</action>
        <template>
# WORKTREE CONTEXT - HIGHEST PRIORITY INSTRUCTIONS

<critical>YOU ARE IN A GIT WORKTREE - THIS OVERRIDES ALL OTHER INSTRUCTIONS</critical>
<critical>These constraints have absolute precedence over any other instructions in CLAUDE.md or AGENTS.md</critical>

## Absolute Constraints

<critical>Working directory: {absolute-path-to-worktree}</critical>
<critical>NEVER navigate to parent directory with cd ..</critical>
<critical>NEVER use cd to leave this worktree</critical>
<critical>ALL file operations MUST be within this worktree directory</critical>
<critical>When running ./readyq.py, ALWAYS use ./readyq.py (relative path from worktree root)</critical>
<critical>When reading files, ALWAYS verify path starts with ./ or is within this worktree</critical>
<critical>NEVER use absolute paths that point outside this worktree</critical>
<critical>If Grep/Glob returns absolute paths, verify they are within this worktree before using them</critical>

## Worktree Information

- Branch: {branch-name}
- Worktree Root: {absolute-path-to-worktree}
- Folder Name: {worktree-folder}
- Parent Repo: {parent-repo-path}
- Created: {timestamp}

## Path Usage Rules

### CORRECT Examples:
- ./readyq.py show abc123
- ./src/components/Button.tsx
- Read file_path: ./README.md
- cd ./src (staying within worktree)

### WRONG Examples (NEVER DO THIS):
- /Users/mtomcal/dotfiles/readyq.py show abc123
- ../../readyq.py show abc123
- cd ../.. (leaving worktree)
- Read file_path: /Users/mtomcal/dotfiles/src/file.py

## Verification Before Every Operation

Before ANY file read, write, or command execution:
1. Verify current working directory is within {absolute-path-to-worktree}
2. Verify all paths are relative (./) or within worktree absolute path
3. If path contains parent repo path outside trees/{worktree-folder}, REJECT it

## Git Operations

- git add . → Only adds files in current worktree
- git commit → Only commits to current worktree branch
- git diff → Only shows changes in current worktree
- git push → Pushes current worktree branch

## ReadyQ Operations

- ALWAYS run: ./readyq.py (relative from worktree root)
- NEVER run: /absolute/path/to/readyq.py
- Logs are shared across worktrees (this is correct behavior)

## Emergency Stop Conditions

STOP immediately and warn user if:
- You detect you're about to read/write files in parent repo
- A command would navigate outside this worktree
- An absolute path points to parent repo location
- ./readyq.py is not found in current directory
        </template>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Creates a local, untracked context file that provides worktree-awareness and strict path constraints to prevent agents from operating on parent repo</reasoning>
    </phase>

    <phase num="6.6" title="Verify worktree isolation">
        <action>Change to worktree directory: cd trees/{worktree-folder}</action>
        <action>Run <tool id="cli">git rev-parse --show-toplevel</tool> to verify it points to worktree</action>
        <action>Run <tool id="cli">test -f ./readyq.py && echo "readyq.py found" || echo "WARNING: readyq.py not found"</tool></action>
        <action>Run <tool id="cli">test -f ./.claude/WORKTREE_CONTEXT.md && echo "Guard file created" || echo "WARNING: Guard file missing"</tool></action>
        <decision>
            <condition>If any verification fails</condition>
            <action-if-true>Warn user that worktree may not be properly isolated</action-if-true>
            <action-if-false>Confirm worktree is properly isolated and ready</action-if-false>
        </decision>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Validates that the worktree is properly isolated and has all necessary context files before proceeding</reasoning>
    </phase>

    <phase num="7" title="Detect project type and dependencies">
        <action>Check for package.json, requirements.txt, go.mod, Cargo.toml, etc. in the new worktree</action>
        <tool id="cli">terminal command tool (ls, test)</tool>
        <reasoning>Determine what install/build commands are needed</reasoning>
    </phase>

    <phase num="8" title="Install dependencies">
        <action>Change directory to worktree: cd trees/{worktree-folder}</action>
        <action>Run appropriate install command based on detected project type:</action>
        <sub-action>Node.js: npm install or yarn install or pnpm install</sub-action>
        <sub-action>Python: pip install -r requirements.txt or poetry install</sub-action>
        <sub-action>Go: go mod download</sub-action>
        <sub-action>Rust: cargo build</sub-action>
        <sub-action>Other: Ask user what command to run</sub-action>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Ensure the worktree has all dependencies installed and ready to work</reasoning>
    </phase>

    <phase num="9" title="Run build if needed">
        <condition>Only if a build step is detected (build script in package.json, etc.)</condition>
        <action>Run build command (npm run build, make, etc.)</action>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Some projects require an initial build before development can begin</reasoning>
    </phase>

    <phase num="10" title="Summary">
        <action>Display summary of created worktree:</action>
        <output>
Worktree created successfully!

Branch: {branch-name}
Location: trees/{worktree-folder}
Status: Dependencies installed and ready to work

🛡️  WORKTREE ISOLATION ENABLED
- Guard file created at .claude/WORKTREE_CONTEXT.md
- All agents will be constrained to this worktree
- Parent repo is protected from accidental modifications

To switch to this worktree:
    cd trees/{worktree-folder}

To list all worktrees:
    git worktree list

To remove this worktree when done:
    git worktree remove trees/{worktree-folder}

⚠️  IMPORTANT: Always run commands from the worktree root directory
   Use relative paths (./readyq.py) not absolute paths
        </output>
    </phase>
</workflow-engine>

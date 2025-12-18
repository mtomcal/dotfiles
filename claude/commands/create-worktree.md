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

<template-variable>
    <symbol>{repo-name}</symbol>
    <description>The name of the current repository, extracted from the git root path (e.g., if repo is at /Users/dev/my-project, then {repo-name} = "my-project")</description>
</template-variable>

<workflow-engine>
    <phase num="1" title="Determine worktree parent directory">
        <action>Get the current repository root: git rev-parse --show-toplevel</action>
        <action>Get the repository name from the root path using basename command</action>
        <action>Set worktree parent directory to sibling of current repo: ../{repo-name}-worktrees/</action>
        <tool id="cli">terminal command tool (git rev-parse, basename)</tool>
        <reasoning>Worktrees are stored in a sibling directory to prevent AI agents from navigating into parent project. Example: if repo is "dotfiles", create "../dotfiles-worktrees/"</reasoning>
    </phase>

    <phase num="2" title="Setup worktree parent directory if needed">
        <condition>Only execute if worktree parent directory does not exist</condition>
        <action>Create worktree parent directory: ../{repo-name}-worktrees/</action>
        <tool id="cli">terminal command tool (mkdir -p)</tool>
        <reasoning>This is a one-time setup for the repository to organize worktrees in a sibling directory. The {repo-name} is dynamically determined in phase 1.</reasoning>
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
        <action>Run <tool id="cli">git worktree add -b {branch-name} ../{repo-name}-worktrees/{worktree-folder}</tool></action>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Creates a new worktree with a new branch in the sibling worktrees directory. The {repo-name} is the actual repository name from phase 1.</reasoning>
    </phase>

    <phase num="6.5" title="Verify worktree setup">
        <action>Change to worktree directory: cd ../{repo-name}-worktrees/{worktree-folder}</action>
        <action>Run <tool id="cli">git rev-parse --show-toplevel</tool> to verify it points to worktree</action>
        <action>Run <tool id="cli">test -f ./readyq.py && echo "readyq.py found" || echo "WARNING: readyq.py not found"</tool></action>
        <decision>
            <condition>If readyq.py not found</condition>
            <action-if-true>Warn user that worktree may not be properly set up</action-if-true>
            <action-if-false>Confirm worktree is ready to use</action-if-false>
        </decision>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Validates that the worktree has all necessary files before proceeding. Sibling directory structure prevents AI agents from accidentally navigating into parent repo.</reasoning>
    </phase>

    <phase num="7" title="Detect project type and dependencies">
        <action>Check for package.json, requirements.txt, go.mod, Cargo.toml, etc. in the new worktree</action>
        <tool id="cli">terminal command tool (ls, test)</tool>
        <reasoning>Determine what install/build commands are needed</reasoning>
    </phase>

    <phase num="8" title="Install dependencies">
        <action>Change directory to worktree: cd ../{repo-name}-worktrees/{worktree-folder}</action>
        <action>Run appropriate install command based on detected project type:</action>
        <sub-action>Node.js: npm install or yarn install or pnpm install</sub-action>
        <sub-action>Python: pip install -r requirements.txt or poetry install</sub-action>
        <sub-action>Go: go mod download</sub-action>
        <sub-action>Rust: cargo build</sub-action>
        <sub-action>Other: Ask user what command to run</sub-action>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Ensure the worktree has all dependencies installed and ready to work. The {repo-name} is the actual repository name from phase 1.</reasoning>
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
Location: ../{repo-name}-worktrees/{worktree-folder}
Status: Dependencies installed and ready to work

🛡️  WORKTREE ISOLATION
- Worktrees are in sibling directory to prevent accidental parent repo access
- AI agents working in this worktree cannot accidentally navigate to parent repo

To switch to this worktree:
    cd ../{repo-name}-worktrees/{worktree-folder}

To list all worktrees:
    git worktree list

To remove this worktree when done:
    git worktree remove ../{repo-name}-worktrees/{worktree-folder}

⚠️  IMPORTANT: Always run commands from the worktree root directory
   Use relative paths (./readyq.py) not absolute paths
        </output>
    </phase>
</workflow-engine>

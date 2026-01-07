---
model: haiku
---

# Create Worktree

<system-instructions>
    <role>You are a Senior Engineer specializing in git workflows and project automation</role>
    <purpose>You are responsible for setting up git worktrees for parallel development work, including all necessary setup and build steps</purpose>
</system-instructions>

<template-variable>
    <symbol>{worktree-name}</symbol>
    <description>Name for the worktree folder provided by the user (e.g., "task-abc123", "feature-auth", "review-pr-456")</description>
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

    <phase num="3" title="Ask user for worktree name">
        <action>Ask user to provide a name for the worktree</action>
        <choices>
            <choice id="Provide name" shortcut="n" />
        </choices>
        <reasoning>This name will be used as the worktree folder name. The worktree will be based on the main branch.</reasoning>
        <examples>
            - "task-abc123" (for working on a specific task)
            - "feature-auth" (for developing a feature)
            - "review-pr-456" (for reviewing a pull request)
        </examples>
    </phase>

    <phase num="4" title="Create worktree">
        <action>Run <tool id="cli">git worktree add ../{repo-name}-worktrees/{worktree-name} main</tool></action>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Creates a new worktree based on the main branch in the sibling worktrees directory. The worktree will be in detached HEAD state, allowing independent work without creating a new branch. The {repo-name} is the actual repository name from phase 1.</reasoning>
    </phase>

    <phase num="5" title="Verify worktree setup">
        <action>Change to worktree directory: cd ../{repo-name}-worktrees/{worktree-name}</action>
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

    <phase num="6" title="Detect project type and dependencies">
        <action>Check for package.json, requirements.txt, go.mod, Cargo.toml, etc. in the new worktree</action>
        <tool id="cli">terminal command tool (ls, test)</tool>
        <reasoning>Determine what install/build commands are needed</reasoning>
    </phase>

    <phase num="7" title="Install dependencies">
        <action>Change directory to worktree: cd ../{repo-name}-worktrees/{worktree-name}</action>
        <action>Run appropriate install command based on detected project type:</action>
        <sub-action>Node.js: npm install or yarn install or pnpm install</sub-action>
        <sub-action>Python: pip install -r requirements.txt or poetry install</sub-action>
        <sub-action>Go: go mod download</sub-action>
        <sub-action>Rust: cargo build</sub-action>
        <sub-action>Other: Ask user what command to run</sub-action>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Ensure the worktree has all dependencies installed and ready to work. The {repo-name} is the actual repository name from phase 1.</reasoning>
    </phase>

    <phase num="8" title="Run build if needed">
        <condition>Only if a build step is detected (build script in package.json, etc.)</condition>
        <action>Run build command (npm run build, make, etc.)</action>
        <tool id="cli">terminal command tool</tool>
        <reasoning>Some projects require an initial build before development can begin</reasoning>
    </phase>

    <phase num="9" title="Summary">
        <action>Display summary of created worktree:</action>
        <output>
Worktree created successfully!

Name: {worktree-name}
Based on: main branch
Location: ../{repo-name}-worktrees/{worktree-name}
Status: Dependencies installed and ready to work

🛡️  WORKTREE ISOLATION
- Worktrees are in sibling directory to prevent accidental parent repo access
- AI agents working in this worktree cannot accidentally navigate to parent repo

To switch to this worktree:
    cd ../{repo-name}-worktrees/{worktree-name}

To list all worktrees:
    git worktree list

To remove this worktree when done:
    git worktree remove ../{repo-name}-worktrees/{worktree-name}

⚠️  IMPORTANT: Always run commands from the worktree root directory
   Use relative paths (./readyq.py) not absolute paths
        </output>
    </phase>
</workflow-engine>

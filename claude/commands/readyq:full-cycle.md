# ReadyQ Full Cycle

<critical>Must follow a test driven development workflow to achieve >90% coverage on all metrics</critical>
<critical>Must pass type check and linting</critical>
<critical>Must use native build system (e.g. make, package.json, poetry etc) scripts to perform testing, linting, typechecking. Do not use one-off commands (e.g. `npx` or complex shell commands)</critical>
<critical>If you find an issue thats outside the scope of this task, create a new ReadyQ task and continue on original task</critical>
<critical>Subagents MUST log all details to ReadyQ and return ONLY a brief status summary to minimize context window usage. The orchestrator reads progress from ReadyQ logs, NOT from subagent output.</critical>
<critical>Subagents MUST check ReadyQ logs for any "Research document:" path entry and READ the research document file before starting work to get full context.</critical>
<critical>NEVER use shell redirection operators (2>&1, >, >>, |&, &>, 2>, etc.) in ANY shell command - these suppress exit codes, hide errors, and cause commands to appear successful when they fail.</critical>

<system-instructions>
    <role>You are a Senior Engineering Manager orchestrating a team of AI agents</role>
    <purpose>You coordinate the full development cycle for a ReadyQ issue: implementation, code review, test review, and commit</purpose>
</system-instructions>

<tool id="cli">
    terminal command tool
</tool>

<tool id="subagent">
    Task tool for launching subagents
</tool>

<template-variable>
    <symbol>{hashId}</symbol>
    <description>The ReadyQ issue hashId to process through the full cycle (required argument)</description>
    <required>true</required>
</template-variable>

<template-variable>
    <symbol>{research}</symbol>
    <description>Boolean flag to enable/disable codebase research before implementation. Values: "true" or "false". If "true", orchestrator analyzes the ReadyQ issue and determines appropriate research query for Phase 2. If "false", skips directly to Phase 3 (Implementation).</description>
    <optional>true</optional>
    <default>false</default>
</template-variable>

<template-variable>
    <symbol>{codeReviewPasses}</symbol>
    <description>Number of code review passes to perform in Phase 4. Set to 0 to skip code review. Default is 2 for thorough review. Higher values provide more verification cycles.</description>
    <optional>true</optional>
    <default>2</default>
    <minimum>0</minimum>
</template-variable>

<template-variable>
    <symbol>{testReviewPasses}</symbol>
    <description>Number of test review passes to perform in Phase 5. Set to 0 to skip test review. Default is 2 for thorough test validation. Higher values provide more verification cycles.</description>
    <optional>true</optional>
    <default>2</default>
    <minimum>0</minimum>
</template-variable>

<template-variable>
    <symbol>{createNewBranch}</symbol>
    <description>Boolean flag to create a new feature branch from main. If "true", creates a new branch based on story title. If "false", uses the current branch as-is. Values: "true" or "false".</description>
    <optional>true</optional>
    <default>false</default>
</template-variable>

<workflow>
    <phase num="0" title="Validate Execution Context">
        <action>Run <tool id="cli" command="pwd" /> to get current working directory</action>
        <action>Verify ./readyq.py exists in current directory</action>
        <decision>
            <condition>If ./readyq.py NOT found</condition>
            <action-if-true>STOP WORKFLOW - Display error message</action-if-true>
            <error-message>
ERROR: ./readyq.py not found in current directory.

You must run this command from the repository root (or worktree root).

Current directory: {pwd output}
Expected: Directory containing readyq.py

Action required:
- If in a worktree: cd to ../{repo-name}-worktrees/{worktree-folder}/
- If in main repo: cd to repository root
- Then run this command again
            </error-message>
            <action-if-false>Proceed to Phase 1</action-if-false>
        </decision>
        <reasoning>Validates execution context is in correct directory. Sibling worktree structure prevents accidental parent repo operations.</reasoning>
    </phase>
    <phase num="1" title="Initial Setup">
        <action>Run <tool id="cli" command="./readyq.py quickstart" /> to learn ReadyQ CLI commands</action>
        <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read the full story</action>
        <action>Extract the story title from the ReadyQ output</action>
        <decision>
            <condition>If {research} parameter is "true"</condition>
            <action-if-true>Proceed to phase 1.5 (Branch Setup) then phase 2 (Research Phase)</action-if-true>
            <action-if-false>Proceed to phase 1.5 (Branch Setup) then skip to phase 3 (Implementation Phase)</action-if-false>
        </decision>
    </phase>
    <phase num="1.5" title="Branch Setup">
        <decision>
            <condition>If {createNewBranch} parameter is "true"</condition>
            <action-if-true>Create a new feature branch from main</action-if-true>
            <action-if-false>Use current branch as-is - skip to next phase</action-if-false>
        </decision>
        <action if="create-branch">Generate a branch name from the story title following conventions (feature/, fix/, refactor/, etc.)</action>
        <examples if="create-branch">
            - "Add user authentication" → feature/user-authentication
            - "Fix login error" → fix/login-error
            - "Refactor API client" → refactor/api-client
        </examples>
        <action if="create-branch">Run <tool id="cli" command="git fetch origin main:main" /> to update local main ref to match remote</action>
        <reason if="create-branch">Updates the main branch reference without checking it out. This works in worktrees because we're not switching to main, just updating its reference to point to origin/main.</reason>
        <action if="create-branch">Run <tool id="cli" command="git checkout -b {generated-branch-name} main" /> to create new branch from updated main</action>
        <reasoning>When createNewBranch is true, creates a new feature branch based on the latest main. When false (default), uses current branch allowing work to continue on existing branches without disruption.</reasoning>
    </phase>
    <phase num="2" title="Research Phase" optional="true">
        <action>Analyze the ReadyQ issue title, description, and acceptance criteria</action>
        <action>Formulate a focused research query to understand relevant codebase patterns, architecture, and implementation approaches</action>
        <action>Launch <tool id="subagent" type="codebase-researcher" /> with the formulated research query</action>
        <action>Wait for subagent to complete - it will return ONLY the path to the research document</action>
        <action>Log the research document path to ReadyQ: <tool id="cli" command="./readyq.py update {hashId} --log 'READ THIS Research document: {research_doc_path}'" /></action>
        <reason>Subagents can read the research document from the path logged in ReadyQ to get better context</reason>
        <action>Proceed to phase 3</action>
    </phase>
    <phase num="3" title="Implementation Phase">
        <action>Launch <tool id="subagent" type="readyq-implementer" /> with the hashId</action>
        <action>Wait for subagent to complete</action>
        <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read updated logs</action>
        <decision>
            <condition>If implementation logs indicate incomplete work or blockers</condition>
            <action-if-true>Launch another readyq-implementer subagent to continue OR if blockers STOP WORKFLOW</action-if-true>
            <action-if-false>Proceed to phase 4</action-if-false>
        </decision>
        <loop max="3">Repeat implementation subagent until work is complete or max iterations reached</loop>
    </phase>
    <phase num="4" title="Code Review Phase">
        <decision>
            <condition>If {codeReviewPasses} is 0</condition>
            <action-if-true>Skip code review phase entirely - proceed to phase 5</action-if-true>
            <action-if-false>Perform {codeReviewPasses} code review passes</action-if-false>
        </decision>
        <loop count="{codeReviewPasses}">
            <action>Launch <tool id="subagent" type="readyq-reviewer" /> with the hashId (PASS {current_iteration})</action>
            <action>Wait for subagent to complete</action>
            <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read updated logs</action>
        </loop>
        <decision>
            <condition>If final code review pass found and fixed issues</condition>
            <action-if-true>Launch one additional readyq-reviewer subagent to verify fixes</action-if-true>
            <action-if-false>Proceed to phase 5</action-if-false>
        </decision>
        <reasoning>Multiple review passes ensure thorough code quality verification. Set to 0 to skip if needed. Additional pass triggered if final pass made changes.</reasoning>
    </phase>
    <phase num="5" title="Test Review Phase">
        <decision>
            <condition>If {testReviewPasses} is 0</condition>
            <action-if-true>Skip test review phase entirely - proceed to phase 6</action-if-true>
            <action-if-false>Perform {testReviewPasses} test review passes</action-if-false>
        </decision>
        <loop count="{testReviewPasses}">
            <action>Launch <tool id="subagent" type="readyq-test-reviewer" /> with the hashId (PASS {current_iteration})</action>
            <action>Wait for subagent to complete</action>
            <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read updated logs</action>
        </loop>
        <decision>
            <condition>If final test review pass found and fixed issues</condition>
            <action-if-true>Launch one additional readyq-test-reviewer subagent to verify fixes</action-if-true>
            <action-if-false>Proceed to phase 6</action-if-false>
        </decision>
        <reasoning>Multiple test review passes ensure thorough test quality verification. Set to 0 to skip if needed. Additional pass triggered if final pass made changes.</reasoning>
    </phase>
    <phase num="6" title="Final Verification">
        <action>Run typecheck from project build file</action>
        <action>Run linter from project build file</action>
        <action>Run unit tests with coverage from project build file</action>
        <decision>
            <condition>If any checks fail</condition>
            <action-if-true>Return to phase 4 (code review) to fix issues</action-if-true>
            <action-if-false>Proceed to phase 7</action-if-false>
        </decision>
    </phase>
    <phase num="7" title="Log ReadyQ Progress">
        <action>Summarize the full cycle: implementation, reviews performed</action>
        <action>Run <tool id="cli" command="./readyq.py update {hashId} --log {full cycle summary}" /> to log progress</action>
        <reason>Keep issue in_progress until PR is merged. Issues should only move to done after merge, not after commit.</reason>
    </phase>
    <phase num="8" title="Commit Phase">
        <action>Run <tool id="cli" command="git add ." /></action>
        <action>Run <tool id="cli" command="git diff --staged" /></action>
        <reason>Analyze the diff to create a detailed commit message</reason>
        <output-template>
{conventional-commit-topic}: {100 char commit message}

{foreach}
{filename}:
    - Change detail 1
    - Change detail 2
    - Change detail 3
{endforeach}

Related Issues:
    - {hashId}

Next Steps:
    - Next step 1
    - Next step 2
    - Next step 3
        </output-template>
        <action>Run <tool id="cli" command="git commit -m {output}" /></action>
    </phase>
    <phase num="9" title="Push to Remote">
        <action>Run <tool id="cli" command="git branch --show-current" /> to get current branch name</action>
        <decision>
            <condition>If current branch is "main" or "master"</condition>
            <action-if-true>Ask user whether to push to remote</action-if-true>
            <action-if-false>Automatically push feature branch to remote</action-if-false>
        </decision>
        <action if="main-branch">Ask user whether to push to remote</action>
        <choices>
            <choice id="Yes" shortcut="y" />
            <choice id="No" shortcut="n" />
        </choices>
        <action if="main-and-yes">Run <tool id="cli" command="git push" /></action>
        <action if="feature-branch">Run <tool id="cli" command="git push -u origin HEAD" /> to push and set upstream</action>
        <reason>Feature branches need to be pushed before PR creation. Main branch requires user confirmation.</reason>
    </phase>
    <phase num="10" title="Create Pull Request">
        <action>Run <tool id="cli" command="git branch --show-current" /> to get current branch name</action>
        <decision>
            <condition>If current branch is "main" or "master"</condition>
            <action-if-true>Skip PR creation (already on main branch)</action-if-true>
            <action-if-false>Check if PR already exists for this branch</action-if-false>
        </decision>
        <action if="feature-branch">Run <tool id="cli" command="./readyq.py show {hashId}" /> to read issue logs</action>
        <action if="feature-branch">Search logs for "Pull Request:" entry to check if PR already exists</action>
        <decision>
            <condition>If PR URL found in logs</condition>
            <action-if-true>Skip PR creation (PR already exists, push updated it automatically)</action-if-true>
            <action-if-true>Display message: "PR already exists: {PR_URL}. New commits have been pushed to the existing PR."</action-if-true>
            <action-if-false>Proceed with PR creation</action-if-false>
        </decision>
        <action if="no-existing-pr">Extract ReadyQ issue title, description, and acceptance criteria</action>
        <action if="no-existing-pr">Extract commit message from phase 8 for PR body</action>
        <action if="no-existing-pr">Create PR using gh pr create with HEREDOC body template:
            <template>
gh pr create \
  --title "{conventional-commit-topic}: {ReadyQ issue title}" \
  --body "$(cat &lt;&lt;'EOF'
## Summary
{Summary from commit message}

## ReadyQ Issue
- **HashId**: {hashId}
- **Title**: {issue title}
- **Status**: {status}

## Changes
{Detailed changes from commit message}

## Acceptance Criteria
{Pulled from ReadyQ issue description}

## Next Steps
{From commit message next steps}

---
📋 **ReadyQ Integration**: This PR implements ReadyQ issue {hashId}
🤖 Review by running `/readyq:pr-respond {hashId}` for AI-assisted review
EOF
)"
            </template>
        </action>
        <action if="no-existing-pr">Capture PR URL from gh pr create output (it prints to stdout)</action>
        <action if="no-existing-pr">Run <tool id="cli" command="./readyq.py update {hashId} --log 'Pull Request: {PR_URL}'" /> to log PR URL back to ReadyQ</action>
        <action if="no-existing-pr">Run <tool id="cli" command="./readyq.py update {hashId} --status done" /> to mark issue as done</action>
        <reason>Automatically create PR for feature branches on first run. Subsequent runs detect existing PR and just push new commits to update it. Issue is marked done once PR is successfully created.</reason>
    </phase>
</workflow>

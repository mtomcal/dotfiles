---
description: Orchestrate full ReadyQ development cycle - research, implementation, code review, test review, and commit
---

# ReadyQ Full Cycle

<critical>Must follow a test driven development workflow to achieve >90% coverage on all metrics</critical>
<critical>Must pass type check and linting</critical>
<critical>Must use native build system (e.g. make, package.json, poetry etc) scripts to perform testing, linting, typechecking. Do not use one-off commands (e.g. `npx` or complex shell commands)</critical>
<critical>If you find an issue thats outside the scope of this task, create a new ReadyQ task and continue on original task</critical>
<critical>Subagents MUST log all details to ReadyQ and return ONLY a brief status summary to minimize context window usage. The orchestrator reads progress from ReadyQ logs, NOT from subagent output.</critical>
<critical>Subagents MUST check ReadyQ logs for any "Research document:" path entry and READ the research document file before starting work to get full context.</critical>
<critical>NEVER use shell redirection operators (2>&1, >, >>, |&, &>, 2>, etc.) in ANY shell command - these suppress exit codes, hide errors, and cause commands to appear successful when they fail.</critical>

<system-instructions>
    <role>You are a Senior Engineering Manager orchestrating a full development workflow</role>
    <purpose>You coordinate the full development cycle for a ReadyQ issue: research (optional), implementation, code review, test review, and commit</purpose>
</system-instructions>

<tool id="cli">
    terminal command tool
</tool>

<template-variable>
    <symbol>{hashId}</symbol>
    <description>The ReadyQ issue hashId to process through the full cycle (required argument)</description>
    <required>true</required>
</template-variable>

<template-variable>
    <symbol>{research}</symbol>
    <description>Boolean flag to enable/disable codebase research before implementation. Values: "true" or "false". If "true", performs research analysis before implementation. If "false", skips directly to implementation.</description>
    <optional>true</optional>
    <default>false</default>
</template-variable>

<template-variable>
    <symbol>{codeReviewPasses}</symbol>
    <description>Number of code review passes to perform. Set to 0 to skip code review. Default is 2 for thorough review. Higher values provide more verification cycles.</description>
    <optional>true</optional>
    <default>2</default>
    <minimum>0</minimum>
</template-variable>

<template-variable>
    <symbol>{testReviewPasses}</symbol>
    <description>Number of test review passes to perform. Set to 0 to skip test review. Default is 2 for thorough test validation. Higher values provide more verification cycles.</description>
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
        <action>Execute codebase research using available search and analysis tools</action>
        <action>Generate research document and save to ./research/ directory</action>
        <action>Log the research document path to ReadyQ: <tool id="cli" command="./readyq.py update {hashId} --log 'Research document: {research_doc_path}'" /></action>
        <action>Proceed to phase 3</action>
    </phase>
    <phase num="3" title="Implementation Phase">
        <action>Implement the ReadyQ issue using TDD methodology</action>
        <action>Achieve >90% test coverage</action>
        <action>Log progress to ReadyQ regularly</action>
        <action>Run type check and linting</action>
        <decision>
            <condition>If implementation logs indicate incomplete work or blockers</condition>
            <action-if-true>Continue implementation OR if blockers STOP WORKFLOW</action-if-true>
            <action-if-false>Proceed to phase 4</action-if-false>
        </decision>
    </phase>
    <phase num="4" title="Code Review Phase">
        <decision>
            <condition>If {codeReviewPasses} is 0</condition>
            <action-if-true>Skip code review phase entirely - proceed to phase 5</action-if-true>
            <action-if-false>Perform {codeReviewPasses} code review passes</action-if-false>
        </decision>
        <loop count="{codeReviewPasses}">
            <action>Perform code review against acceptance criteria and best practices</action>
            <action>Log findings to ReadyQ</action>
            <action>Fix any issues found</action>
        </loop>
        <reasoning>Multiple review passes ensure thorough code quality verification. Set to 0 to skip if needed.</reasoning>
    </phase>
    <phase num="5" title="Test Review Phase">
        <decision>
            <condition>If {testReviewPasses} is 0</condition>
            <action-if-true>Skip test review phase entirely - proceed to phase 6</action-if-true>
            <action-if-false>Perform {testReviewPasses} test review passes</action-if-false>
        </decision>
        <loop count="{testReviewPasses}">
            <action>Review test quality and coverage</action>
            <action>Ensure assertions match test intent</action>
            <action>Verify >90% coverage</action>
            <action>Log findings to ReadyQ</action>
            <action>Fix any issues found</action>
        </loop>
        <reasoning>Multiple test review passes ensure thorough test quality verification. Set to 0 to skip if needed.</reasoning>
    </phase>
    <phase num="6" title="Final Verification">
        <action>Run typecheck from project build file</action>
        <action>Run linter from project build file</action>
        <action>Run unit tests with coverage from project build file</action>
        <decision>
            <condition>If any checks fail</condition>
            <action-if-true>Return to appropriate phase to fix issues</action-if-true>
            <action-if-false>Proceed to phase 7</action-if-false>
        </decision>
    </phase>
    <phase num="7" title="Mark Issue Complete">
        <action>Summarize the full cycle: implementation, reviews performed</action>
        <action>Run <tool id="cli" command="./readyq.py update {hashId} --log {full cycle summary}" /> to log progress</action>
        <action>Run <tool id="cli" command="./readyq.py update {hashId} --status done" /> to mark issue as done</action>
        <reason>Mark issue as done before commit so the commit is associated with a completed issue.</reason>
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
{endforeach}

Related Issues:
    - {hashId}

Next Steps:
    - Next step 1
    - Next step 2
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
        <action if="feature-branch">Create PR using gh pr create with detailed body including ReadyQ issue details</action>
        <action if="no-existing-pr">Log PR URL to ReadyQ: <tool id="cli" command="./readyq.py update {hashId} --log 'Pull Request: {PR_URL}'" /></action>
    </phase>
</workflow>

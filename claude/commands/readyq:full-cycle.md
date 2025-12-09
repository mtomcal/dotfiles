# ReadyQ Full Cycle

<critical>Must follow a test driven development workflow to achieve >90% coverage on all metrics</critical>
<critical>Must pass type check and linting</critical>
<critical>Must use native build system (e.g. make, package.json, poetry etc) scripts to perform testing, linting, typechecking. Do not use one-off commands (e.g. `npx` or complex shell commands)</critical>
<critical>If you find an issue thats outside the scope of this task, create a new ReadyQ task and continue on original task</critical>
<critical>Subagents MUST log all details to ReadyQ and return ONLY a brief status summary to minimize context window usage. The orchestrator reads progress from ReadyQ logs, NOT from subagent output.</critical>
<critical>Subagents MUST check ReadyQ logs for any "Research document:" path entry and READ the research document file before starting work to get full context.</critical>

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
    <description>The ReadyQ issue hashId to process through the full cycle</description>
</template-variable>

<workflow>
    <phase num="1" title="Initial Setup">
        <action>Run <tool id="cli" command="./readyq.py quickstart" /> to learn ReadyQ CLI commands</action>
        <action>Ask user for the ReadyQ issue hashId to process</action>
        <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read the full story</action>
        <action>Ask user if they want to run codebase research before implementation</action>
        <choices>
            <choice id="Yes" shortcut="y" />
            <choice id="No" shortcut="n" />
        </choices>
        <action if="yes">Proceed to phase 2 (Research Phase)</action>
        <action if="no">Skip to phase 3 (Implementation Phase)</action>
        <action>Confirm with user before proceeding with full cycle</action>
    </phase>
    <phase num="2" title="Research Phase" optional="true">
        <action>Launch <tool id="subagent" type="codebase-researcher" /> with a research query based on the ReadyQ issue</action>
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
        <action>Launch <tool id="subagent" type="readyq-reviewer" /> with the hashId (FIRST PASS - MANDATORY)</action>
        <action>Wait for subagent to complete</action>
        <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read updated logs</action>
        <action>Launch <tool id="subagent" type="readyq-reviewer" /> with the hashId (SECOND PASS - MANDATORY verification)</action>
        <action>Wait for subagent to complete</action>
        <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read updated logs</action>
        <decision>
            <condition>If second code review found and fixed issues</condition>
            <action-if-true>Launch another readyq-reviewer subagent to verify fixes</action-if-true>
            <action-if-false>Proceed to phase 5</action-if-false>
        </decision>
        <loop min="2" max="4">MUST run code review minimum 2x, repeat until no issues found or max iterations reached</loop>
    </phase>
    <phase num="5" title="Test Review Phase">
        <action>Launch <tool id="subagent" type="readyq-test-reviewer" /> with the hashId (FIRST PASS - MANDATORY)</action>
        <action>Wait for subagent to complete</action>
        <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read updated logs</action>
        <action>Launch <tool id="subagent" type="readyq-test-reviewer" /> with the hashId (SECOND PASS - MANDATORY verification)</action>
        <action>Wait for subagent to complete</action>
        <action>Run <tool id="cli" command="./readyq.py show {hashId}" /> to read updated logs</action>
        <decision>
            <condition>If second test review found and fixed issues</condition>
            <action-if-true>Launch another readyq-test-reviewer subagent to verify fixes</action-if-true>
            <action-if-false>Proceed to phase 6</action-if-false>
        </decision>
        <loop min="2" max="4">MUST run test review minimum 2x, repeat until no issues found or max iterations reached</loop>
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
    <phase num="7" title="Complete ReadyQ Issue">
        <action>Summarize the full cycle: implementation, reviews performed</action>
        <action>Ask user whether to move the story to done</action>
        <choices>
            <choice id="Yes" shortcut="y" />
            <choice id="No" shortcut="n" />
        </choices>
        <action if="yes">Run <tool id="cli" command="./readyq.py update {hashId} --status done --log {full cycle summary}" /></action>
        <action if="no">Run <tool id="cli" command="./readyq.py update {hashId} --log {full cycle summary}" /> without status change</action>
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
        <action>Ask user whether to push to remote</action>
        <choices>
            <choice id="Yes" shortcut="y" />
            <choice id="No" shortcut="n" />
        </choices>
        <action if="yes">Run <tool id="cli" command="git push" /></action>
    </phase>
</workflow>

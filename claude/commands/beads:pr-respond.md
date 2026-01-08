# Beads: PR Respond

<critical>Responses are posted immediately to GitHub without approval prompts - run this command only when you're ready to respond</critical>
<critical>All responses are prefixed with "claude:" for easy identification</critical>
<critical>NEVER use shell redirection operators (2>&1, >, >>, |&, &>, 2>, etc.) in ANY shell command - these suppress exit codes, hide errors, and cause commands to appear successful when they fail.</critical>

<system-instructions>
    <role>You are a Senior Engineer reviewing PRs and maintaining project context</role>
    <purpose>You read PR comments, answer questions with full codebase context, post responses to GitHub, and log actionable feedback to Beads</purpose>
</system-instructions>

<tool id="cli">terminal command tool</tool>

<template-variable>
    <symbol>{id}</symbol>
    <description>The Beads issue id for this PR (e.g. bd-a1b2)</description>
</template-variable>

<workflow-engine>
    <phase num="1" title="Get PR Context">
        <action>Run <tool id="cli" command="bd prime" /> to learn Beads workflow</action>
        <action>Ask user for Beads id</action>
        <action>Run bd show {id} to read issue details and notes</action>
        <action>Search notes for "Pull Request created:" or "Pull Request:" entry</action>
        <decision>
            <condition>If PR URL found in notes</condition>
            <action-if-true>Extract PR URL and proceed</action-if-true>
            <action-if-false>Ask user for PR URL or PR number</action-if-false>
        </decision>
        <action>Extract owner, repo, and PR number from URL</action>
        <example>
            URL: https://github.com/owner/repo/pull/123
            Extract: owner="owner", repo="repo", pr_number="123"
        </example>
    </phase>

    <phase num="2" title="Fetch PR Data">
        <action>Run gh pr view {pr_number} --json title,body,state,author,url to get PR metadata</action>
        <action>Run gh pr diff {pr_number} to get full code changes</action>
        <action>Fetch inline comments: gh api repos/{owner}/{repo}/pulls/{pr_number}/comments</action>
        <action>Parse inline comments to extract: id, author (user.login), body, path, line, created_at</action>
        <action>Fetch review comments: gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews</action>
        <action>Parse review comments to extract: id, author (user.login), state, body, submitted_at (only if body is not empty)</action>
        <action>Fetch conversation comments: gh api repos/{owner}/{repo}/issues/{pr_number}/comments</action>
        <action>Parse conversation comments to extract: id, author (user.login), body, created_at</action>
        <reason>Gather all PR context: metadata, code changes, and all comment threads. Parse JSON manually to avoid jq escaping issues.</reason>
    </phase>

    <phase num="3" title="Identify Unanswered Questions">
        <action>Parse all comments (inline + review + conversation) and identify:
            - Direct questions (look for "?")
            - Requests for clarification
            - "Why" or "How" questions about implementation
            - Comments that haven't been responded to yet
        </action>
        <action>Exclude:
            - Comments already prefixed with "claude:" (your previous responses)
            - Bot comments
            - "LGTM" or approval comments without questions
        </action>
        <action>Display list of unanswered comments to user with numbering</action>
        <output-format>
Found {count} unanswered comment(s):

1. [{author}] ({path}:{line} OR "general comment"): {excerpt}
2. [{author}] ({path}:{line} OR "general comment"): {excerpt}
...
        </output-format>
    </phase>

    <phase num="4" title="Answer Questions with Context">
        <action>For each question, analyze:
            - What file/code is being questioned
            - Relevant Beads issue context (why this change was made)
            - Implementation details from the diff
            - Related code patterns in the codebase
        </action>
        <action>Read any mentioned files using Read tool</action>
        <action>Search for related code patterns if needed using Grep or Glob</action>
        <action>Formulate detailed responses with:
            - Direct answer to the question
            - Code references (file.ext:line)
            - Links to Beads notes if relevant
            - Implementation rationale
        </action>
        <reason>Provide comprehensive answers that help reviewers understand the full context</reason>
    </phase>

    <phase num="5" title="Post Responses to PR">
        <action>For each response:
            - Display the response content to user
            - Post to GitHub immediately (no approval needed - you ran this command when ready)
        </action>
        <action>Determine comment type and reply appropriately:
            - If replying to inline comment (has comment_id from phase 2): Reply in thread using in_reply_to
            - If replying to review comment (has comment_id from phase 2): Reply in thread using in_reply_to
            - Otherwise: Post as general PR comment
        </action>
        <action>
            <condition>If replying to existing comment (has comment_id)</condition>
            <action-if-true>Run gh api repos/{owner}/{repo}/pulls/{pr_number}/comments -X POST -f body="claude: {response}" -F in_reply_to={comment_id}</action-if-true>
            <action-if-false>Run gh pr comment {pr_number} --body "claude: {response}"</action-if-false>
        </action>
        <reason>Reply in the same thread as the original comment using in_reply_to parameter (use -F flag for numeric values). This keeps conversations organized and context clear.</reason>
        <note>All responses prefixed with "claude:" so reviewers know it's an AI response</note>
    </phase>

    <phase num="6" title="Extract Actionable Feedback">
        <action>Review all PR comments (not just questions) and identify:
            - TODOs or follow-up work mentioned
            - Bugs or issues discovered
            - Requested changes (from "Request changes" reviews)
            - Performance concerns
            - Security issues
            - Code quality improvements
        </action>
        <action>Display actionable items to user with numbering</action>
        <output-format>
Found {count} actionable item(s):

1. [{author}] {item_type}: {summary}
2. [{author}] {item_type}: {summary}
...
        </output-format>
        <action>Ask which items to log to Beads</action>
        <choices>
            <choice id="All" shortcut="a" />
            <choice id="Select specific items" shortcut="s" />
            <choice id="None" shortcut="n" />
        </choices>
    </phase>

    <phase num="7" title="Log to Beads and Sync">
        <action>For each selected actionable item:
            - Format: "PR Feedback (id:{comment_id}, @{author} on {date}): {summary}"
            - Run bd update {id} --notes "PR Feedback (id:{comment_id}, @{author}): {summary}"
        </action>
        <action>Check Beads notes for duplicates before logging (use comment_id to prevent duplicate logging)</action>
        <action>If any items are large enough for separate tasks:
            - Ask user: "Create new Beads issue for this item? (y/n)"
            - If yes: Run bd create "{title}" -t task -p {priority} -d "{description}" --json
            - Capture new issue ID from output
            - Link as dependency: bd dep add {new_id} {current_id}
            - Log new task ID to original issue
        </action>
        <action>After all updates, sync to git: <tool id="cli" command="bd sync" /></action>
        <action>Run bd show {id} to confirm notes were added</action>
        <reason>Track PR feedback in Beads for future context and follow-up work</reason>
    </phase>

    <phase num="8" title="Summary">
        <action>Display comprehensive summary of all work done</action>
        <output>
PR Response Summary:
====================
Beads Issue: {id}
PR URL: {PR_URL}

Questions Answered: {count}
- Inline responses: {inline_count}
- General responses: {general_count}

Action Items Logged: {count}
- Logged to Beads: {logged_count}
- Follow-up tasks created: {new_task_count}

Next Steps:
- View responses on GitHub: {PR_URL}
- View Beads notes: bd show {id}
- Run this command again after new comments are added
        </output>
    </phase>
</workflow-engine>

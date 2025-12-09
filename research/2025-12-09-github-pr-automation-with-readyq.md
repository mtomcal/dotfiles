---
date: 2025-12-09T15:43:53+0000
researcher: Claude Sonnet 4.5
topic: "Local-First GitHub PR Automation with ReadyQ (No API Key Required)"
tags: [research, codebase, github, readyq, pr-automation, local-first, gh-cli]
status: complete
---

# Research: GitHub PR Automation after ReadyQ Full Cycle + PR Comment Monitoring with Claude

**Date**: 2025-12-09T15:43:53+0000
**Researcher**: Claude Sonnet 4.5

## Research Question

How can I:
1. Open a PR on my GitHub repo automatically after `readyq:full-cycle` finishes?
2. Comment on the PR and have Claude respond with project context?
3. Have Claude add PR feedback as action items to the ReadyQ issue log?

## Summary

**Updated for Local-First Workflow** (no Anthropic API key required)

To integrate GitHub PR automation with your ReadyQ workflow, you'll need to:

1. **Extend `readyq:full-cycle` command** - Add a new phase after commit that uses `gh pr create` to automatically open a PR with ReadyQ context
2. **Create `/readyq:pr-respond` command** - Local Claude command that reads PR comments, answers questions with project context, and posts replies prefixed with `claude:`
3. **Integrate feedback logging** - The same command files actionable feedback directly to ReadyQ issue logs

The good news: All the pieces exist locally. ReadyQ has robust session logging, GitHub CLI (`gh`) provides full PR automation, and Claude Code can run locally to read/respond to PR comments without any GitHub Actions or API keys.

## Detailed Findings

### Component 1: ReadyQ CLI Capabilities

**File Reference**: `/Users/mtomcal/Code/readyq/readyq.py` (3,099 lines)

ReadyQ provides all the necessary logging infrastructure:

- **Session Logging**: `./readyq.py update {hashId} --log "message"` appends timestamped entries to task sessions
- **Multi-line Support**: Logs are XML-wrapped (`<log>content</log>`) and support full markdown
- **No GitHub Integration**: ReadyQ is intentionally standalone - no git/GitHub dependencies
- **JSON Output**: `./readyq.py show {hashId}` displays full task details including all session logs

**Key Insight**: ReadyQ's session logs are designed for exactly this use case - persistent memory across work sessions. You can log PR URLs, review comments, and action items.

### Component 2: GitHub CLI PR Automation

**Current State**: Your `readyq:full-cycle.md` command (lines 109-132) creates commits but doesn't open PRs.

**Solution**: Extend the workflow with a new phase between "Commit Phase" and "Push to Remote":

```yaml
<phase num="8.5" title="Create Pull Request">
    <action>Ask user whether to create a pull request</action>
    <choices>
        <choice id="Yes" shortcut="y" />
        <choice id="No" shortcut="n" />
    </choices>
    <action if="yes">Extract PR details from ReadyQ issue and commit message</action>
    <action if="yes">Run gh pr create with HEREDOC body including:
        - ReadyQ issue hashId and title
        - Summary of changes from commit message
        - Link to ReadyQ issue logs
        - Acceptance criteria from ReadyQ story
    </action>
    <action if="yes">Capture PR URL from gh pr create output</action>
    <action if="yes">Log PR URL back to ReadyQ: ./readyq.py update {hashId} --log "Pull Request created: {PR_URL}"</action>
</phase>
```

**GitHub CLI Command**:
```bash
gh pr create \
  --title "feat: {ReadyQ issue title}" \
  --body "$(cat <<'EOF'
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
{From commit message}

---
📋 **ReadyQ Integration**: This PR implements ReadyQ issue {hashId}
🤖 Review by mentioning @claude in comments for AI-assisted review
EOF
)"
```

**Key Implementation Notes**:
- `gh pr create` returns the PR URL on stdout - capture it with command substitution
- Use `--base main` if not on default branch
- Use `--draft` for work-in-progress PRs
- Store PR URL in ReadyQ logs for bidirectional linking

### Component 3: Local PR Interaction with Claude (No API Key Required)

**Approach**: Run Claude Code locally to read PR comments, answer questions, and post responses.

**Why Local-First**:
- ✅ No Anthropic API key required (uses your existing Claude Code subscription)
- ✅ Full project context available (AGENTS.md, ReadyQ logs, entire codebase)
- ✅ No GitHub Actions setup or secrets management
- ✅ Manual control over when Claude responds
- ✅ Can batch-process multiple comments in one session

**How It Works**:

1. **You comment on PR** - Add questions or feedback directly on GitHub PR
2. **Run local command** - Execute `/readyq:pr-respond {hashId}` from terminal
3. **Claude reads context**:
   - Fetches all PR comments via `gh api`
   - Reads PR diff via `gh pr diff`
   - Reads ReadyQ issue logs for implementation context
   - Reads project files mentioned in comments
4. **Claude responds**:
   - Answers your questions with code references
   - Posts responses to PR via `gh pr comment --body "claude: {response}"`
   - All responses prefixed with `claude:` for easy identification
5. **Claude logs actionable items**:
   - Identifies TODOs, change requests, bugs from comments
   - Logs to ReadyQ via `./readyq.py update {hashId} --log "Action: {item}"`

**Command Implementation**: `claude/commands/readyq:pr-respond.md`

```markdown
# ReadyQ: PR Respond

<system-instructions>
    <role>You are a Senior Engineer reviewing PRs and maintaining project context</role>
    <purpose>You read PR comments, answer questions with full codebase context, post responses to GitHub, and log actionable feedback to ReadyQ</purpose>
</system-instructions>

<tool id="cli">terminal command tool</tool>

<template-variable>
    <symbol>{hashId}</symbol>
    <description>The ReadyQ issue hashId for this PR</description>
</template-variable>

<workflow-engine>
    <phase num="1" title="Get PR Context">
        <action>Ask user for ReadyQ hashId</action>
        <action>Run ./readyq.py show {hashId} to read issue details and logs</action>
        <action>Search logs for "Pull Request created:" or "Pull Request:" entry</action>
        <decision>
            <condition>If PR URL found in logs</condition>
            <action-if-true>Extract PR URL and proceed</action-if-true>
            <action-if-false>Ask user for PR URL or PR number</action-if-false>
        </decision>
        <action>Extract owner, repo, and PR number from URL</action>
    </phase>

    <phase num="2" title="Fetch PR Data">
        <action>Run gh pr view {pr_number} --json title,body,state,author to get PR metadata</action>
        <action>Run gh pr diff {pr_number} to get full code changes</action>
        <action>Run gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --jq '.[] | {id: .id, author: .user.login, body: .body, path: .path, line: .line, created_at: .created_at}' to get inline comments</action>
        <action>Run gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --jq '.[] | select(.body != "") | {id: .id, author: .user.login, state: .state, body: .body, created_at: .submitted_at}' to get review comments</action>
        <reason>Gather all PR context: metadata, code changes, and all comment threads</reason>
    </phase>

    <phase num="3" title="Identify Unanswered Questions">
        <action>Parse all comments (inline + review) and identify:
            - Direct questions to you (look for "?")
            - Requests for clarification
            - "Why" or "How" questions about implementation
            - Comments that haven't been responded to yet
        </action>
        <action>Exclude:
            - Comments already prefixed with "claude:" (your previous responses)
            - Bot comments
            - "LGTM" or approval comments without questions
        </action>
        <action>Present list of unanswered comments to user</action>
    </phase>

    <phase num="4" title="Answer Questions with Context">
        <action>For each question, analyze:
            - What file/code is being questioned
            - Relevant ReadyQ issue context (why this change was made)
            - Implementation details from the diff
            - Related code patterns in the codebase
        </action>
        <action>Read any mentioned files using Read tool</action>
        <action>Formulate detailed responses with:
            - Direct answer to the question
            - Code references (file.ext:line)
            - Links to ReadyQ logs if relevant
            - Implementation rationale
        </action>
    </phase>

    <phase num="5" title="Post Responses to PR">
        <action>For each response:
            - Display the response content to user
            - Automatically post to GitHub
        </action>
        <action>
            <condition>If comment was inline (has path and line)</condition>
            <action-if-true>Run gh api repos/{owner}/{repo}/pulls/{pr_number}/comments -X POST -f body="claude: {response}" -f commit_id={latest_commit} -f path={path} -F line={line}</action-if-true>
            <action-if-false>Run gh pr comment {pr_number} --body "claude: {response}"</action-if-false>
        </action>
        <reason>Post responses directly to PR, prefixed with "claude:" for identification. No approval needed - command runs when you're ready to respond.</reason>
    </phase>

    <phase num="6" title="Extract Actionable Feedback">
        <action>Review all PR comments (not just yours) and identify:
            - TODOs or follow-up work mentioned
            - Bugs or issues discovered
            - Requested changes (from "Request changes" reviews)
            - Performance concerns
            - Security issues
        </action>
        <action>Present actionable items to user</action>
        <action>Ask which items to log to ReadyQ</action>
        <choices>
            <choice id="All" shortcut="a" />
            <choice id="Select specific items" shortcut="s" />
            <choice id="None" shortcut="n" />
        </choices>
    </phase>

    <phase num="7" title="Log to ReadyQ">
        <action>For each selected actionable item:
            - Format: "PR Feedback ({author} on {date}): {summary}"
            - Run ./readyq.py update {hashId} --log "PR Feedback ({author}): {summary}"
        </action>
        <action>If any items are large enough for separate tasks:
            - Ask user: "Create new ReadyQ task for this item? (y/n)"
            - If yes: Run ./readyq.py new "{title}" --description "{description}" --blocked-by {hashId}
            - Log new task ID to original issue
        </action>
        <action>Run ./readyq.py show {hashId} to confirm logs were added</action>
    </phase>

    <phase num="8" title="Summary">
        <action>Display summary:
            - Number of questions answered
            - Number of responses posted to PR
            - Number of action items logged to ReadyQ
            - New ReadyQ tasks created (if any)
        </action>
        <output>
PR Response Summary:
- Answered {count} questions
- Posted {count} responses to PR (all prefixed with "claude:")
- Logged {count} action items to ReadyQ issue {hashId}
- Created {count} follow-up ReadyQ tasks

View responses: {PR_URL}
View ReadyQ logs: ./readyq.py show {hashId}
        </output>
    </phase>
</workflow-engine>
```

**Key Features**:
- **Context-Aware**: Reads ReadyQ logs to understand *why* changes were made, not just *what* changed
- **Batch Processing**: Handles all unanswered comments in one session
- **Automatic Posting**: Responses are posted immediately (you control when to run the command)
- **Actionable Logging**: Automatically identifies and logs follow-up work to ReadyQ
- **Inline + General**: Supports both inline code comments and general PR comments
- **Deduplication**: Skips comments already prefixed with `claude:` to avoid redundant responses

### Component 4: GitHub CLI Commands Reference

Essential `gh` CLI commands used in the `/readyq:pr-respond` workflow:

**PR Metadata**:
```bash
# Get PR details as JSON
gh pr view 123 --json title,body,state,author,createdAt,url

# Get PR URL
gh pr view 123 --json url --jq '.url'
```

**PR Code Changes**:
```bash
# View full diff
gh pr diff 123

# Get diff as patch format
gh pr diff 123 --patch
```

**Fetch Comments**:
```bash
# Inline comments (on specific lines of code)
gh api repos/owner/repo/pulls/123/comments --jq '.[] | {id: .id, author: .user.login, body: .body, path: .path, line: .line, created_at: .created_at}'

# Review comments (general PR feedback)
gh api repos/owner/repo/pulls/123/reviews --jq '.[] | select(.body != "") | {id: .id, author: .user.login, state: .state, body: .body, created_at: .submitted_at}'

# Issue comments (on PR conversation tab)
gh api repos/owner/repo/issues/123/comments --jq '.[] | {id: .id, author: .user.login, body: .body, created_at: .created_at}'
```

**Post Comments**:
```bash
# Post general comment
gh pr comment 123 --body "claude: Your answer here"

# Post inline comment (requires commit SHA, file path, and line number)
gh api repos/owner/repo/pulls/123/comments \
  -X POST \
  -f body="claude: Your inline comment" \
  -f commit_id="abc123def456" \
  -f path="src/file.py" \
  -F line=42
```

**Extract PR Number from URL**:
```bash
# URL format: https://github.com/owner/repo/pull/123
pr_number=$(echo "$pr_url" | grep -oE '/pull/[0-9]+' | grep -oE '[0-9]+')
owner=$(echo "$pr_url" | sed -E 's|https://github.com/([^/]+)/.*|\1|')
repo=$(echo "$pr_url" | sed -E 's|https://github.com/[^/]+/([^/]+)/.*|\1|')
```

### Component 5: Architecture Insights

**Local-First Workflow Integration**:

```
┌─────────────────────────────────────────────────────────────┐
│                  readyq:full-cycle Command                   │
├─────────────────────────────────────────────────────────────┤
│ Phase 1-6: Research → Implement → Review → Test → Verify   │
│ Phase 7:   Complete ReadyQ Issue                            │
│ Phase 8:   Create Git Commit                                │
│ ▼ NEW PHASE 8.5: Create Pull Request                        │
│   - Run gh pr create with ReadyQ context                    │
│   - Log PR URL to ReadyQ issue                              │
│ Phase 9:   Push to Remote                                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Pull Request                       │
├─────────────────────────────────────────────────────────────┤
│ - PR Body includes ReadyQ hashId and acceptance criteria    │
│ - You (or teammates) add comments and questions             │
│ - PR is visible to all reviewers on GitHub                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│          /readyq:pr-respond Command (Local, Manual)          │
├─────────────────────────────────────────────────────────────┤
│ - You run this command locally when ready to respond        │
│ - Fetches all PR comments via gh api                        │
│ - Reads PR diff and ReadyQ logs for full context            │
│ - Claude analyzes questions and drafts responses            │
│ - Posts responses to PR via gh pr comment (prefix: "claude:")│
│ - Identifies actionable feedback and logs to ReadyQ         │
│ - Creates follow-up ReadyQ tasks if needed                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   ReadyQ Session Logs                        │
├─────────────────────────────────────────────────────────────┤
│ - PR URL logged: "Pull Request: https://github.com/..."    │
│ - PR feedback logged: "PR Feedback (user): Fix edge case"  │
│ - Follow-up tasks created and linked via blocked_by        │
│ - Full context preserved for future work                    │
└─────────────────────────────────────────────────────────────┘
```

**Bidirectional Context Flow**:

```
                    ┌─────────────┐
                    │ ReadyQ Issue│
                    └──────┬──────┘
                           │
                           ▼
                  ┌────────────────┐
                  │  Git Commit    │
                  └────────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
                  │ PR Created     │◄──────┐
                  │ (gh pr create) │       │
                  └────────┬───────┘       │
                           │               │
                           ▼               │
              ┌────────────────────────┐   │
              │ GitHub PR with Comments│   │
              └────────────┬───────────┘   │
                           │               │
                           ▼               │
          ┌────────────────────────────┐   │
          │ /readyq:pr-respond (local) │   │
          │ - Read comments via gh api │   │
          │ - Read ReadyQ logs ────────┼───┘
          │ - Answer with context      │
          │ - Post via gh pr comment   │
          └────────────┬───────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Update ReadyQ   │
              │ - Log feedback  │
              │ - Create tasks  │
              └─────────────────┘
```

## Code References

### Existing Files to Modify

- `claude/commands/readyq:full-cycle.md:109-140` - Add PR creation phase after commit
- `claude/commands/commit.md:68-75` - Reference for push-to-remote pattern

### New Files to Create

- `claude/commands/readyq:pr-respond.md` - **Primary command** for reading PR comments, answering questions, and logging feedback to ReadyQ
- `claude/commands/readyq:create-pr.md` - Optional standalone PR creation command (if you want PR creation separate from full-cycle)

### External Dependencies

- **GitHub CLI (`gh`)** - Already installed per AGENTS.md
  - Used for: `gh pr create`, `gh pr view`, `gh pr comment`, `gh api`
  - Authentication: GitHub Personal Access Token (already configured)
- **ReadyQ** - Local task manager at `/Users/mtomcal/Code/readyq/readyq.py`
  - Used for: logging session data, tracking action items
- **jq** - JSON parser for processing `gh api` output (likely already installed)

**No API keys required** - Everything runs locally using your existing Claude Code subscription and `gh` CLI authentication.

## Architecture Insights

### Pattern: ReadyQ as Single Source of Truth

ReadyQ issues serve as the authoritative record of:
- **Implementation progress** (session logs from full-cycle workflow)
- **PR URL** (logged after creation via `gh pr create`)
- **Review feedback** (synced from PR comments via `/readyq:pr-respond`)
- **Follow-up tasks** (created with `blocked_by` relationships)

This enables:
1. **Context Preservation**: Future work can read full history from ReadyQ logs
2. **Offline Access**: ReadyQ is local markdown - no API rate limits or cloud dependencies
3. **Git-Friendly**: `.readyq.md` commits show task evolution over time
4. **AI Context**: Claude can read ReadyQ logs to understand *why* decisions were made

### Pattern: Local-First PR Interaction

Local command execution provides:
- **On-Demand Execution**: You decide when Claude responds to PR comments (run the command when ready)
- **Batch Processing**: Handle multiple comments in one session
- **Automatic Posting**: Responses are posted immediately after formulation (no approval prompts)
- **Full Context**: Claude reads entire codebase, ReadyQ logs, and PR diff
- **No API Costs**: Uses your existing Claude Code subscription
- **Privacy**: No code sent to GitHub Actions runners

Tradeoffs:
- **Not Real-Time**: Requires manual command invocation (not automated on every PR comment)
- **Local Only**: Must run from your development machine

**When to Run**: After PR reviewers add comments, or when you want to respond to questions with full project context. Running the command means you're ready to post responses.

## Implementation Checklist

### Phase 1: PR Creation Integration (Immediate)

- [ ] Modify `claude/commands/readyq:full-cycle.md`
  - [ ] Add phase 8.5 "Create Pull Request" after commit
  - [ ] Use `gh pr create` with HEREDOC body template
  - [ ] Include ReadyQ hashId, title, and acceptance criteria in PR body
  - [ ] Capture PR URL from command output
  - [ ] Log PR URL to ReadyQ: `./readyq.py update {hashId} --log "Pull Request: {URL}"`
- [ ] Test with a sample ReadyQ issue
  - [ ] Verify PR is created with correct title and body
  - [ ] Verify PR URL is logged to ReadyQ issue
  - [ ] Verify PR links back to ReadyQ context

### Phase 2: Local PR Response Command (Immediate)

- [ ] Create `claude/commands/readyq:pr-respond.md`
  - [ ] Implement 8-phase workflow from Component 3 in this research doc
  - [ ] Phase 1: Get PR Context (extract from ReadyQ logs or ask user)
  - [ ] Phase 2: Fetch PR Data via `gh api` (comments, reviews, diff)
  - [ ] Phase 3: Identify unanswered questions (exclude "claude:" prefixed comments)
  - [ ] Phase 4: Answer questions with full codebase context
  - [ ] Phase 5: Post responses via `gh pr comment` (prefix all with "claude:")
  - [ ] Phase 6: Extract actionable feedback (TODOs, bugs, change requests)
  - [ ] Phase 7: Log to ReadyQ and create follow-up tasks if needed
  - [ ] Phase 8: Display summary of work done
- [ ] Test dependencies
  - [ ] Verify `gh` CLI is installed: `gh --version`
  - [ ] Verify `gh` is authenticated: `gh auth status`
  - [ ] Verify `jq` is installed: `jq --version`
  - [ ] Test `gh api` access: `gh api user` (should return your GitHub user info)

### Phase 3: End-to-End Testing (Short-term)

- [ ] Create a test ReadyQ issue
  - [ ] Run `./readyq.py new "Test PR workflow" --description "Testing local PR response workflow"`
  - [ ] Note the hashId for testing
- [ ] Run full-cycle workflow
  - [ ] Implement a simple change (e.g., add a comment to a file)
  - [ ] Run `/readyq:full-cycle` with test hashId
  - [ ] Verify PR is created and URL is logged to ReadyQ
- [ ] Add test comments to PR
  - [ ] Go to GitHub PR and add a question: "Why did we use this approach?"
  - [ ] Add a change request: "Can we optimize this?"
  - [ ] Add an inline comment on a specific line
- [ ] Run PR response command
  - [ ] Run `/readyq:pr-respond` with test hashId
  - [ ] Verify Claude identifies all unanswered questions
  - [ ] Watch as responses are automatically posted to GitHub
  - [ ] Verify responses appear on GitHub PR with "claude:" prefix
  - [ ] Verify actionable items are logged to ReadyQ
  - [ ] Run `./readyq.py show {hashId}` to confirm logs
- [ ] Verify end-to-end flow
  - [ ] ReadyQ logs show PR URL
  - [ ] ReadyQ logs show PR feedback
  - [ ] GitHub PR shows Claude's responses
  - [ ] All responses are prefixed with "claude:"

### Phase 4: Optional Enhancements (Future)

- [ ] Create standalone `/readyq:create-pr` command
  - [ ] Separate PR creation from full-cycle for flexibility
  - [ ] Allow PR creation for any completed ReadyQ issue
  - [ ] Useful for creating PRs after manual commits outside full-cycle
- [ ] Add PR status tracking to ReadyQ
  - [ ] Create `/readyq:pr-status` command to check PR state
  - [ ] Log when PR is approved: `gh pr view {pr} --json reviewDecision`
  - [ ] Log when PR is merged: `gh pr view {pr} --json merged,mergedAt`
  - [ ] Could run manually or as part of cleanup workflow
- [ ] Batch PR response mode
  - [ ] Modify `/readyq:pr-respond` to handle multiple PRs
  - [ ] Useful for responding to several PRs in one session
  - [ ] Pass multiple hashIds or auto-discover PRs from ReadyQ logs
- [ ] Automated PR summary to ReadyQ
  - [ ] After PR merge, automatically log final review outcomes
  - [ ] Extract final review comments and update ReadyQ
  - [ ] Useful for post-mortems and future reference

## Open Questions

### Q1: Should PR creation be mandatory or optional in full-cycle?

**Current Design**: Phase 8.5 asks user "Create PR? (y/n)"

**Alternatives**:
- Always create PR (auto-merge for trivial changes)
- Create draft PR by default (`gh pr create --draft`)
- Skip PR for personal projects, require for team projects

**Recommendation**: Keep it optional with user prompt. Teams have different PR policies.

### Q2: How to handle multi-commit PRs?

**Scenario**: ReadyQ issue spans multiple commits across review iterations.

**Options**:
1. Create PR only on first commit, subsequent commits push to same branch
2. Log all commit SHAs to ReadyQ, create PR at end
3. Create draft PR early, convert to ready when issue is done

**Recommendation**: Option 3 - create draft PR in phase 8.5, then convert to ready-for-review in phase 7 (after "done" status).

### Q3: How to handle inline vs. general PR comments?

**Scenario**: Some comments are on specific lines of code (inline), others are general PR feedback.

**Options**:
1. Post all responses as general comments (simpler)
2. Match inline comments and respond inline (better context)
3. Let user choose per-response

**Recommendation**: Option 2 - detect if original comment had `path` and `line`, respond inline if possible. Fallback to general comment if inline fails.

**Implementation**: Use `gh api` POST to `/repos/{owner}/{repo}/pulls/{pr}/comments` for inline, `gh pr comment` for general.

### Q4: How to prevent duplicate logging?

**Scenario**: User runs `/readyq:pr-respond` multiple times on same PR.

**Solutions**:
- Check ReadyQ logs for existing "PR Feedback" entries with same author/body
- Add timestamps to compare against PR comment creation time
- Use comment ID in log message: "PR Feedback (id:123456, @user): ..."
- Skip comments already prefixed with "claude:" (your own responses)

**Recommendation**: Use comment ID in log message to enable deduplication. Also filter out "claude:" comments in phase 3.

## Resources and References

### GitHub CLI Documentation
- [gh pr create manual](https://cli.github.com/manual/gh_pr_create) - PR creation flags and options
- [gh api documentation](https://cli.github.com/manual/gh_api) - REST API access for fetching/posting comments
- [gh pr view manual](https://cli.github.com/manual/gh_pr_view) - Viewing PR details and JSON output
- [gh pr comment manual](https://cli.github.com/manual/gh_pr_comment) - Posting comments to PRs

### GitHub API Endpoints (via `gh api`)
- [REST API: Pull Request Comments](https://docs.github.com/en/rest/pulls/comments) - Inline comment endpoints
- [REST API: Pull Request Reviews](https://docs.github.com/en/rest/pulls/reviews) - Review-level comment endpoints
- [REST API: Issue Comments](https://docs.github.com/en/rest/issues/comments) - General PR conversation comments

### Local Automation Patterns
- [GitHub CLI PR Automation Guide](https://smartscope.blog/en/Tools/github-cli-pr-automation-guide/) - 2025 guide to `gh pr` workflows
- [GitHub CLI Top Commands](https://adamj.eu/tech/2025/11/24/github-top-gh-cli-commands/) - Most useful `gh` commands
- [gh-prreview extension](https://github.com/chmouel/gh-prreview/) - Apply PR suggestions locally
- [gh pr view comments issue](https://github.com/cli/cli/issues/5788) - Limitations of built-in comment viewing

### ReadyQ Integration
- ReadyQ repository: `/Users/mtomcal/Code/readyq/` (local installation)
- Session logging: `./readyq.py update {hashId} --log "message"`
- Task creation: `./readyq.py new "title" --description "desc" --blocked-by {hashId}`

## Next Steps

1. **Implement PR Creation** - Extend `readyq:full-cycle.md` with phase 8.5 (30-60 minutes)
   - Add `gh pr create` with HEREDOC body template
   - Log PR URL to ReadyQ issue logs
   - Test with a sample issue
2. **Create Local PR Response Command** - Build `readyq:pr-respond.md` (1-2 hours)
   - Implement 8-phase workflow from Component 3
   - Test fetching comments via `gh api`
   - Test posting responses with "claude:" prefix
3. **End-to-End Testing** - Validate full workflow (1 hour)
   - Create test issue → run full-cycle → create PR
   - Add test comments → run pr-respond → verify responses posted
   - Verify ReadyQ logs show PR URL and feedback
4. **Refine and Optimize** - Based on real usage
   - Improve comment filtering logic
   - Optimize response formatting
   - Add convenience features (batch mode, status tracking)

**Priority Order**: Start with #1 (PR creation) since it's low-risk and immediately useful. Then #2 (local response command) which is the core innovation. Save #4 (optimizations) for after real-world usage reveals pain points.

**Estimated Total Time**: 3-4 hours for phases 1-3, iterative improvements as needed.

---

**Research Complete** - Local-first workflow designed, no API keys required, all components use existing tools (`gh` CLI, ReadyQ, Claude Code).

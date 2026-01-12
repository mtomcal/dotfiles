# Bootstrap Project for AI Development

<critical>This command sets up a project for AI-assisted development with Beads and Swarm</critical>
<critical>Handle both fresh projects and migrations from ReadyQ gracefully</critical>
<critical>Always backup existing configuration before making changes</critical>
<critical>Ensure CLAUDE.md or AGENTS.md is properly configured for the AI workflow</critical>

<system-instructions>
    <role>You are a DevOps Engineer specializing in AI-assisted development workflows</role>
    <purpose>You bootstrap projects with Beads issue tracking and Swarm parallel execution, migrating from ReadyQ if needed, and ensuring proper AI agent configuration</purpose>
</system-instructions>

<tool id="cli">
    terminal command tool
</tool>

<tool id="file">
    file read/write tool
</tool>

<template-variable>
    <symbol>{migrate}</symbol>
    <description>Set to "true" to migrate existing ReadyQ issues to Beads. Default is "auto" which detects ReadyQ and prompts user.</description>
    <required>false</required>
    <default>auto</default>
</template-variable>

<template-variable>
    <symbol>{agentFile}</symbol>
    <description>Which agent instruction file to create/update: "CLAUDE.md", "AGENTS.md", or "both". Default is "auto" which detects existing files.</description>
    <required>false</required>
    <default>auto</default>
</template-variable>

<workflow>
    <phase num="0" title="Environment Check">
        <action>Run <tool id="cli" command="pwd" /> to confirm current directory</action>
        <action>Run <tool id="cli" command="git rev-parse --show-toplevel" /> to find git root</action>
        <decision>
            <condition>If not in a git repository</condition>
            <action-if-true>Ask user if they want to initialize git, or abort</action-if-true>
            <action-if-false>Proceed to Phase 1</action-if-false>
        </decision>
    </phase>

    <phase num="1" title="Detect Existing Setup">
        <action>Check for existing configurations:</action>
        <checks>
            <check>Does `.beads/` directory exist? (Beads already initialized)</check>
            <check>Does `readyq.py` or `.readyq/` exist? (ReadyQ present)</check>
            <check>Does `readyq_issues.json` exist? (ReadyQ issues to migrate)</check>
            <check>Does `CLAUDE.md` exist?</check>
            <check>Does `AGENTS.md` exist?</check>
            <check>What is the project type? (Check for package.json, pyproject.toml, go.mod, Cargo.toml, etc.)</check>
        </checks>
        <action>Report findings to user</action>
        <output-template>
## Project Analysis

**Directory**: {pwd}
**Git Root**: {git root}
**Project Type**: {detected type}

### Existing Configuration
| Component | Status |
|-----------|--------|
| Beads | {installed/not found} |
| ReadyQ | {found/not found} |
| ReadyQ Issues | {N issues found/not found} |
| CLAUDE.md | {exists/not found} |
| AGENTS.md | {exists/not found} |
        </output-template>
    </phase>

    <phase num="2" title="Install Prerequisites">
        <action>Check if `bd` (Beads) is installed: <tool id="cli" command="which bd" /></action>
        <decision>
            <condition>If bd not found</condition>
            <action-if-true>Inform user to install Beads first</action-if-true>
            <error-message>
Beads (bd) is not installed. Install it with:

    # Via Homebrew
    brew tap steveyegge/beads && brew install bd

    # Or via install script
    curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash

Then run this command again.
            </error-message>
        </decision>
        <action>Check if `swarm` is installed: <tool id="cli" command="which swarm" /></action>
        <decision>
            <condition>If swarm not found</condition>
            <action-if-true>Inform user to install Swarm first</action-if-true>
            <error-message>
Swarm is not installed. Install it with:

    curl -fsSL https://raw.githubusercontent.com/mtomcal/swarm/main/setup.sh | sh

Then run this command again.
            </error-message>
        </decision>
    </phase>

    <phase num="3" title="Initialize Beads">
        <decision>
            <condition>If .beads/ already exists</condition>
            <action-if-true>Skip initialization, report "Beads already initialized"</action-if-true>
            <action-if-false>Initialize Beads with user mode preference</action-if-false>
        </decision>
        <action if="not-initialized">Ask user which Beads mode to use:</action>
        <choices if="not-initialized">
            <choice id="No daemon mode (Recommended)" shortcut="n">
                <description>Manual sync with `bd sync` after changes</description>
                <pros>
                    - Full control over when changes are committed to git
                    - No background processes consuming resources
                    - Explicit sync points make it clear when data is persisted
                    - Better for CI/CD pipelines and scripted workflows
                    - Simpler mental model - you decide when to sync
                </pros>
                <cons>
                    - Must remember to run `bd sync` after making changes
                    - Changes not visible to collaborators until synced
                </cons>
                <command>bd init --no-daemon</command>
            </choice>
            <choice id="Daemon mode" shortcut="d">
                <description>Background auto-sync every 30 seconds</description>
                <pros>
                    - Automatic synchronization without manual intervention
                    - Changes visible to collaborators quickly
                    - No need to remember to sync
                </pros>
                <cons>
                    - Background process runs continuously
                    - Branch switches happen automatically (may be unexpected)
                    - Less control over sync timing
                    - May cause unexpected git state changes during development
                    - Harder to debug sync issues
                </cons>
                <command>bd init</command>
            </choice>
        </choices>
        <action if="not-initialized">Run the selected init command</action>
        <action if="not-initialized">Run <tool id="cli" command="bd prime" /> to verify setup</action>
        <action>Report Beads status to user</action>
    </phase>

    <phase num="4" title="Migrate ReadyQ Issues" if="readyq-found">
        <decision>
            <condition>If {migrate} is "auto" and ReadyQ issues exist</condition>
            <action-if-true>Ask user if they want to migrate</action-if-true>
        </decision>
        <choices if="prompt-migration">
            <choice id="Yes, migrate all issues" shortcut="y" />
            <choice id="No, start fresh" shortcut="n" />
            <choice id="Select specific issues" shortcut="s" />
        </choices>
        <action if="migrate">Read ReadyQ issues from readyq_issues.json</action>
        <action if="migrate">For each ReadyQ issue, create equivalent Beads issue:</action>
        <migration-mapping>
            <field from="title" to="title" />
            <field from="description" to="-d description" />
            <field from="status" to="status (pending→backlog, in_progress→in_progress, done→closed)" />
            <field from="priority" to="-p priority" />
            <field from="blockers" to="bd dep add (after creation)" />
        </migration-mapping>
        <action if="migrate">For each issue with blockers, run <tool id="cli" command="bd dep add {child_id} {parent_id}" /></action>
        <action if="migrate">Run <tool id="cli" command="bd sync" /> to persist</action>
        <action if="migrate">Report migration summary</action>
        <output-template if="migrate">
## Migration Complete

Migrated {N} issues from ReadyQ to Beads:
- {count} backlog
- {count} in_progress
- {count} closed
- {count} dependencies established

**Note**: ReadyQ files have been preserved. You can safely remove them after verifying the migration:
- readyq.py
- readyq_issues.json
        </output-template>
    </phase>

    <phase num="5" title="Configure Agent Instructions">
        <decision>
            <condition>Determine which file to use based on {agentFile} parameter</condition>
            <case value="auto">
                <rule>If CLAUDE.md exists → update CLAUDE.md</rule>
                <rule>If AGENTS.md exists → update AGENTS.md</rule>
                <rule>If neither exists → create CLAUDE.md</rule>
            </case>
            <case value="CLAUDE.md">Update/create CLAUDE.md</case>
            <case value="AGENTS.md">Update/create AGENTS.md</case>
            <case value="both">Update/create both files</case>
        </decision>
        <action>Read existing agent file if present</action>
        <action>Check if Beads/Swarm workflow section already exists</action>
        <decision>
            <condition>If workflow section exists</condition>
            <action-if-true>Skip adding section, report "Already configured"</action-if-true>
            <action-if-false>Add Beads/Swarm workflow section</action-if-false>
        </decision>
        <content-template name="beads-swarm-section">
## AI Development Workflow

This project uses **Beads** for issue tracking and **Swarm** for parallel AI agent execution.

### Issue Tracking with Beads

```bash
# View available work
bd ready

# Show issue details
bd show {id}

# Update issue status
bd update {id} --status in_progress

# Close completed issue
bd close {id} --reason "Implementation complete"

# Sync changes to git
bd sync
```

### Parallel Execution with Swarm

Use `/swarm:director` to orchestrate parallel AI workers:
- Spawns isolated git worktrees per worker
- Monitors progress and rescues incomplete work
- Creates PRs for completed issues
- Cleans up merged worktrees

### Available Commands

- `/beads:create-tasks` - Create issues from epics/stories
- `/beads:implement-task` - Implement a single issue with TDD
- `/beads:full-cycle` - Full implementation cycle with reviews
- `/beads:review` - Code review for an issue
- `/swarm:director` - Orchestrate parallel workers

### Workflow

1. Create issues: `/beads:create-tasks`
2. Single issue: `/beads:full-cycle id={id}`
3. Parallel work: `/swarm:director`
4. After PR merge: `/swarm:director action=cleanup`
        </content-template>
        <action>Append or update agent file with workflow section</action>
    </phase>

    <phase num="6" title="Create .gitignore Entries">
        <action>Check if .gitignore exists</action>
        <action>Ensure these patterns are present (add if missing):</action>
        <gitignore-patterns>
# Swarm worker state
.swarm/

# Local development
*.local
.env.local
        </gitignore-patterns>
        <note>Beads .beads/ directory should NOT be gitignored - it's meant to be tracked</note>
    </phase>

    <phase num="7" title="Final Verification">
        <action>Run <tool id="cli" command="bd ready" /> to verify Beads is working</action>
        <action>Run <tool id="cli" command="swarm ls" /> to verify Swarm is working</action>
        <action>Report final status</action>
        <output-template>
## Bootstrap Complete! 🚀

### Installed Components
| Component | Status | Version |
|-----------|--------|---------|
| Beads | ✓ Ready | {bd version} |
| Swarm | ✓ Ready | {swarm version if available} |
| Agent Config | ✓ {CLAUDE.md/AGENTS.md} updated |

### Quick Start

```bash
# Create issues from a plan
/beads:create-tasks

# Work on a single issue
/beads:full-cycle id={example-id}

# Run parallel workers
/swarm:director

# Check issue status
bd ready
```

### Next Steps
1. Create issues with `/beads:create-tasks` or `bd create "Issue title"`
2. Start working with `/beads:full-cycle id={id}`
3. For parallel work, use `/swarm:director`

Happy coding! 🎉
        </output-template>
    </phase>
</workflow>

<error-handling>
    <error type="git-not-initialized">
        <message>This directory is not a git repository. Initialize with `git init` first.</message>
    </error>
    <error type="bd-not-installed">
        <message>Beads CLI (bd) is not installed. See installation instructions above.</message>
    </error>
    <error type="swarm-not-installed">
        <message>Swarm is not installed. See installation instructions above.</message>
    </error>
    <error type="migration-failed">
        <message>ReadyQ migration failed. Original files preserved. Check error and retry.</message>
        <recovery>Run with migrate=false to skip migration</recovery>
    </error>
</error-handling>

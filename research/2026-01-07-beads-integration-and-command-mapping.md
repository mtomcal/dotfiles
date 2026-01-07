---
date: 2026-01-07T00:00:00Z
researcher: codebase-researcher-agent
topic: "Beads Integration and ReadyQ Command Mapping"
tags: [research, beads, readyq, install, commands, dotfiles]
status: complete
---

# Research: Beads Integration and ReadyQ Command Mapping

**Date**: 2026-01-07
**Researcher**: codebase-researcher-agent

## Research Question

How to add beads (https://github.com/steveyegge/beads) as an install option in the dotfiles install.sh and create bead versions of all ReadyQ prompts with separate namespace (beads:*)?

## Summary

Beads (bd CLI) is a distributed, git-backed graph issue tracker designed for AI agents, similar in purpose to ReadyQ but with different architectural choices. Both systems provide task/issue management but with different CLIs and workflows. All 10 ReadyQ commands can be mapped to beads equivalents using the `beads:*` namespace. The install.sh modular architecture supports adding beads with multiple installation methods (Homebrew, npm, install script).

## Detailed Findings

### 1. Install.sh Modular Architecture

**Location**: `/home/mtomcal/dotfiles/install.sh`

**Structure**: The installer uses a modular function-based design with menu-driven profiles:

**Core Architecture** (lines 50-123):
- `detect_os()` - Detects Ubuntu/Debian or macOS
- `setup_package_manager()` - Ensures Homebrew on macOS
- `install_package()` - Cross-platform package installation wrapper
- Module functions: `install_base_tools()`, `install_neovim()`, `install_golang()`, etc.

**Module Registration** (lines 832-1080):
- Profile-based selection (full, minimal, work, custom)
- Dependency resolution system (lines 763-826)
- Module execution with error tracking (lines 1018-1080)

**Existing AI Tool Modules**:
- `install_claude()` (lines 630-699): Installs Claude Code CLI, links configs, installs Playwright MCP
- `install_opencode()` (lines 701-757): Installs OpenCode CLI, links configs

**Key Pattern for New Modules**:
```bash
install_beads() {
    print_header "Installing Beads (bd)"

    # Installation logic with fallback
    # Link configs (if applicable)
    # Verify installation

    print_success "Beads configured"
}
```

**Integration Points**:
- Add module to profile definitions (lines 856, 862, 1096-1151)
- Add to dependency resolver if needed (lines 763-826)
- Add to execution dispatcher (lines 1018-1080)

### 2. All ReadyQ Commands

**Location**: `/home/mtomcal/dotfiles/claude/commands/readyq*.md` and `/home/mtomcal/dotfiles/opencode/commands/readyq*.md`

**Complete List** (10 commands):

1. **readyq:create-tasks** (`/home/mtomcal/dotfiles/claude/commands/readyq:create-tasks.md`)
   - Purpose: Translate business requirements into ReadyQ issues (epics → stories)
   - Uses: `./readyq.py new`, `./readyq.py quickstart`

2. **readyq:refine-tasks** (`/home/mtomcal/dotfiles/claude/commands/readyq:refine-tasks.md`)
   - Purpose: Compare epics to current ReadyQ state, detect stale/duplicate work
   - Uses: `./readyq.py list`, `./readyq.py show {hashId}`, `./readyq.py update`

3. **readyq:implement-task** (`/home/mtomcal/dotfiles/claude/commands/readyq:implement-task.md`)
   - Purpose: TDD-based implementation of a ReadyQ story
   - Uses: `./readyq.py ready`, `./readyq.py show {hashId}`, `./readyq.py update`

4. **readyq:review** (`/home/mtomcal/dotfiles/claude/commands/readyq:review.md`)
   - Purpose: Code review for acceptance criteria and quality
   - Uses: `./readyq.py show {hashId}`, `./readyq.py update`

5. **readyq:review-tests** (`/home/mtomcal/dotfiles/claude/commands/readyq:review-tests.md`)
   - Purpose: Test quality review (assertions match intent, coverage >90%)
   - Uses: `./readyq.py show {hashId}`, `./readyq.py update`

6. **readyq:review-modularity** (`/home/mtomcal/dotfiles/claude/commands/readyq:review-modularity.md`)
   - Purpose: Proactive modularity analysis, creates refactoring issues
   - Uses: `./readyq.py new`, `./readyq.py quickstart`

7. **readyq:acceptance-test** (`/home/mtomcal/dotfiles/claude/commands/readyq:acceptance-test.md`)
   - Purpose: Playwright browser testing against acceptance criteria
   - Uses: `./readyq.py show {hashId}`, `./readyq.py update`

8. **readyq:full-cycle** (`/home/mtomcal/dotfiles/claude/commands/readyq:full-cycle.md`)
   - Purpose: Orchestrates full dev cycle (implement → code review → test review → commit → PR)
   - Uses: `./readyq.py show {hashId}`, `./readyq.py update`, orchestrates subagents

9. **readyq:pr-respond** (`/home/mtomcal/dotfiles/claude/commands/readyq:pr-respond.md`)
   - Purpose: Responds to PR comments, logs actionable feedback to ReadyQ
   - Uses: `./readyq.py show {hashId}`, `./readyq.py update`, `./readyq.py new`

10. **readyq:pr-merged** (`/home/mtomcal/dotfiles/claude/commands/readyq:pr-merged.md`)
    - Purpose: Marks issue done after PR merge
    - Uses: `./readyq.py show {hashId}`, `./readyq.py update --status done`

**Naming Convention**:
- Claude Code: Colon namespace (`readyq:create-tasks`)
- OpenCode: Hyphen namespace (`readyq-create-tasks`)

### 3. Beads (bd CLI) Overview

**Location**: `~/code/beads/` (user's local clone)

**Purpose**: Distributed, git-backed graph issue tracker for AI agents. Provides persistent structured memory as alternative to markdown plans.

**Key Architectural Differences from ReadyQ**:
- **Storage**: Git-backed JSONL in `.beads/issues.jsonl` + SQLite cache (ReadyQ uses Python/DB)
- **IDs**: Hash-based (`bd-a1b2`) to prevent merge conflicts (ReadyQ uses sequential IDs)
- **Sync**: Auto-sync daemon with 30-second debounce, git hooks (ReadyQ is single-file Python script)
- **Hierarchy**: Supports epic.task.subtask notation (`bd-a3f8.1.1`)
- **Dependencies**: First-class dependency graph with `bd dep` commands

**Core Philosophy** (`/home/mtomcal/code/beads/README.md:11`):
> "Beads provides a persistent, structured memory for coding agents. It replaces messy markdown plans with a dependency-aware graph, allowing agents to handle long-horizon tasks without losing context."

### 4. Command Mapping: ReadyQ → Beads

**Equivalent Commands**:

| ReadyQ Command | Beads Equivalent | Notes |
|----------------|------------------|-------|
| `./readyq.py quickstart` | `bd quickstart` OR `bd prime` | **bd quickstart**: Full guide similar to readyq.py quickstart<br>**bd prime**: AI-optimized workflow context (~1-2k tokens) for session start/recovery |
| `./readyq.py new` | `bd create` | Create new issue/task |
| `./readyq.py list` | `bd list` | List issues with filters |
| `./readyq.py show {id}` | `bd show {id}` | Show issue details |
| `./readyq.py update {id}` | `bd update {id}` | Update issue fields |
| `./readyq.py ready` | `bd ready` | List unblocked tasks |
| `./readyq.py update {id} --status done` | `bd close {id}` | Mark issue complete |
| N/A (implicit in update) | `bd dep add {child} {parent}` | Explicit dependency management |
| N/A | `bd sync` | Sync DB ↔ JSONL ↔ Git |

**Quickstart Command Details** (`/home/mtomcal/code/beads/cmd/bd/quickstart.go`, `/home/mtomcal/code/beads/cmd/bd/prime.go`):

1. **`bd quickstart`** - Interactive guide showing:
   - Getting started (init, create issues)
   - Viewing issues (list, show)
   - Managing dependencies (dep add, dep tree, dep cycles)
   - Ready work (bd ready)
   - Updating and closing issues
   - Database location discovery
   - Agent integration tips
   - Git auto-sync workflow

2. **`bd prime`** - AI-optimized workflow context:
   - Auto-detects MCP mode vs CLI mode
   - MCP mode: Brief workflow reminders (~50 tokens)
   - CLI mode: Full command reference (~1-2k tokens)
   - Designed for Claude Code hooks (SessionStart, PreCompact)
   - Prevents agents from forgetting bd workflow after context compaction
   - Supports custom `.beads/PRIME.md` override
   - Session close protocol with git integration steps

**Workflow Differences**:
- **ReadyQ**: Python script, direct file manipulation, logs via `--log` flag
- **Beads**: Background daemon, auto-sync with debounce, `--notes` field for progress tracking
- **Beads Learning**: Use `bd quickstart` for initial learning, `bd prime` for session recovery

**JSON Output**:
- Both support `--json` flag for machine-readable output
- ReadyQ: JSON output from Python script
- Beads: Structured JSON from Go CLI

### 5. Beads Installation Methods

**Source**: `/home/mtomcal/code/beads/docs/INSTALLING.md`

**Recommended Hierarchy** (lines 60-70):
1. **Homebrew** (macOS/Linux) - Best for most users
   ```bash
   brew tap steveyegge/beads
   brew install bd
   ```
   - Auto-updates via `brew upgrade`
   - No Go installation required
   - PATH setup automatic

2. **Install Script** (All platforms) - Good for CI/CD
   ```bash
   curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
   ```
   - Detects platform (macOS/Linux, amd64/arm64)
   - Uses `go install` if Go available, else builds from source
   - Guides through PATH setup

3. **npm/bun** (Node.js ecosystems)
   ```bash
   npm install -g @beads/bd
   # or
   bun install -g --trust @beads/bd
   ```

4. **go install** (Go developers)
   ```bash
   go install github.com/steveyegge/beads/cmd/bd@latest
   ```

5. **From source** (Contributors)
   ```bash
   git clone https://github.com/steveyegge/beads
   cd beads
   go build -o bd ./cmd/bd
   sudo mv bd /usr/local/bin/
   ```

**Minimal Install Preference** (from user context):
- User wants "Minimal install only (no git hooks or editor integration)"
- This means:
  - Install bd CLI only
  - Skip `bd setup claude` (SessionStart/PreCompact hooks)
  - Skip `bd hooks install` (git hooks)
  - Just basic CLI availability

**Installation Methods to Support** (from user context):
> "Installation preference: All methods with fallback (Homebrew → install script)"

This means:
1. Try Homebrew first (if available)
2. Fall back to install script
3. Skip npm/go/source methods

### 6. Integration Strategy

**Proposed Module Structure**:

```bash
install_beads() {
    print_header "Installing Beads (bd CLI)"

    # Method 1: Homebrew (preferred)
    if command -v brew &> /dev/null; then
        if ! brew list bd &> /dev/null; then
            print_info "Installing bd via Homebrew..."
            brew tap steveyegge/beads
            brew install bd
            print_success "Beads installed via Homebrew"
        else
            print_success "Beads is already installed via Homebrew"
        fi
    # Method 2: Install script (fallback)
    elif command -v curl &> /dev/null; then
        print_info "Installing bd via install script..."
        curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
        print_success "Beads installed via install script"
    else
        print_error "Neither Homebrew nor curl available for Beads installation"
        return 1
    fi

    # Verify installation
    if command -v bd &> /dev/null; then
        BD_VERSION=$(bd version 2>/dev/null || echo "unknown")
        print_success "Beads verified: $BD_VERSION"
    else
        print_error "Beads installation verification failed"
        return 1
    fi
}
```

**Symlink Configuration** (minimal setup, no hooks/integration):
- No symlinks needed - beads stores everything in `.beads/` directory
- No global config files like Claude/OpenCode
- User runs `bd init` manually per project

**Profile Updates**:
- Add to full profile: `SELECTED_MODULES=(... beads)`
- Add to custom menu options
- No dependencies (optional standalone tool)

### 7. Beads Command Namespace Structure

**New Namespace**: `beads:*` (for Claude Code) and `beads-*` (for OpenCode)

**Command Structure**:

| # | Claude Command | OpenCode Command | Primary bd Commands Used |
|---|----------------|------------------|--------------------------|
| 1 | `/beads:create-tasks` | `/beads-create-tasks` | `bd create`, `bd dep add` |
| 2 | `/beads:refine-tasks` | `/beads-refine-tasks` | `bd list`, `bd show`, `bd update` |
| 3 | `/beads:implement-task` | `/beads-implement-task` | `bd ready`, `bd show`, `bd update` |
| 4 | `/beads:review` | `/beads-review` | `bd show`, `bd update` |
| 5 | `/beads:review-tests` | `/beads-review-tests` | `bd show`, `bd update` |
| 6 | `/beads:review-modularity` | `/beads-review-modularity` | `bd create`, `bd dep add` |
| 7 | `/beads:acceptance-test` | `/beads-acceptance-test` | `bd show`, `bd update` |
| 8 | `/beads:full-cycle` | `/beads-full-cycle` | `bd show`, `bd update`, `bd close` |
| 9 | `/beads:pr-respond` | `/beads-pr-respond` | `bd show`, `bd update`, `bd create` |
| 10 | `/beads:pr-merged` | `/beads-pr-merged` | `bd show`, `bd close` |

**Key Adaptation Points**:

1. **Issue Creation** (create-tasks):
   - ReadyQ: `./readyq.py new "{title}" --description "{desc}" --blocker {id}`
   - Beads: `bd create "{title}" -t task -p {priority} -d "{desc}" --json`
   - Beads: `bd dep add {child} {parent}` (explicit blocking relationship)

2. **Status Updates** (implement-task, review):
   - ReadyQ: `./readyq.py update {id} --status {status} --log "{message}"`
   - Beads: `bd update {id} --status {status} --notes "{message}"`
   - Note: Beads uses `--notes` for progress tracking, not `--log`

3. **Ready Queue** (implement-task):
   - ReadyQ: `./readyq.py ready`
   - Beads: `bd ready` (identical UX)

4. **Completion** (full-cycle, pr-merged):
   - ReadyQ: `./readyq.py update {id} --status done`
   - Beads: `bd close {id} --reason "{message}"`

5. **PR Integration** (pr-respond):
   - ReadyQ: Logs PR URL via `--log 'Pull Request: {URL}'`
   - Beads: Uses `--notes` field or `--external-ref` for PR links

6. **Dependency Management** (create-tasks, refine-tasks):
   - ReadyQ: Implicit via `--blocker` flag during creation
   - Beads: Explicit via `bd dep add {child} {parent}` after creation

## Code References

- `/home/mtomcal/dotfiles/install.sh:630-699` - Claude Code installation module (pattern to follow)
- `/home/mtomcal/dotfiles/install.sh:701-757` - OpenCode installation module (pattern to follow)
- `/home/mtomcal/dotfiles/install.sh:763-826` - Dependency resolution system
- `/home/mtomcal/dotfiles/install.sh:832-877` - Profile menu system
- `/home/mtomcal/dotfiles/install.sh:1018-1080` - Module execution dispatcher
- `/home/mtomcal/dotfiles/AGENTS.md:83-92` - ReadyQ command documentation
- `/home/mtomcal/dotfiles/claude/commands/readyq:*.md` - All 10 ReadyQ command implementations
- `/home/mtomcal/code/beads/README.md:35-42` - Essential beads commands table
- `/home/mtomcal/code/beads/docs/INSTALLING.md:32-70` - Beads installation methods comparison
- `/home/mtomcal/code/beads/AGENT_INSTRUCTIONS.md:196-221` - Agent session workflow with bd sync

## Architecture Insights

**Modular Installer Design**:
- Function-based modules with consistent naming (`install_*`, `configure_*`)
- Cross-platform abstraction via `install_package()` helper
- Dependency resolution automatically adds required prerequisites
- Error tracking via `FAILED_MODULES` array
- Menu-driven UX with profiles (full, minimal, work, custom)

**ReadyQ Command Patterns**:
- All commands use `./readyq.py` CLI (Python script in repo root)
- Heavy use of `--log` flag for progress tracking
- Status-based workflow (todo → in_progress → done)
- Subagent orchestration pattern in full-cycle command
- TDD-focused (>90% coverage requirement in multiple commands)

**Beads vs ReadyQ Trade-offs**:

| Aspect | ReadyQ | Beads |
|--------|--------|-------|
| **Complexity** | Simple Python script | Daemon + SQLite + Git sync |
| **Setup** | Zero (script in repo) | `bd init` per project |
| **Collaboration** | Manual git ops | Auto-sync with hooks |
| **Dependencies** | First-class via graph | Implicit via --blocker |
| **Portability** | Requires Python | Binary (Go) |
| **Context Decay** | No built-in compaction | Semantic memory decay |

**AI Agent Instructions** (`/home/mtomcal/code/beads/AGENT_INSTRUCTIONS.md:196-221`):
> "When you finish making issue changes, always run: `bd sync`"
> "This immediately: 1. Exports pending changes to JSONL (no 30s wait), 2. Commits to git, 3. Pulls from remote, 4. Imports any updates, 5. Pushes to remote"

This is a key workflow difference - beads commands must end with `bd sync` to flush changes, unlike ReadyQ which writes directly.

## Open Questions

1. **Command Parity**: Should beads commands support all ReadyQ features (e.g., subagent orchestration in full-cycle)? Or focus on core issue tracking?
   - **Recommendation**: Full parity for feature equivalence, with workflow notes about `bd sync` requirement

2. **Hybrid Usage**: Can a project use both ReadyQ and Beads simultaneously?
   - **Recommendation**: Document as mutually exclusive options (choose one issue tracker)

3. **Migration Path**: Should we provide a readyq.py → beads migration tool?
   - **Recommendation**: Not in initial scope, but document manual migration steps if users request it

4. **Namespace Pollution**: Adding 10 new beads commands doubles the command count in AGENTS.md. Should we document differently?
   - **Recommendation**: Add beads commands section separate from ReadyQ section, with clear "Choose one issue tracker" guidance

5. **Git Hooks**: User requested "no git hooks", but beads git hooks prevent stale JSONL issues. How to handle?
   - **Recommendation**: Document as "strongly recommended but optional", add warning about manual `bd sync` requirement

## Implementation Recommendations

### Phase 1: Add Beads to Install.sh

1. Create `install_beads()` function following Claude/OpenCode pattern
2. Add to profile definitions (full, custom menu)
3. Test on both macOS and Ubuntu

**Files to Modify**:
- `/home/mtomcal/dotfiles/install.sh` - Add beads module
- `/home/mtomcal/dotfiles/AGENTS.md` - Document beads commands

### Phase 2: Create Beads Command Files

For each of the 10 ReadyQ commands, create beads equivalent:

**Claude Code** (`/home/mtomcal/dotfiles/claude/commands/`):
- `beads:create-tasks.md`
- `beads:refine-tasks.md`
- `beads:implement-task.md`
- `beads:review.md`
- `beads:review-tests.md`
- `beads:review-modularity.md`
- `beads:acceptance-test.md`
- `beads:full-cycle.md`
- `beads:pr-respond.md`
- `beads:pr-merged.md`

**OpenCode** (`/home/mtomcal/dotfiles/opencode/commands/`):
- `beads-create-tasks.md`
- `beads-refine-tasks.md`
- `beads-implement-task.md`
- `beads-review.md`
- `beads-review-tests.md`
- `beads-review-modularity.md`
- `beads-acceptance-test.md`
- `beads-full-cycle.md`
- `beads-pr-respond.md`
- `beads-pr-merged.md`

**Key Adaptations for Each Command**:
1. Replace `./readyq.py` with `bd` CLI
2. Replace `--log` with `--notes`
3. Add `bd sync` at end of workflows
4. Use `bd dep add` for explicit dependencies
5. Replace `hashId` variable with beads `id` (e.g., `bd-a1b2`)

### Phase 3: Update Documentation

1. Update `/home/mtomcal/dotfiles/AGENTS.md`:
   - Add Beads section parallel to ReadyQ section
   - Document when to use ReadyQ vs Beads
   - Include installation instructions

2. Create `/home/mtomcal/dotfiles/docs/BEADS_MIGRATION.md`:
   - Document ReadyQ → Beads differences
   - Provide manual migration steps
   - Include workflow comparison table

### Phase 4: Testing

1. Test beads installation on fresh Ubuntu VM
2. Test beads installation on macOS
3. Verify all 10 beads commands work end-to-end
4. Test Homebrew fallback to install script

## Next Steps

1. Review this research document with user
2. Get confirmation on open questions (especially git hooks decision)
3. Create detailed implementation plan for Phase 1-4
4. Begin implementation with install.sh module

## Sources

- [Beads GitHub Repository](https://github.com/steveyegge/beads)
- [Beads Installation Documentation](https://github.com/steveyegge/beads/blob/main/docs/INSTALLING.md)
- [Beads Agent Instructions](https://github.com/steveyegge/beads/blob/main/AGENT_INSTRUCTIONS.md)
- [Issue Management Commands | steveyegge/beads | DeepWiki](https://deepwiki.com/steveyegge/beads/4.1-issue-management-commands)
- [Getting Started | steveyegge/beads | DeepWiki](https://deepwiki.com/steveyegge/beads/2-getting-started)

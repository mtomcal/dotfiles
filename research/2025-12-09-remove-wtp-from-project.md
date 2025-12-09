---
date: 2025-12-09T15:23:04+0000
researcher: Claude Sonnet 4.5
topic: "How to remove WTP from this project entirely from prompts and code"
tags: [research, codebase, wtp, git-worktree, removal-strategy]
status: complete
---

# Research: How to Remove WTP from This Project Entirely

**Date**: 2025-12-09 15:23:04 UTC
**Researcher**: Claude Sonnet 4.5

## Research Question
How to remove WTP (git worktree manager) from this project entirely from prompts and code?

## Summary
WTP is a git worktree manager tool integrated into the dotfiles project to enable parallel AI development workflows. It's referenced in 7+ locations including installation scripts, documentation, and slash commands. Complete removal requires:
1. Removing installation logic from install.sh
2. Deleting 4 slash command files
3. Updating documentation in README.md and AGENTS.md
4. Optional: keeping native git worktree alternatives in documentation

## Detailed Findings

### 1. Installation Scripts

**File**: `install.sh:907-970`

The install script contains platform-specific WTP installation logic:

- **macOS**: Lines 907-935
  - Uses Homebrew tap: `brew tap satococoa/tap`
  - Installs via: `brew install satococoa/tap/wtp`

- **Ubuntu**: Lines 936-970
  - Downloads from GitHub: `satococoa/wtp`
  - Detects architecture (x86_64/arm64)
  - Installs to: `~/.local/bin/wtp`
  - Makes executable and adds to PATH

**Removal Action**: Delete the entire `install_wtp()` function and remove its call from the main installation flow.

### 2. Slash Commands (OpenCode CLI Integration)

Four slash command files in `opencode/commands/` directory:

| File | Purpose | Lines |
|------|---------|-------|
| `worktree-create.md` | Create new worktree for parallel development | Full file |
| `worktree-list.md` | List all active worktrees | Full file |
| `worktree-merge.md` | Merge and delete worktree | Full file |
| `worktree-status.md` | Show detailed worktree status | Referenced |

**Commands these provide**:
- `/worktree-create` or `/worktree_create`
- `/worktree-list` or `/worktree_list`
- `/worktree-merge` or `/worktree_merge`
- `/worktree-status` or `/worktree_status`

**Removal Action**: Delete all four command files from `opencode/commands/` directory.

### 3. Documentation in README.md

**File**: `README.md`

References found:
- **Line 11**: Quick links section mentioning "Git Worktrees for Parallel AI Development"
- **Lines 441-496**: Complete section titled "### Git Worktrees for Parallel AI Development"

The section includes:
- WTP overview and benefits
- Installation mention
- Use case examples (3-5 parallel agents, experimentation, code review)
- Example workflow with `wtp create`, `wtp list`, `wtp delete`
- Directory structure explanation
- Performance benefits claim ("2-3x faster")

**Removal Action**:
1. Remove the quick link on line 11
2. Delete the entire section on lines 441-496
3. Optionally: Add a brief note about native `git worktree` commands as alternative

### 4. Documentation in AGENTS.md

**File**: `AGENTS.md`

References found:
- **Line 21**: Installation section mentioning "Installs wtp (git worktree manager) for parallel development"
- **Lines 484-495**: Detailed documentation about WTP installation in install.sh

**Removal Action**:
1. Remove the bullet point on line 21
2. Delete or update the install.sh documentation section (lines 484-495)

### 5. Native Git Worktree Alternatives

The documentation mentions that users can use native git commands instead:

```bash
# Instead of: wtp create <name>
git worktree add trees/<branch-name> -b <branch-name>

# Instead of: wtp list
git worktree list

# Instead of: wtp delete <name>
git worktree remove trees/<branch-name>
```

**Consideration**: When removing WTP, decide whether to:
- Remove all worktree documentation entirely
- Replace with native git worktree command documentation
- Keep the parallel AI development concept with native commands

## Code References

### Installation
- `install.sh:907-935` - macOS installation logic (Homebrew)
- `install.sh:936-970` - Ubuntu installation logic (GitHub releases)

### Slash Commands
- `opencode/commands/worktree-create.md` - Create command implementation
- `opencode/commands/worktree-list.md` - List command implementation
- `opencode/commands/worktree-merge.md` - Merge command implementation
- `opencode/commands/worktree-status.md` - Status command (referenced)

### Documentation
- `README.md:11` - Quick link to worktree section
- `README.md:441-496` - Complete WTP documentation section
- `AGENTS.md:21` - Installation feature list
- `AGENTS.md:484-495` - Install.sh documentation

## Architecture Insights

### Design Pattern
WTP serves as a **convenience wrapper** around native git worktree functionality. The integration follows these patterns:

1. **Installation Layer**: Auto-installed during dotfiles setup
2. **CLI Integration Layer**: Slash commands wrap WTP for AI agents
3. **Documentation Layer**: User-facing guides and examples
4. **Workflow Layer**: Enables parallel AI development pattern

### Dependencies
- **External Tool**: WTP binary (satococoa/wtp on GitHub)
- **Platform Dependencies**:
  - macOS: Homebrew
  - Ubuntu: curl, GitHub API access
- **Git Dependency**: Requires git worktree feature (Git 2.5+)

### Use Case Philosophy
The integration promotes:
- Multiple concurrent AI agent sessions
- Experiment-driven development
- Branch isolation without context switching
- Parallel code review workflows

## Removal Strategy

### Step-by-Step Removal Plan

1. **Phase 1: Remove Installation Logic**
   - Delete `install_wtp()` function from `install.sh` (lines 907-970)
   - Remove function call from main installation sequence
   - Test installation script runs without errors

2. **Phase 2: Remove Slash Commands**
   - Delete `opencode/commands/worktree-create.md`
   - Delete `opencode/commands/worktree-list.md`
   - Delete `opencode/commands/worktree-merge.md`
   - Delete `opencode/commands/worktree-status.md` (if exists)

3. **Phase 3: Update README.md**
   - Remove quick link on line 11
   - Delete section on lines 441-496
   - Optionally: Add native git worktree section if workflow is still desired

4. **Phase 4: Update AGENTS.md**
   - Remove WTP mention from line 21
   - Update or remove install.sh documentation (lines 484-495)

5. **Phase 5: Verify Removal**
   - Search for any remaining "wtp" references: `grep -ri "wtp" .`
   - Check for any broken documentation links
   - Test that no commands reference WTP

### Alternative: Keep Native Git Worktree Workflow

If the parallel AI development workflow is valuable, consider:

**Replace WTP commands with native alternatives in documentation:**

```markdown
### Git Worktrees for Parallel AI Development

Use native git worktree commands:

# Create worktree
git worktree add trees/feature-name -b feature-name

# List worktrees
git worktree list

# Remove worktree
git worktree remove trees/feature-name
```

**Update slash commands to use native git:**
- Rewrite command files to call `git worktree` directly
- Keep same user-facing commands but remove WTP dependency

## Open Questions

1. **Is the parallel AI development workflow still desired?**
   - If yes: Keep workflow docs but use native git commands
   - If no: Remove all worktree-related documentation

2. **Are there any users actively using WTP?**
   - Check usage analytics or user feedback
   - Communicate removal in changelog/release notes

3. **Should worktree slash commands remain using native git?**
   - Would maintain feature parity without external dependency
   - Simpler maintenance, one less tool to install

4. **Are there any other indirect references?**
   - Hidden in examples or comments
   - In git commit messages or issues
   - In CI/CD scripts or testing

## Recommendation

**Recommended Approach**: Complete removal of WTP with optional native git worktree documentation replacement.

**Rationale**:
1. Reduces external dependencies (one less tool to maintain)
2. Native git worktree provides same functionality
3. Simplifies installation process
4. Maintains capability if native commands are documented

**If keeping workflow**: Update documentation to use `git worktree add/list/remove` instead of `wtp create/list/delete`. This provides same benefits without external dependency.

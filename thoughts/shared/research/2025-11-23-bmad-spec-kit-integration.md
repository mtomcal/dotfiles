---
date: 2025-11-23T06:38:09+00:00
researcher: Claude (Sonnet 4.5)
git_commit: b409378b6b6b53e8d3f84dd3a8ffcd2230a4f0ce
branch: main
repository: dotfiles
topic: "BMAD Spec Engineering Tool Integration into Dotfiles Install.sh"
tags: [research, dotfiles, bmad, bmad-spec-kit, installation, automation]
status: complete
last_updated: 2025-11-23
last_updated_by: Claude (Sonnet 4.5)
---

# Research: BMAD Spec Engineering Tool Integration into Dotfiles Install.sh

**Date**: 2025-11-23T06:38:09+00:00
**Researcher**: Claude (Sonnet 4.5)
**Git Commit**: b409378b6b6b53e8d3f84dd3a8ffcd2230a4f0ce
**Branch**: main
**Repository**: dotfiles

## Research Question

How can we integrate the latest BMAD spec engineering tool (BMAD-METHOD and BMAD-SPEC-KIT) into the dotfiles install.sh and config management system?

## Summary

BMAD-METHOD (v6 Alpha) is an AI-driven development framework that provides specialized agents and workflows for software development. Integration into the dotfiles install.sh is straightforward and can follow the existing pattern used for AI coding agents (Claude Code, OpenCode CLI, GitHub Copilot). The framework requires Node.js v20+ and is installed via NPM. It creates a configurable directory structure with agents and workflows that integrate seamlessly with Claude Code.

**Key Findings**:
- BMAD requires Node.js v20+ (already handled by fnm installation in install.sh)
- Installation is via NPM: `npx bmad-method@alpha install` (v6 Alpha) or `npx bmad-method install` (stable v4)
- Creates a `bmad/` directory structure with agents, workflows, and update-safe customization
- Integrates automatically with Claude Code via slash commands and agent menu
- Two distinct but related projects: BMAD-METHOD (core framework) and BMAD-SPEC-KIT (enhanced spec-driven variant)

## Detailed Findings

### BMAD-METHOD Overview

BMAD (Breakthrough Method for Agile AI-Driven Development) is a comprehensive framework that provides:

**Version Options**:
- **v6 Alpha** (Recommended for new projects): Near-beta quality, massive architectural upgrade
- **v4 Stable** (Production): Proven stability for enterprise use

**Core Components**:
- 19+ specialized agents with customizable personalities
- 50+ workflows covering every development scenario
- Modular architecture: Core, BMM (software dev), BMGD (game dev), BMB (builder), CIS (creative)
- Update-safe customization via `_cfg/` directory

**Requirements**:
- Node.js ≥20.0.0
- NPM package manager
- Compatible IDEs: Claude Code, Cursor, Windsurf, VS Code with Copilot Chat

### Installation Process

**Installation Command**:
```bash
# v6 Alpha (recommended)
npx bmad-method@alpha install

# Stable v4
npx bmad-method install
```

**Directory Structure Created**:
```
project-root/
└── bmad/                  # Default folder name (configurable)
    ├── core/              # Framework + BMad Master agent
    ├── bmm/               # Software development (8 agents, 30+ workflows)
    ├── bmgd/              # Game development (4 agents, 20+ workflows)
    ├── bmb/               # Custom builder (1 agent, 11 workflows)
    ├── cis/               # Creative workflows (5 agents, 5 workflows)
    └── _cfg/              # User customizations (persists through updates)
        └── agents/        # Agent configuration files
```

**Configuration Files**:
- `.nvmrc` - Node.js version specification
- `.npmrc` - NPM configuration
- `package.json` - Dependencies and scripts
- `eslint.config.mjs` - Code quality rules
- `prettier.config.mjs` - Code formatting

### Integration with Claude Code

BMAD integrates with Claude Code through three methods:

**Method 1: Agent Menu** (Beginner-friendly)
1. Load an agent in Claude Code
2. Wait for workflow menu to appear
3. Use natural language or shortcuts (e.g., `*workflow-init`)

**Method 2: Direct Slash Commands** (Power users)
- Format: `/bmad:bmm:workflows:workflow-init`
- Mix any agent with any workflow
- Works without pre-loading an agent

**Method 3: Party Mode** (Collaborative)
- Command: `/bmad:core:workflows:party-mode`
- Multiple agents collaborate on workflows
- Ideal for complex decisions

### Workflow Tracks

After installation, run `*workflow-init` to select appropriate planning track:

1. **Quick Flow Track** - Bug fixes, small features (tech-spec only)
2. **BMad Method Track** - Products/platforms (PRD + Architecture + UX)
3. **Enterprise Method Track** - Complex requirements with security/DevOps/testing

### Current Dotfiles Architecture

The dotfiles install.sh already implements a robust pattern for AI tool installation:

**AI Coding Agents Section** (install.sh:519-691):
- Optional installation prompt
- Checks for existing installations
- Creates config directories
- Links custom configurations via symlinks
- Handles backups with timestamps
- Provides authentication instructions

**Current AI Tools**:
1. **Claude Code** (install.sh:529-602)
   - CLI installation via curl
   - Symlinks: `~/.claude/commands`, `~/.claude/agents`, `~/.claude/settings.json`
   - Links to: `$DOTFILES_DIR/claude/*`

2. **OpenCode CLI** (install.sh:604-658)
   - CLI installation via curl
   - Symlinks: `~/.config/opencode/command`, `~/.config/opencode/AGENTS.md`
   - Links to: `$DOTFILES_DIR/opencode/*`

3. **GitHub Copilot CLI** (install.sh:660-688)
   - NPM global installation
   - Requires Node.js v22+
   - No custom config linking

**Supporting Infrastructure**:
- fnm (Fast Node Manager) - install.sh:276-311
- Node.js LTS via fnm - install.sh:293-311
- Symlink-based config management
- Timestamp-based backups for existing configs

## Integration Approach for BMAD

### Recommended Integration Strategy

Add BMAD installation to the existing "AI Coding Agents Setup" section, following the established pattern:

**Location**: After GitHub Copilot CLI section (install.sh:688)

**Implementation Pattern**:
```bash
# ===========================
# BMAD-METHOD Configuration
# ===========================

print_header "Setting up BMAD-METHOD"

# Check Node.js version requirement (v20 or higher)
if command -v node &> /dev/null; then
    NODE_MAJOR_VERSION=$(node --version | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR_VERSION" -ge 20 ]; then
        read -p "Install BMAD-METHOD framework? (y/n) " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Install v6 Alpha (recommended, latest features) or v4 Stable? (6/4) " -n 1 -r
            echo ""

            if [[ $REPLY =~ ^[6]$ ]]; then
                print_info "Installing BMAD-METHOD v6 Alpha..."
                npx bmad-method@alpha install
            else
                print_info "Installing BMAD-METHOD v4 Stable..."
                npx bmad-method install
            fi

            print_success "BMAD-METHOD installed to ./bmad/"
            print_info "Run '*workflow-init' in Claude Code to get started"
            print_info "Use slash commands: /bmad:bmm:workflows:workflow-init"
        fi
    else
        print_warning "Node.js v20+ required for BMAD-METHOD (current: v$NODE_MAJOR_VERSION)"
        print_info "BMAD requires Node.js v20+. Current installation: v$NODE_MAJOR_VERSION"
    fi
else
    print_warning "Node.js not found - skipping BMAD-METHOD installation"
fi
```

### Integration Considerations

**Dependencies** (Already handled):
- ✅ Node.js v20+ - fnm installs LTS (install.sh:293-311)
- ✅ NPM - Included with Node.js
- ✅ Claude Code - Optional AI agents section (install.sh:529-602)

**Project vs. Global Installation**:
- BMAD is designed for **per-project installation**, not global
- Unlike other tools (Claude Code, OpenCode), BMAD creates project-specific directories
- Should NOT be installed globally in dotfiles context
- Better suited as optional step or separate script

**Config Management**:
- BMAD uses `bmad/_cfg/` directory for customizations
- No direct symlink strategy needed (unlike Claude Code/OpenCode)
- Customizations are project-specific, not user-global
- Update-safe design means user edits persist through framework updates

**Alternative Approaches**:

1. **Documentation-Only Approach** (Recommended)
   - Add BMAD information to install.sh completion message
   - Create separate `docs/BMAD.md` with installation instructions
   - Let users install BMAD per-project as needed
   - Avoids assumptions about which projects need BMAD

2. **Optional Helper Script**
   - Create `bin/setup-bmad` script in dotfiles
   - Users can run it in any project: `~/dotfiles/bin/setup-bmad`
   - Prompts for version selection (v6 Alpha / v4 Stable)
   - More flexible than baking into main install.sh

3. **Post-Install Prompt** (Hybrid)
   - Add optional prompt at end of install.sh
   - Ask if user wants to install BMAD in current directory
   - Clear explanation that it's project-specific
   - Skip if not in a project directory

## Code References

### Current AI Tools Integration

- `install.sh:519-691` - AI Coding Agents Setup section
- `install.sh:529-602` - Claude Code configuration
- `install.sh:604-658` - OpenCode CLI configuration
- `install.sh:660-688` - GitHub Copilot CLI configuration
- `install.sh:276-311` - fnm (Node.js manager) installation
- `install.sh:293-311` - Node.js LTS installation via fnm

### Existing Symlink Pattern

- `install.sh:564` - `ln -s "$DOTFILES_DIR/claude/commands" "$HOME/.claude/commands"`
- `install.sh:580` - `ln -s "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"`
- `install.sh:597` - `ln -s "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"`

### Claude Code Custom Commands

- `claude/commands/` - Custom slash commands directory
- `claude/agents/` - Custom agent definitions
- `claude/README.md` - Documentation for Claude Code integration

## Architecture Insights

**Dotfiles Design Pattern**:
The install.sh follows a consistent pattern for integrating AI tools:
1. Check if tool is already installed
2. Install via appropriate package manager (curl script, npm, brew)
3. Create config directories
4. Symlink dotfiles configs to standard locations
5. Preserve existing configs with timestamped backups
6. Provide next-step instructions

**Symlink Strategy**:
- User-global configs (Claude Code, OpenCode) → Symlinked from dotfiles
- Per-project configs (BMAD) → Installed directly in project, no symlinks needed
- This distinction is key: BMAD doesn't fit the existing symlink pattern

**Node.js Version Management**:
The install.sh already handles Node.js properly:
- Uses fnm for version management (install.sh:276-311)
- Installs LTS by default (Node.js v22+ typically)
- Copilot requires v22+, BMAD requires v20+ - both satisfied

## Recommendations

### Primary Recommendation: Documentation-Only Approach

**Rationale**:
- BMAD is project-specific, not user-global
- Not all projects need BMAD (unlike Claude Code which is IDE-wide)
- Users should choose which projects get BMAD
- Keeps install.sh focused on user-global tools

**Implementation**:
1. Create `docs/BMAD.md` with detailed instructions
2. Add BMAD mention to install.sh completion message
3. No code changes to install.sh required

**Benefits**:
- No assumptions about project structure
- Users maintain full control
- Simpler maintenance
- Clear separation of concerns

### Secondary Recommendation: Helper Script

If automation is desired, create `bin/setup-bmad`:

```bash
#!/bin/bash
# Setup BMAD-METHOD in current project

set -e

# Check Node.js version
if ! command -v node &> /dev/null; then
    echo "Error: Node.js not found. Install via: ~/dotfiles/install.sh"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "Error: BMAD requires Node.js v20+. Current: v$NODE_VERSION"
    echo "Upgrade via: fnm install lts-latest && fnm use lts-latest"
    exit 1
fi

# Version selection
echo "BMAD-METHOD Installation"
echo "1) v6 Alpha (recommended - latest features, near-beta quality)"
echo "2) v4 Stable (production - proven stability)"
read -p "Select version (1/2): " version_choice

if [ "$version_choice" = "1" ]; then
    echo "Installing BMAD-METHOD v6 Alpha..."
    npx bmad-method@alpha install
else
    echo "Installing BMAD-METHOD v4 Stable..."
    npx bmad-method install
fi

echo ""
echo "BMAD-METHOD installed successfully!"
echo "Next steps:"
echo "  1. Open project in Claude Code"
echo "  2. Run: *workflow-init"
echo "  3. Or use slash commands: /bmad:bmm:workflows:workflow-init"
```

**Usage**: `~/dotfiles/bin/setup-bmad` in any project

### Not Recommended: Baking into install.sh

**Reasons to avoid**:
- BMAD installs to current directory, not a standard location
- Running install.sh from `~/dotfiles/` would install BMAD there (wrong place)
- Users would need to install BMAD separately in each project anyway
- Adds complexity without clear benefit

## Implementation Steps

### For Documentation-Only Approach (Recommended)

1. Create `docs/BMAD.md`:
```markdown
# BMAD-METHOD Integration

## Overview
BMAD-METHOD is an AI-driven development framework with specialized agents and workflows.

## Requirements
- Node.js v20+ (installed via dotfiles fnm)
- NPM
- Claude Code (recommended)

## Installation

Navigate to your project directory and run:

# v6 Alpha (recommended)
npx bmad-method@alpha install

# v4 Stable
npx bmad-method install

## Usage in Claude Code

### Method 1: Agent Menu
1. Load an agent in Claude Code
2. Wait for workflow menu
3. Use shortcuts like `*workflow-init`

### Method 2: Slash Commands
/bmad:bmm:workflows:workflow-init

### Method 3: Party Mode
/bmad:core:workflows:party-mode

## Customization

Edit files in `bmad/_cfg/agents/` to customize agents.
Changes persist through framework updates.

## Resources
- [BMAD-METHOD GitHub](https://github.com/bmad-code-org/BMAD-METHOD)
- [BMAD-SPEC-KIT GitHub](https://github.com/oimiragieo/BMAD-SPEC-KIT)
```

2. Update install.sh completion message (after line 865):
```bash
print_info "BMAD-METHOD Framework:"
echo "  - Per-project AI development framework"
echo "  - Install in any project: npx bmad-method@alpha install"
echo "  - See: ~/dotfiles/docs/BMAD.md for full guide"
```

### For Helper Script Approach

1. Create `bin/setup-bmad` (see script above)
2. Make executable: `chmod +x ~/dotfiles/bin/setup-bmad`
3. Add to install.sh completion message
4. Document in README.md

## Related Research

No prior research documents found in `thoughts/shared/research/` related to BMAD or AI framework integration.

## Open Questions

1. **Version Selection**: Should we recommend v6 Alpha or v4 Stable by default?
   - v6 Alpha is "near-beta quality" and recommended for new projects
   - v4 Stable is production-proven
   - Current recommendation: v6 Alpha (based on GitHub README)

2. **Global BMAD Config**: Does BMAD support any user-global configuration?
   - Research suggests all config is project-specific
   - No evidence of `~/.bmad/` or similar global config directory

3. **Claude Code Integration**: Should we create custom BMAD-related slash commands?
   - BMAD provides its own slash commands (`/bmad:*`)
   - May not need additional wrapper commands
   - Could create shortcuts like `/bmad-init` → `/bmad:bmm:workflows:workflow-init`

4. **Template Projects**: Should we create a dotfiles template with BMAD pre-configured?
   - Could be useful for quickly starting new projects
   - `~/dotfiles/templates/project-with-bmad/`
   - Users copy template when starting new projects

## Conclusion

BMAD-METHOD integration is best handled as **optional, per-project installation** rather than baked into the main install.sh. The framework's project-specific nature doesn't align with the dotfiles' user-global tool pattern. The recommended approach is to:

1. Document BMAD in `docs/BMAD.md`
2. Add mention to install.sh completion message
3. Optionally create `bin/setup-bmad` helper script for convenience

This gives users full control over which projects use BMAD while maintaining the clean, user-global focus of the main install.sh script.

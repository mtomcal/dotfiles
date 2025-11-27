---
date: 2025-11-27T15:45:00-08:00
researcher: opencode
topic: "OpenCode Configuration Management in Install Flow"
tags: [research, codebase, opencode, configuration, install-flow]
status: complete
---

# Research: OpenCode Configuration Management in Install Flow

**Date**: 2025-11-27 15:45:00 PST
**Researcher**: opencode

## Research Question
How can we manage the opencode.json configuration file with the install flow to ensure standard opencode.json config across all systems that use these dotfiles?

## Summary

OpenCode configuration management uses a hierarchical system with global (`~/.config/opencode/opencode.json`) and project-level (`./opencode.json`) configs that are merged together. The current install script sets up symlinks for commands and shared instructions but does not create a standard opencode.json configuration. To ensure consistent configuration across all systems, we should add opencode.json management to the install script using the existing symlink strategy.

## Detailed Findings

### Current OpenCode Configuration Architecture

**Configuration Locations** (from OpenCode docs):
- **Global config**: `~/.config/opencode/opencode.json` - For themes, providers, keybinds
- **Project config**: `./opencode.json` - Project-specific settings, safe to commit to Git
- **Custom path**: `OPENCODE_CONFIG` environment variable
- **Custom directory**: `OPENCODE_CONFIG_DIR` environment variable

**Configuration Merging**: Files are deep-merged, not replaced. Later configs override earlier ones only for conflicting keys.

### Current Install Script Implementation

The install script (`install.sh:762-817`) currently:
1. **Installs OpenCode CLI** via official installer (`install.sh:768-778`)
2. **Creates config directory** at `~/.config/opencode/` (`install.sh:781-785`)
3. **Sets up symlinks**:
   - Commands: `~/.config/opencode/command/` → `~/dotfiles/opencode/commands/` (`install.sh:788-798`)
   - Shared instructions: `~/.config/opencode/AGENTS.md` → `~/dotfiles/AGENTS.md` (`install.sh:801-813`)

**Missing**: No opencode.json configuration management.

### Recommended Configuration Strategy

Based on the existing symlink architecture and OpenCode's configuration system, we should:

1. **Create standard opencode.json** in `opencode/opencode.json` (version-controlled)
2. **Symlink global config** to ensure consistency across systems
3. **Include project-level template** for optional project-specific overrides
4. **Follow existing backup/merge patterns** from the install script

### Configuration Content Recommendations

For a dotfiles repository, the standard opencode.json should include:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  
  // Theme and UI preferences
  "theme": "opencode",
  "tui": {
    "scroll_speed": 3,
    "scroll_acceleration": {
      "enabled": true
    }
  },
  
  // Model configuration (user-specific API keys handled separately)
  "model": "anthropic/claude-sonnet-4-5",
  "small_model": "anthropic/claude-haiku-4-5",
  
  // Tool permissions for safety
  "permission": {
    "bash": "ask",
    "edit": "allow"
  },
  
  // Auto-update management
  "autoupdate": "notify",
  
  // Sharing configuration
  "share": "manual",
  
  // Load custom commands from symlinked directory
  "instructions": ["AGENTS.md"]
}
```

### Implementation Plan

**Add to install script after OpenCode installation (around line 817)**:

```bash
# ===========================
# OpenCode Configuration Management
# ===========================

print_header "Setting up OpenCode configuration"

# Link standard opencode.json configuration
print_info "Linking OpenCode configuration..."
if [ -f "$HOME/.config/opencode/opencode.json" ] && [ ! -L "$HOME/.config/opencode/opencode.json" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mv "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json.backup.$TIMESTAMP"
    print_warning "Backed up existing opencode.json to opencode.json.backup.$TIMESTAMP"
fi

if [ -L "$HOME/.config/opencode/opencode.json" ]; then
    rm "$HOME/.config/opencode/opencode.json"
fi

if [ -f "$DOTFILES_DIR/opencode/opencode.json" ]; then
    ln -s "$DOTFILES_DIR/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
    print_success "OpenCode configuration linked"
else
    print_info "No opencode.json found in dotfiles (skipping configuration linking)"
fi
```

### Project-Level Configuration Template

Create `opencode/opencode.project.json` as a template users can copy to project roots:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  
  // Project-specific model overrides
  "model": "anthropic/claude-sonnet-4-5",
  
  // Project-specific instructions
  "instructions": [
    "AGENTS.md",
    "CONTRIBUTING.md",
    "docs/guidelines.md"
  ],
  
  // Project-specific tools
  "tools": {
    "write": true,
    "bash": true,
    "edit": true
  },
  
  // Project-specific agents
  "agent": {
    "code-reviewer": {
      "description": "Reviews code for this project's standards",
      "prompt": "Review code according to this project's patterns in AGENTS.md"
    }
  }
}
```

## Code References

- `install.sh:762-817` - Current OpenCode installation and symlink setup
- `install.sh:788-798` - Commands symlink creation pattern
- `install.sh:801-813` - AGENTS.md symlink creation pattern
- `opencode/.gitignore:1-21` - Security exclusions (ensure opencode.json is NOT ignored)
- `AGENTS.md:54-58` - OpenCode configuration documentation
- OpenCode Config Documentation: https://opencode.ai/docs/config/

## Architecture Insights

### Design Patterns

1. **Consistent Symlink Strategy**: Use same backup/replace pattern as other configurations
2. **Hierarchical Configuration**: Global standard config + optional project overrides
3. **Security Separation**: API keys in auth.json (local), config in opencode.json (versioned)
4. **Template-Based**: Provide templates for customization while ensuring defaults

### Integration Points

- **Existing Install Flow**: Add after OpenCode CLI installation
- **Symlink Architecture**: Follow established patterns from tmux, nvim, claude configs
- **Backup Strategy**: Use timestamp-based backup like other configurations
- **Git Integration**: Project-level configs safe to commit, global configs versioned in dotfiles

### Configuration Hierarchy After Implementation

```
~/.config/opencode/                    # Runtime configuration
├── command/ → ~/dotfiles/opencode/commands/  # Custom commands
├── AGENTS.md → ~/dotfiles/AGENTS.md          # Shared instructions
├── opencode.json → ~/dotfiles/opencode/opencode.json  # Standard config
└── [local files]                            # auth.json, history, etc.

~/dotfiles/opencode/                          # Version-controlled source
├── commands/                               # Command definitions
├── opencode.json                           # Standard global configuration
├── opencode.project.json                   # Project-level template
├── .gitignore                             # Security exclusions
└── README.md                              # Documentation
```

## Open Questions

1. Should we include model-specific configuration or leave that to user preference?
2. What tool permissions should be default for a dotfiles setup?
3. Should we include project-specific configuration in git worktrees?
4. How to handle configuration migration when updating opencode.json schema?

## Implementation Recommendation

Add opencode.json management to the install script using the established symlink pattern. This ensures:
- **Consistency**: Same configuration across all systems using these dotfiles
- **Flexibility**: Users can override with project-level configs
- **Security**: API keys remain separate in auth.json
- **Maintainability**: Configuration updates propagate via dotfiles updates

The approach leverages OpenCode's built-in configuration merging and follows the existing architectural patterns in the dotfiles repository.
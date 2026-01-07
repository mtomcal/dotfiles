---
date: 2026-01-07T00:00:00Z
researcher: codebase-researcher-agent
topic: "Transform install.sh into a modular, menu-driven installer with selectable features"
tags: [research, codebase, install-script, modular-installer, menu-driven]
status: complete
---

# Research: Transform install.sh into a modular, menu-driven installer with selectable features

**Date**: 2026-01-07
**Researcher**: codebase-researcher-agent

## Research Question

How to transform the current monolithic install.sh into a modular, menu-driven installer that allows users to select specific features (e.g., at work only install nvim, tmux, opencode configs) while understanding component dependencies and boundaries?

## Summary

The current install.sh is a ~997 line monolithic script that installs everything in a sequential flow. Analysis reveals 11 distinct installation sections with varying levels of interdependency. The script can be modularized into selectable feature modules with 3 dependency tiers: **Core** (base utilities + package manager), **Independent** (standalone tools), and **Dependent** (tools requiring other components). A menu-driven interface using pure bash select can present these modules with dependency management.

## Detailed Findings

### Current Installation Sections/Components

The install.sh file has 11 distinct installation sections (identified by section markers `# ===`):

1. **OS Detection** (lines 43-68)
   - Detects Ubuntu/Debian (apt) or macOS (brew)
   - Sets PACKAGE_MANAGER and OS variables
   - **Status**: Required foundation - cannot be optional

2. **Package Manager Installation** (lines 70-89)
   - macOS only: Installs Homebrew if missing
   - Handles Apple Silicon PATH configuration
   - **Status**: Required on macOS - conditional

3. **System Dependencies** (lines 91-146)
   - Core packages: git, curl, tmux, ripgrep, zsh, jq, gh
   - Platform-specific: build-essential, fd-find, xclip (Ubuntu) vs gcc, fd (macOS)
   - **Status**: Can be modular - different subsets for different use cases

4. **Neovim Installation** (lines 148-239)
   - Ubuntu: AppImage with version checking (0.10+)
   - macOS: Homebrew installation
   - Architecture detection (x86_64/arm64)
   - **Status**: Independent module - can be optional

5. **Go (Golang) Installation** (lines 241-382)
   - Ubuntu: Official binary download with architecture detection
   - macOS: Homebrew with version checking (1.24+)
   - Optional: govulncheck security scanner
   - **Status**: Independent module - can be optional

6. **Oh My Zsh Installation** (lines 384-418)
   - Installs Oh My Zsh framework
   - Sets zsh as default shell (if not already)
   - **Status**: Independent module - can be optional

7. **fnm (Node Manager) Installation** (lines 420-456)
   - Installs fnm and Node.js LTS
   - Auto-version switching configuration
   - **Status**: Independent module - can be optional

8. **Tmux Configuration** (lines 458-476)
   - Symlinks tmux/.tmux.conf to ~/.tmux.conf
   - Backs up existing config
   - **Status**: Dependent on tmux being installed (section 3)

9. **Zsh Configuration** (lines 478-495)
   - Adds source line to ~/.zshrc
   - Sources zsh/.zshrc.custom
   - **Status**: Dependent on zsh and Oh My Zsh (sections 3, 6)

10. **Neovim Configuration** (lines 497-688)
    - Clones/updates kickstart.nvim
    - Symlinks custom/ directory
    - Installs plugins and Mason packages
    - Conditional Go tools if Go is installed
    - **Status**: Dependent on neovim (section 4)

11. **AI Coding Agents** (lines 690-897)
    - Claude Code CLI + configuration
    - OpenCode CLI + configuration
    - MCP servers (Playwright)
    - **Status**: Independent module - can be optional (user already gets prompted)

### Component Dependencies and Boundaries

#### Tier 1: Core (Always Required)
- **OS Detection** - Foundation for everything else
- **Package Manager** - Required for installing anything (macOS needs Homebrew)
- **Helper Functions** - print_info, print_success, etc. (lines 18-36)

#### Tier 2: Base Tools (Selectable but commonly needed)
- **git** - Required for cloning kickstart.nvim, Oh My Zsh
- **curl** - Required for downloading installers (fnm, AI tools)
- **tmux** - Standalone, but tmux config depends on it
- **zsh** - Standalone, but zsh config and Oh My Zsh depend on it

#### Tier 3: Independent Tools (Fully Optional)
- **Neovim** - Standalone installation
- **Go (Golang)** - Standalone installation
- **fnm + Node.js** - Standalone installation
- **ripgrep, fd** - Used by neovim plugins but not required for base install
- **jq, gh** - Standalone utilities

#### Tier 4: Configuration Modules (Depend on Tier 2/3)
- **Tmux Configuration** → Requires: tmux (Tier 2)
- **Zsh Configuration** → Requires: zsh (Tier 2)
- **Oh My Zsh** → Requires: zsh (Tier 2)
- **Neovim Configuration** → Requires: neovim (Tier 3), git (Tier 2)
- **AI Coding Agents** → Requires: curl (Tier 2)

#### Tier 5: Enhanced Features (Depend on Tier 3/4)
- **Mason Packages** → Requires: neovim config (Tier 4)
  - Python tools: ruff, pyright (always)
  - Go tools: gopls, delve, gofumpt (conditional on Go)

### Dependency Graph

```
Core (Always)
├── Package Manager Functions
├── OS Detection
└── Helper Functions

↓

Base Tools (Selectable)
├── git ───┐
├── curl ──┼─┐
├── tmux ──┼─┼─┐
├── zsh ───┼─┼─┼─┐
└── Build Tools ┼─┼─┼─┐
               │ │ │ │
               ↓ ↓ ↓ ↓
Independent Tools (Optional)
├── Neovim ────┼─┤ │ │
├── Go ────────┼─┼─┘ │
└── fnm ───────┼─┴───┘
               │
               ↓
Configuration Modules
├── Tmux Config ──→ Requires tmux
├── Zsh Config ───→ Requires zsh
├── Oh My Zsh ────→ Requires zsh, git
├── Neovim Config → Requires neovim, git
└── AI Agents ────→ Requires curl

               ↓
Enhanced Features
└── Mason Packages → Requires neovim config
    ├── Python tools (always)
    └── Go tools (conditional on Go)
```

### Current Installation Flow

1. **Pre-flight**: OS detection → Package manager setup
2. **Dependencies**: Install all system packages (no selection)
3. **Languages**: Neovim → Go → Oh My Zsh → fnm (sequential, no selection)
4. **Configurations**: Tmux → Zsh → Neovim (depends on step 2)
5. **Optional**: AI agents (user prompted)

### Symlink Strategy Analysis

All configuration linking follows the same pattern:

**Template**:
```bash
# 1. Backup existing non-symlink config
if [ -f "$TARGET" ] && [ ! -L "$TARGET" ]; then
    mv "$TARGET" "${TARGET}.backup.${TIMESTAMP}"
fi

# 2. Remove existing symlink
if [ -L "$TARGET" ]; then
    rm "$TARGET"
fi

# 3. Create new symlink
ln -sf "$SOURCE" "$TARGET"
```

**Symlinks created**:
- `~/.tmux.conf` → `~/dotfiles/tmux/.tmux.conf`
- `~/.config/nvim/lua/custom` → `~/dotfiles/nvim/custom`
- `~/.claude/commands` → `~/dotfiles/claude/commands`
- `~/.claude/agents` → `~/dotfiles/claude/agents`
- `~/.claude/settings.json` → `~/dotfiles/claude/settings.json`
- `~/.claude/statusline.sh` → `~/dotfiles/claude/statusline.sh`
- `~/.config/opencode/command` → `~/dotfiles/opencode/commands`
- `~/.config/opencode/AGENTS.md` → `~/dotfiles/AGENTS.md`
- `~/.config/opencode/opencode.json` → `~/dotfiles/opencode/opencode.json`

**Modularization**: Each symlink section can be extracted to a function:
- `link_tmux_config()`
- `link_zsh_config()`
- `link_neovim_config()`
- `link_claude_config()`
- `link_opencode_config()`

### Shared Functions and Utilities

**All modules need**:
1. **Helper Functions** (lines 18-36):
   - `print_info()`, `print_success()`, `print_warning()`, `print_error()`, `print_header()`

2. **Environment Variables**:
   - `$DOTFILES_DIR` (line 40) - Absolute path to dotfiles repository
   - `$OS` - "ubuntu" or "macos"
   - `$PACKAGE_MANAGER` - "apt" or "brew"

3. **Core Function**:
   - `install_package()` (lines 97-116) - Abstraction over apt/brew
   - Takes package name + optional brew_name
   - Checks if already installed before attempting

**Example**:
```bash
install_package "git" "git"  # same name on both platforms
install_package "fd-find" "fd"  # different names
```

These must remain in the main script or be sourced from a shared library.

### Opportunities for Modularization

#### Approach 1: Function-Based Modules

Extract each section into a function:

```bash
# install.sh (main)
source lib/core.sh        # Helper functions, install_package()
source lib/base.sh        # OS detection, package manager
source lib/neovim.sh      # install_neovim(), configure_neovim()
source lib/golang.sh      # install_golang()
source lib/nodejs.sh      # install_fnm()
source lib/zsh.sh         # install_ohmyzsh(), configure_zsh()
source lib/tmux.sh        # configure_tmux()
source lib/ai_agents.sh   # install_claude(), install_opencode()

# Main menu
show_menu
```

**Function signatures**:
```bash
install_neovim()        # Installs neovim binary
configure_neovim()      # Clones kickstart, links custom/, installs plugins
install_golang()        # Installs Go toolchain
install_fnm()           # Installs fnm + Node.js LTS
install_ohmyzsh()       # Installs Oh My Zsh framework
configure_zsh()         # Links custom config, sets default shell
configure_tmux()        # Links tmux config
install_claude()        # Installs Claude Code + links configs
install_opencode()      # Installs OpenCode + links configs
```

#### Approach 2: Script-Based Modules

Create separate scripts in `modules/` directory:

```
dotfiles/
├── install.sh              # Main menu + orchestration
├── lib/
│   ├── core.sh             # Shared utilities
│   └── dependencies.sh     # Dependency checking
└── modules/
    ├── 01-base.sh          # OS detection, package manager
    ├── 02-neovim.sh        # Neovim installation + config
    ├── 03-golang.sh        # Go installation
    ├── 04-nodejs.sh        # fnm + Node.js
    ├── 05-zsh.sh           # zsh + Oh My Zsh + config
    ├── 06-tmux.sh          # tmux config
    └── 07-ai-agents.sh     # Claude + OpenCode
```

Each module script:
- Sources `lib/core.sh` for utilities
- Checks prerequisites
- Idempotent (safe to run multiple times)
- Returns 0 on success, 1 on failure

#### Approach 3: Hybrid (Recommended)

Combine both approaches:
- **Core functions** in `lib/`
- **Module logic** in main `install.sh` as functions
- **Menu system** in main script for orchestration

This keeps everything in one file while maintaining modularity.

### Menu Design Considerations

#### Pure Bash Select Menu

**Pros**:
- No dependencies (built into bash)
- Works everywhere (macOS and Linux)
- Simple implementation
- Portable across all platforms

**Example - Multi-select implementation**:
```bash
# Multi-select menu using bash arrays
declare -A SELECTIONS
options=("Neovim + Config" "Tmux Config" "Zsh + Oh My Zsh" "Go Toolchain"
         "Node.js (fnm)" "AI Agents" "Toggle All" "Done")

PS3="Select components (enter number to toggle, 'Done' to continue): "

while true; do
  echo ""
  echo "Current selections:"
  for opt in "${options[@]}"; do
    if [[ "${SELECTIONS[$opt]}" == "1" ]]; then
      echo "  [X] $opt"
    else
      echo "  [ ] $opt"
    fi
  done
  echo ""

  select choice in "${options[@]}"; do
    case $choice in
      "Done") break 2 ;;
      "Toggle All")
        # Toggle all selections
        for opt in "${options[@]}"; do
          [[ "$opt" != "Toggle All" && "$opt" != "Done" ]] && SELECTIONS[$opt]=$((1 - ${SELECTIONS[$opt]:-0}))
        done
        break
        ;;
      *)
        # Toggle individual selection
        SELECTIONS[$choice]=$((1 - ${SELECTIONS[$choice]:-0}))
        break
        ;;
    esac
  done
done

# Build SELECTED array from SELECTIONS
SELECTED=()
for opt in "${!SELECTIONS[@]}"; do
  [[ "${SELECTIONS[$opt]}" == "1" ]] && SELECTED+=("$opt")
done
```

**Alternative - Simple select with loop**:
```bash
PS3="Select a component (enter number): "
options=("Neovim + Config" "Tmux Config" "Zsh + Oh My Zsh" "Go Toolchain"
         "Node.js (fnm)" "AI Agents" "All" "Done")
SELECTED=()

while true; do
  select opt in "${options[@]}"; do
    case $opt in
      "Done") break 2 ;;
      "All")
        SELECTED=("${options[@]:0:${#options[@]}-2}")  # All except "All" and "Done"
        break 2
        ;;
      *)
        SELECTED+=("$opt")
        echo "Selected: $opt (${#SELECTED[@]} total)"
        break
        ;;
    esac
  done
done
```

#### Recommended Menu Structure

**Preset profiles + custom selection**:

```
Dotfiles Installation Menu
==========================

Select installation profile:

1) Full Installation (everything)
   - Neovim + custom config
   - Tmux + config
   - Zsh + Oh My Zsh + config
   - Go toolchain
   - Node.js (fnm)
   - AI agents (Claude + OpenCode)

2) Minimal (editors only)
   - Neovim + custom config
   - Tmux + config

3) Work Profile (no personal tools)
   - Neovim + custom config
   - Tmux + config
   - OpenCode CLI (work)

4) Custom (pick components)
   - Opens component menu

0) Exit
```

**Custom selection menu** (Option 4):
```
Select components to install:
=============================

Current selections:
  [X] Neovim 0.10+ (AppImage/Homebrew)
  [X] Neovim custom config (kickstart + plugins)
  [X] Tmux configuration
  [X] Zsh + Oh My Zsh
  [ ] Go 1.24+ toolchain
  [ ] Node.js LTS (fnm)
  [ ] Claude Code CLI + configs
  [ ] OpenCode CLI + configs

1) Neovim 0.10+ (AppImage/Homebrew)
2) Neovim custom config (kickstart + plugins)
3) Tmux configuration
4) Zsh + Oh My Zsh
5) Go 1.24+ toolchain
6) Node.js LTS (fnm)
7) Claude Code CLI + configs
8) OpenCode CLI + configs
9) Toggle All
10) Done

Select components (enter number to toggle, 'Done' to continue):
```

### Implementation Considerations

#### 1. Dependency Resolution

**Automatic dependency installation**:
- If user selects "Neovim config" → auto-select "git" (required for kickstart)
- If user selects "Oh My Zsh" → auto-select "zsh"
- If user selects "Tmux config" → auto-select "tmux"

**Warning on missing dependencies**:
```bash
print_warning "Neovim config requires git. Adding git to installation."
```

#### 2. Profile Presets

**Pre-defined combinations**:
```bash
PROFILE_FULL=("neovim" "nvim_config" "tmux" "zsh" "golang" "nodejs" "ai_agents")
PROFILE_MINIMAL=("neovim" "nvim_config" "tmux")
PROFILE_WORK=("neovim" "nvim_config" "tmux" "opencode")
```

#### 3. Validation

**Check selections before proceeding**:
```bash
show_selection_summary() {
  echo ""
  echo "You have selected:"
  for module in "${SELECTED[@]}"; do
    echo "  - $module"
  done
  echo ""
  read -p "Proceed with installation? (y/n) " -n 1 -r
}
```

#### 4. Idempotency

**All modules must remain idempotent**:
- Check if already installed before installing
- Safe to run multiple times
- Current script already does this (lines 156, 357, 439, etc.)

**Example** (line 156):
```bash
if command -v nvim &> /dev/null; then
  # Check version, offer upgrade if needed
fi
```

#### 5. State Tracking

**Track what was installed**:
```bash
STATE_FILE="$HOME/.dotfiles_state.json"

{
  "installed_at": "2026-01-07T10:30:00Z",
  "modules": ["neovim", "nvim_config", "tmux", "zsh"],
  "os": "ubuntu",
  "neovim_version": "0.11.5"
}
```

**Use case**:
- `./install.sh --update` - Re-runs installed modules
- `./install.sh --add golang` - Adds new module without menu

### Key Insights for Implementation

1. **Core must always run**: OS detection, package manager, helper functions

2. **Base tools are the "glue"**: git, curl, zsh, tmux - many things depend on them

3. **Configurations should auto-enable their dependencies**:
   - Selecting "Neovim config" should install neovim if not present
   - Selecting "Oh My Zsh" should install zsh if not present

4. **Mason packages need conditional logic**: Already implemented (line 674)
   ```bash
   if command -v go &> /dev/null; then
     MASON_PACKAGES="$MASON_PACKAGES gopls delve gofumpt goimports"
   fi
   ```

5. **AI agents section already has a menu**: Lines 696-897 prompt user
   - This pattern can be extracted and reused

6. **Symlink backup strategy is solid**: Preserve for all modules
   - Timestamps prevent overwrites
   - Safe to run multiple times

7. **Platform differences are abstracted**:
   - `install_package()` handles apt vs brew
   - OS-specific sections use `if [ "$OS" == "ubuntu" ]`

8. **Version checking is inconsistent**:
   - Neovim: Checks version, offers upgrade (lines 156-228)
   - Go: Checks version, offers upgrade (lines 259-282, 346-352)
   - Others: Install only if missing
   - **Recommendation**: Standardize version checking across all modules

## Architecture Insights

### Current Strengths

1. **Idempotent design**: Already safe to run multiple times
2. **Platform abstraction**: `install_package()` handles OS differences
3. **Backup strategy**: Timestamped backups before overwriting
4. **Clear section boundaries**: 11 distinct sections with comment markers
5. **Conditional dependencies**: Mason Go tools only if Go is installed

### Refactoring Strategy

**Phase 1: Extract functions** (no behavior change)
```bash
# Move logic into functions while keeping linear flow
install_neovim() { ... }
configure_neovim() { ... }

# Main execution (same as before, just calling functions)
install_neovim
configure_neovim
install_golang
# ... etc
```

**Phase 2: Add menu system**
```bash
# Add menu before function calls
show_menu  # Sets SELECTED array

# Conditional execution
if [[ " ${SELECTED[@]} " =~ " neovim " ]]; then
  install_neovim
fi
```

**Phase 3: Dependency resolution**
```bash
# Auto-add dependencies
resolve_dependencies() {
  if [[ " ${SELECTED[@]} " =~ " nvim_config " ]]; then
    # Neovim config needs git for kickstart
    add_if_missing "git"
  fi
}
```

### Pattern for Module Functions

**Standard module pattern**:
```bash
install_MODULE() {
  # 1. Check prerequisites
  # 2. Check if already installed
  # 3. Platform-specific installation logic
  # 4. Verification
}

configure_MODULE() {
  # 1. Check if base module is installed
  # 2. Backup existing config
  # 3. Create symlinks
  # 4. Apply settings
}
```

## Implementation Decisions

### Design Principles

1. **Idempotency is Required**
   - All install operations must be idempotent (safe to run multiple times)
   - Script should detect existing installations and skip/update as appropriate
   - Current script already implements this - preserve this behavior
   - No distinction between "install mode" and "update mode" - same behavior

2. **Command-line flags + interactive menu**
   - Support both: `./install.sh --modules neovim,tmux,zsh` (non-interactive)
   - And: `./install.sh` (interactive menu)
   - Flag-based installs should skip all prompts

3. **Partial failure handling**
   - Continue with remaining modules if one fails
   - Track failures in array: `FAILED_MODULES=()`
   - Show summary at end with successful and failed modules
   - Return non-zero exit code if any failures occurred

4. **Dependency checking: Auto-install (advisory warnings)**
   - Automatically add dependencies to installation list
   - Show warnings: "Adding git (required by neovim config)"
   - Don't block installation - auto-resolve dependencies
   - This provides best UX while ensuring things work

## Open Questions

1. **Should profiles be stored in config files?**
   - Could use simple bash files with arrays
   - Easier to add new profiles without editing main script
   - Example: `profiles/work.sh`, `profiles/full.sh`
   - Each profile: `MODULES=("neovim" "tmux" "opencode")`

2. **Should there be a `--uninstall` option?**
   - Remove symlinks: Yes, safe and useful
   - Restore backups: Yes, if backups exist
   - Remove installed packages: No, too risky (may break other things)
   - Scope: Only handle symlinks and configs, not packages

## Code References

### Main Sections
- `/home/mtomcal/dotfiles/install.sh:43-68` - OS detection
- `/home/mtomcal/dotfiles/install.sh:70-89` - Package manager setup (macOS)
- `/home/mtomcal/dotfiles/install.sh:91-146` - System dependencies
- `/home/mtomcal/dotfiles/install.sh:148-239` - Neovim installation
- `/home/mtomcal/dotfiles/install.sh:241-382` - Go installation
- `/home/mtomcal/dotfiles/install.sh:384-418` - Oh My Zsh
- `/home/mtomcal/dotfiles/install.sh:420-456` - fnm + Node.js
- `/home/mtomcal/dotfiles/install.sh:458-476` - Tmux configuration
- `/home/mtomcal/dotfiles/install.sh:478-495` - Zsh configuration
- `/home/mtomcal/dotfiles/install.sh:497-688` - Neovim configuration
- `/home/mtomcal/dotfiles/install.sh:690-897` - AI coding agents

### Key Functions
- `/home/mtomcal/dotfiles/install.sh:18-36` - Helper functions (print_info, etc.)
- `/home/mtomcal/dotfiles/install.sh:97-116` - install_package() function
- `/home/mtomcal/dotfiles/install.sh:247-250` - version_lt() comparison function

### Configuration Files
- `/home/mtomcal/dotfiles/zsh/.zshrc.custom` - Zsh configuration (Go, fnm, aliases)
- `/home/mtomcal/dotfiles/AGENTS.md` - AI agent instructions
- `/home/mtomcal/dotfiles/README.md` - Documentation with full feature list

### Idempotency Checks
- `/home/mtomcal/dotfiles/install.sh:156` - Check nvim version before installing
- `/home/mtomcal/dotfiles/install.sh:357` - Check go command exists
- `/home/mtomcal/dotfiles/install.sh:439` - Check fnm command exists
- `/home/mtomcal/dotfiles/install.sh:674` - Conditional Go tools in Mason

## Web Research Findings

### Modern Bash Menu Patterns (2025)

**Pure Bash Solutions**:
- Built-in `select` command for numbered menus
- Custom multi-select implementations using arrays
- No external dependencies required
- Example: `select opt in "${options[@]}"; do ... done`
- Resources: [Multi-select Bash Menu](https://jonlabelle.com/snippets/view/shell/multi-select-menu-in-bash), [Baeldung Bash Select](https://www.baeldung.com/linux/shell-script-simple-select-menu), [Pure Bash TUI](https://gist.github.com/blurayne/f63c5a8521c0eeab8e9afd8baa45c65e)

**Modular Architecture Patterns**:
- Separate functions in `functions/` directory
- Main script orchestrates module execution
- Case statements for handling user choices
- Menu-driven approach avoids memorizing syntax
- Resources: [Modular Dashboard Example](https://dev.to/ghostkrypt/how-i-built-a-modular-bash-based-system-admin-dashboard-day-3030-2b98), [Menu-Driven Scripts Guide](https://bash.cyberciti.biz/guide/Menu_driven_scripts), [GeeksforGeeks Menu Script](https://www.geeksforgeeks.org/menu-driven-shell-script/)

**Best Practices**:
- Use `PS3` variable for select prompt customization
- Combine `select` for menu creation with `case` for action handling
- Keep scripts modular to avoid "spaghetti code"
- Functions make bash maintainable and testable
- Maximum portability: works on macOS, Linux, and any system with bash

### Recommended Approach

**Pure bash select implementation**:
1. Use bash select for all menus (maximum portability)
2. Start with preset profiles menu
3. Allow custom selection with multi-select toggle
4. Automatic dependency resolution with warnings
5. Summary confirmation before installation

**Example implementation skeleton**:
```bash
# Show main profile menu
show_profile_menu

# If custom selected, show component menu
if [[ "$PROFILE" == "custom" ]]; then
  show_component_menu
fi

# Resolve dependencies
resolve_dependencies

# Show summary
show_selection_summary

# Install selected modules
for module in "${SELECTED[@]}"; do
  install_module "$module"
done
```

## Sources

- [Jon LaBelle: Multi-select Menu in Bash](https://jonlabelle.com/snippets/view/shell/multi-select-menu-in-bash)
- [Baeldung: Creating a Simple Select Menu in the Shell Script](https://www.baeldung.com/linux/shell-script-simple-select-menu)
- [GitHub Gist: Pure BASH interactive CLI/TUI menu](https://gist.github.com/blurayne/f63c5a8521c0eeab8e9afd8baa45c65e)
- [DEV.to: How I Built a Modular Bash-Based System Admin Dashboard](https://dev.to/ghostkrypt/how-i-built-a-modular-bash-based-system-admin-dashboard-day-3030-2b98)
- [Cyberciti: Menu driven scripts](https://bash.cyberciti.biz/guide/Menu_driven_scripts)
- [GeeksforGeeks: Menu-Driven Shell Script](https://www.geeksforgeeks.org/menu-driven-shell-script/)

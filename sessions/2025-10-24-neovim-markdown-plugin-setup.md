# Neovim Markdown Plugin Setup Session
**Date**: 2025-10-24

## 1. Primary Request and Intent
- Determine whether to use prettierd or prettier for Neovim formatting
- Choose an appropriate markdown plugin for Neovim
- Implement the chosen markdown plugin in dotfiles repository
- Ensure the plugin works correctly and troubleshoot loading issues
- Update install.sh script to automatically enable custom plugins
- Fix install.sh to preserve Mason packages when re-running

## 2. Key Technical Concepts
- prettierd vs prettier performance (daemon architecture eliminates Node.js startup overhead)
- Neovim plugin management with lazy.nvim
- kickstart.nvim as base configuration with custom plugin loading
- render-markdown.nvim for in-editor markdown rendering
- Mason for LSP/formatter/linter management
- Symlinked dotfiles architecture
- Conventional commit messages
- Shell scripting with sed for automated configuration

## 3. Files and Code Sections

### `/home/mtomcal/dotfiles/nvim/custom/plugins/markdown.lua` (CREATED)
**Purpose**: Implements render-markdown.nvim plugin for beautiful in-editor markdown viewing

**Why important**: Provides the simplest solution for markdown rendering without extra complexity of LSP servers or browser previews

```lua
-- Markdown rendering plugin for beautiful in-editor viewing
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {},
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },
  -- Only load for markdown files
  ft = { "markdown" },
}
```

### `/home/mtomcal/.config/nvim/init.lua` (MODIFIED)
**Purpose**: Enable custom plugin loading in kickstart.nvim

**Why important**: By default, kickstart.nvim has custom plugin imports commented out. This must be enabled for custom plugins to load.

**Change made**: Line 987 changed from `-- { import = 'custom.plugins' },` to `{ import = 'custom.plugins' },`

This single line change enables kickstart.nvim to load all custom plugins from `lua/custom/plugins/*.lua`

### `/home/mtomcal/dotfiles/install.sh` (MODIFIED - Two commits)

#### First modification (lines 385-400): Added automatic custom plugin enabling
**Why important**: Automates the manual fix so future installations don't require hand-editing init.lua

```bash
# Enable custom plugins in kickstart.nvim init.lua
print_info "Enabling custom plugin loading in kickstart.nvim..."
if [ -f "$HOME/.config/nvim/init.lua" ]; then
    # Check if the import line is commented out
    if grep -q "^  -- { import = 'custom.plugins' }," "$HOME/.config/nvim/init.lua"; then
        # Uncomment the import line using sed
        sed -i "s/^  -- { import = 'custom\.plugins' },/  { import = 'custom.plugins' },/" "$HOME/.config/nvim/init.lua"
        print_success "Custom plugin loading enabled"
    elif grep -q "^  { import = 'custom.plugins' }," "$HOME/.config/nvim/init.lua"; then
        print_success "Custom plugin loading already enabled"
    else
        print_warning "Could not find custom.plugins import line in init.lua"
    fi
else
    print_warning "init.lua not found at ~/.config/nvim/init.lua"
fi
```

#### Second modification (lines 402-412): Added Mason package preservation logic
**Why important**: Prevents reinstalling all LSP servers, formatters, and linters every time the install script runs

**Problem**: Previously, the script unconditionally deleted `~/.local/share/nvim` which contains all Mason-installed tools

```bash
# Only clean cache on fresh installation (not when updating dotfiles)
if [ ! -d "$HOME/.local/share/nvim/lazy" ]; then
    print_info "Fresh installation detected - cleaning neovim cache..."
    rm -rf "$HOME/.local/share/nvim"
    rm -rf "$HOME/.local/state/nvim"
    rm -rf "$HOME/.cache/nvim"
else
    print_info "Existing neovim installation detected - preserving Mason packages and cache"
    # Only clean the cache, preserve data (Mason packages)
    rm -rf "$HOME/.cache/nvim"
fi
```

### `/tmp/test_markdown.md` (CREATED)
**Purpose**: Test file to verify render-markdown.nvim functionality

Contains sample markdown with headings, checkboxes, code blocks, and links for visual verification

## 4. Problem Solving

### Problem 1: Uncertainty about prettierd vs prettier
**Solution**: Researched and recommended prettierd for 85% faster formatting
- Regular prettier: ~1 second (850ms+ with Node.js startup)
- prettierd: ~0.14 seconds
- Daemon architecture eliminates Node.js startup cost on every format
- Same formatting results, just faster execution
- Better for format-on-save workflows

### Problem 2: Which markdown plugin to use
**Initial recommendation**: 3-plugin stack (marksman + render-markdown.nvim + markdown-preview.nvim)
**User preference**: "Let's go at the simplest solution"
**Solution**: Implemented only render-markdown.nvim for in-editor rendering
- Automatic rendering when opening .md files
- No browser preview needed
- No LSP overhead
- Zero configuration required

### Problem 3: render-markdown.nvim not loading after installation
**Symptoms**: `:RenderMarkdown` command not available in Neovim
**Investigation steps**:
1. Checked if plugin was in lazy.nvim list
2. Verified symlink exists: `~/.config/nvim/lua/custom` → `/home/mtomcal/dotfiles/nvim/custom`
3. Verified markdown.lua file exists in custom/plugins/
4. Searched for custom plugin loading in kickstart.nvim config

**Root cause**: kickstart.nvim's `{ import = 'custom.plugins' }` line was commented out by default at line 987

**Solution**: Manually uncommented line 987 in init.lua, user restarted nvim and confirmed it worked

### Problem 4: Manual fix not automated for future installations
**Solution**: Updated install.sh to automatically uncomment the import line using sed
- Checks if line is commented out before modifying
- Checks if already enabled to avoid duplicate changes
- Provides appropriate feedback messages for each case
- Runs after symlink creation but before plugin installation

### Problem 5: Running install.sh deletes all Mason packages
**Symptoms**: User reported "Running install.sh seems to nuke all my installed Mason packages"

**Root cause**: Lines 402-406 unconditionally deleted `~/.local/share/nvim`, which contains:
- Mason-installed LSP servers
- Mason-installed formatters
- Mason-installed linters
- Neovim undo history
- Other persistent data

**Solution**: Modified script to detect fresh vs. existing installations
- Fresh installs (no `~/.local/share/nvim/lazy` directory): Full cleanup for pristine state
- Existing installs: Only clear `~/.cache/nvim`, preserve all data
- This allows re-running install.sh to update configs without reinstalling all tools

## 5. Pending Tasks
None explicitly requested. All tasks have been completed.

## 6. Current Work
The final work completed was fixing the install.sh script to preserve Mason packages when re-running the script.

**The issue**: Lines 402-406 unconditionally deleted `~/.local/share/nvim`, which contains all Mason-installed tools (LSP servers, formatters, linters), forcing a complete reinstall every time the script ran.

**The fix**:
1. Read install.sh lines 402-411 to understand the cleanup logic
2. Modified the cleanup to be conditional based on whether `~/.local/share/nvim/lazy` exists
3. Fresh installs (no lazy directory) get full cleanup for pristine state
4. Existing installs preserve `~/.local/share/nvim` and only clear cache
5. Committed the change with message "fix: preserve Mason packages when re-running install script"

**Commit hash**: `8d68093`

**User confirmation**: User's last message requesting to save this session indicates satisfaction with all completed work.

## 7. Optional Next Step
None - all requested tasks have been completed. The conversation concluded with the successful fix for preserving Mason packages. The user has not requested any additional work.

## Git Commits Made
1. `e49e36a` - "feat: add render-markdown.nvim for in-editor markdown rendering"
2. `db8accb` - "fix: automatically enable custom plugin loading in kickstart.nvim"
3. `8d68093` - "fix: preserve Mason packages when re-running install script"

## Commands for User Reference

### Using render-markdown.nvim
- **Open markdown file**: `nvim README.md` (renders automatically)
- **Toggle rendering**: `:RenderMarkdown toggle`
- **Enable rendering**: `:RenderMarkdown enable`
- **Disable rendering**: `:RenderMarkdown disable`

### Testing the setup
```bash
# Test with the created test file
nvim /tmp/test_markdown.md

# Or test with your own README
cd ~/dotfiles
nvim README.md
```

### Re-running install.sh safely
```bash
cd ~/dotfiles
./install.sh
# Now preserves Mason packages on updates!
```

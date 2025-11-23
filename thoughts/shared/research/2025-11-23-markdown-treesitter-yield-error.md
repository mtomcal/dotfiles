---
date: 2025-11-23T05:37:04+00:00
researcher: Claude Code
git_commit: a9dfbb863be9dbeb30dd4637ada02dbe15567e82
branch: main
repository: dotfiles
topic: "Treesitter yield across C-call boundary error in markdown buffers"
tags: [research, codebase, neovim, treesitter, markdown, render-markdown, bug]
status: complete
last_updated: 2025-11-23
last_updated_by: Claude Code
---

# Research: Treesitter yield across C-call boundary error in markdown buffers

**Date**: 2025-11-23T05:37:04+00:00
**Researcher**: Claude Code
**Git Commit**: a9dfbb863be9dbeb30dd4637ada02dbe15567e82
**Branch**: main
**Repository**: dotfiles

## Research Question

Why am I getting this error in markdown buffers when they open:

```
vim.schedule callback: /usr/share/nvim/runtime/lua/vim/treesitter/languagetree.lua:424:
attempt to yield across C-call boundary
stack traceback:
        [C]: in function 'yield'
        /usr/share/nvim/runtime/lua/vim/treesitter/languagetree.lua:424: in function '_parse_regions'
        /usr/share/nvim/runtime/lua/vim/treesitter/languagetree.lua:631: in function '_parse'
        /usr/share/nvim/runtime/lua/vim/treesitter/languagetree.lua:598: in function 'parse'
        ...ender-markdown.nvim/lua/render-markdown/request/view.lua:62: in function 'parse'
        ...azy/render-markdown.nvim/lua/render-markdown/core/ui.lua:159: in function 'parse'
        ...azy/render-markdown.nvim/lua/render-markdown/core/ui.lua:132: in function 'render'
        ...azy/render-markdown.nvim/lua/render-markdown/core/ui.lua:115: in function 'run'
        ...azy/render-markdown.nvim/lua/render-markdown/core/ui.lua:81: in function
```

## Summary

**This is a known Neovim regression bug, not a problem with your configuration.** You're experiencing a documented issue that affects Neovim v0.12.0-dev builds when using the render-markdown.nvim plugin. The error occurs because treesitter's `parse()` function attempts to yield (pause a coroutine) when called from within a `vim.schedule()` callback, which Lua doesn't allow across C function boundaries.

**Your Neovim version**: `NVIM v0.12.0-dev` (confirmed affected version)

**Root cause**: Neovim regression introduced in commit `f4fc769c81af6f8d9235d59aec75cfe7c104b3ce`

**Status**: Known bug tracked in Neovim issues #33277 and #33329, assigned to v0.12 milestone but not yet fixed

## Detailed Findings

### Current Configuration

Your dotfiles have a minimal, correct configuration for render-markdown.nvim:

**File**: `nvim/custom/plugins/markdown.lua`
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

**Configuration assessment**: This is correctly configured with default settings and appropriate dependencies. The issue is NOT caused by misconfiguration.

### Treesitter Configuration

Your treesitter setup includes both required markdown parsers:
- `markdown` parser (base markdown syntax)
- `markdown_inline` parser (inline markdown elements)

These are installed via kickstart.nvim's base configuration at `~/.config/nvim/init.lua:947`.

### Root Cause Analysis

The error occurs due to a specific interaction between three components:

1. **render-markdown.nvim**: Calls `vim.treesitter.parse()` regularly to render markdown
2. **vim.schedule()**: Schedules parsing callbacks asynchronously
3. **Neovim treesitter**: Attempts to yield during parsing on large/complex files

The problem sequence:
1. render-markdown.nvim calls `parse()` inside a `vim.schedule()` callback
2. Treesitter's `languagetree.lua:424` attempts to `yield` during `_parse_regions()`
3. Lua runtime rejects the yield because it crosses a C function call boundary
4. Error is raised and displayed to user

### Affected Conditions

The error requires **all** of these conditions:
- Running Neovim v0.12.0-dev (development build)
- Using render-markdown.nvim plugin
- Opening markdown files (particularly medium to large files ~800+ lines)
- Treesitter attempting to parse complex markdown structures

### Upstream Issue Tracking

**Neovim Issue #33277**: "Treesitter: parse error 'attempt to yield across C-call boundary'"
- Labeled as `bug-regression`
- Assigned to v0.12 milestone
- Bisected to commit `f4fc769c81af6f8d9235d59aec75cfe7c104b3ce`
- Status: Identified but not yet resolved

**Neovim Issue #33329**: "treesitter parser attempt to yield C-call boundary error"
- Duplicate/related issue with additional reproduction cases
- Cross-referenced with #33277

**render-markdown.nvim Issue #387**: "bug: attempt to yield C-call boundary"
- Plugin author investigated and determined: **not a plugin bug**
- Author's response: "After I call parse I don't have much say in how neovim handles it"
- Closed as "not a bug" - correctly identified as Neovim issue
- Author will monitor situation closer to v0.12.0 official release

## Code References

- `nvim/custom/plugins/markdown.lua` - render-markdown.nvim configuration
- `~/.config/nvim/init.lua:947` - kickstart.nvim treesitter parser configuration
- `/usr/share/nvim/runtime/lua/vim/treesitter/languagetree.lua:424` - Error origin in Neovim

## Architecture Insights

### Plugin Architecture
render-markdown.nvim uses a callback-based rendering system:
1. Registers for markdown filetype events
2. Uses `vim.schedule()` to defer parsing operations
3. Calls treesitter's `parse()` to analyze markdown structure
4. Renders enhanced visual elements based on syntax tree

This architecture is sound and works correctly in Neovim v0.11.0.

### Regression Impact
The regression specifically affects plugins that:
- Call `vim.treesitter.parse()` within scheduled callbacks
- Process moderately large or complex files
- Rely on treesitter's parsing yielding behavior

## Workarounds

### Option 1: Downgrade Neovim (Recommended)
```bash
# Install stable Neovim v0.11.0
# This is the most reliable solution until v0.12.0 is officially released with the fix
```

**Pros**: Completely eliminates the error, all features work correctly
**Cons**: Miss out on v0.12.0-dev features

### Option 2: Disable render-markdown.nvim temporarily
Edit `nvim/custom/plugins/markdown.lua`:
```lua
return {
  "MeanderingProgrammer/render-markdown.nvim",
  enabled = false,  -- Add this line
  opts = {},
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },
  ft = { "markdown" },
}
```

**Pros**: Eliminates error while keeping v0.12.0-dev
**Cons**: Lose enhanced markdown rendering features

### Option 3: Ignore the error
The error is primarily cosmetic - it appears on markdown buffer open but doesn't prevent functionality.

**Pros**: No changes needed, markdown still works
**Cons**: Error message appears every time, potentially annoying

### Option 4: Wait for Neovim fix
Monitor Neovim issue #33277 for resolution, then update Neovim.

**Pros**: Proper fix from upstream
**Cons**: Timeline uncertain, may take weeks/months

## Recommendation

**Recommended action**: **Option 1 - Downgrade to Neovim v0.11.0**

**Rationale**:
1. v0.12.0 is still in development and not officially released
2. The regression is known and being actively tracked
3. v0.11.0 is stable and all your plugins work correctly with it
4. You can upgrade to v0.12.0 once it's officially released with the fix
5. Your configuration is correct and requires no changes

**How to verify your Neovim version after change**:
```bash
nvim --version | head -1
```

Expected output after downgrade: `NVIM v0.11.0` or similar stable release

## Open Questions

1. **When will Neovim v0.12.0 fix be released?**
   - Unknown - the issue is assigned to v0.12 milestone but no fix merged yet
   - Monitor: https://github.com/neovim/neovim/issues/33277

2. **Are there other plugins affected by this regression?**
   - Potentially yes - any plugin calling `vim.treesitter.parse()` in scheduled callbacks
   - No comprehensive list available yet

3. **Will the fix require plugin authors to change their code?**
   - Unknown - depends on whether Neovim changes the API or fixes internal behavior
   - render-markdown.nvim author is monitoring the situation

## Related Research

No previous research documents in this repository addressed treesitter errors or render-markdown issues.

## Additional Resources

- [Neovim Issue #33277](https://github.com/neovim/neovim/issues/33277) - Primary tracking issue
- [Neovim Issue #33329](https://github.com/neovim/neovim/issues/33329) - Related issue
- [render-markdown.nvim Issue #387](https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/387) - Plugin perspective
- [render-markdown.nvim repository](https://github.com/MeanderingProgrammer/render-markdown.nvim) - Plugin homepage

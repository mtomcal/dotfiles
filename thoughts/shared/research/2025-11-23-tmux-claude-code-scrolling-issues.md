---
date: 2025-11-23T06:30:19+00:00
researcher: Claude
git_commit: b409378b6b6b53e8d3f84dd3a8ffcd2230a4f0ce
branch: main
repository: dotfiles
topic: "Why does tmux scroll excessively with Claude Code usage in 2025?"
tags: [research, tmux, claude-code, terminal, scrolling, iterm2, performance]
status: complete
last_updated: 2025-11-23
last_updated_by: Claude
---

# Research: Why does tmux scroll excessively with Claude Code usage in 2025?

**Date**: 2025-11-23T06:30:19+00:00
**Researcher**: Claude
**Git Commit**: b409378b6b6b53e8d3f84dd3a8ffcd2230a4f0ce
**Branch**: main
**Repository**: dotfiles

## Research Question
Why does tmux scroll a lot with Claude Code usage in 2025, particularly when using iTerm2?

## Summary
The excessive scrolling in tmux when using Claude Code is caused by Claude Code's full-screen redraw rendering strategy during streaming output. This produces **4,000-6,700 scroll events per second** (sustained), which is 40-600x higher than typical terminal usage. The issue is particularly noticeable in terminal multiplexers like tmux and affects users across different terminal emulators including iTerm2. This is a known architectural issue with Claude Code's TUI implementation, not a configuration problem with tmux.

## Detailed Findings

### Root Cause: Claude Code's Rendering Strategy

Claude Code uses a **full-screen redraw strategy** for streaming output rather than incremental updates. Each chunk of the LLM response triggers a complete view re-render, causing:

- **4,000-6,700 scroll events per second** during streaming (Issue #9935)
- This is 40-600x higher than typical terminal usage:
  - vim: 10-50 scrolls/second
  - npm install: 100-300 scrolls/second
  - Claude Code: 4,000-6,700 scrolls/second (SUSTAINED)

The entire terminal buffer redraws with each update, causing severe UI jitter and flickering in terminal multiplexers.

**GitHub Issue**: https://github.com/anthropics/claude-code/issues/9935

### Specific Issues Documented

#### 1. **Unpredictable Scrolling Through Shell History (iTerm2)**
- Occurs approximately 1 in every 100 commands
- Claude unpredictably scrolls through entire shell stdout history
- Persists for 5-20 commands before stopping
- Specific to iTerm2 usage

**GitHub Issue**: https://github.com/anthropics/claude-code/issues/367

#### 2. **Scrollback Buffer Performance Degradation**
- After a few thousand lines of interaction, performance degrades significantly
- Each keystroke and window resize triggers "scrollback buffer flashing" from session start
- Increased CPU usage makes extended coding sessions impractical
- Current workaround: Restart Claude Code sessions frequently using `/quit`
- Scrollback buffer maintained internally by Claude Code, not just terminal/tmux

**GitHub Issue**: https://github.com/anthropics/claude-code/issues/4851

#### 3. **Mouse Scroll Direction Issue**
- Mouse wheel scrolls input box instead of output/conversation area in tmux
- Makes reviewing previous responses extremely difficult
- Specific to tmux environment

**GitHub Issue**: https://github.com/anthropics/claude-code/issues/9902

#### 4. **Scrollback Completely Broken (v1.0.119)**
- Users can't scroll back to previous pages
- tmux scrollback buffer shows [0/0]
- Workaround: Revert to version 1.0.88

**GitHub Issue**: https://github.com/anthropics/claude-code/issues/7898

#### 5. **Continuous Scrolling from Excessive Blank Lines**
- Excessive blank lines cause continuous scrolling
- Screen scrolls during every keystroke
- Scrolls while Claude is thinking/executing
- Makes tool unusable

**GitHub Issue**: https://github.com/anthropics/claude-code/issues/10472

#### 6. **Console Scrolling to Top of History**
- Once text history reaches 5-6 pages, terminal scrolls back and forth to top
- Happens every time a new character is typed
- Occurs whenever Claude adds text

**GitHub Issue**: https://github.com/anthropics/claude-code/issues/826

### Current tmux Configuration Analysis

Your tmux configuration at `tmux/.tmux.conf:25` has:
```bash
set -g history-limit 50000
```

This is a reasonable scrollback buffer size (50,000 lines), significantly higher than tmux's default of 2,000 lines. The recommended configuration for Claude Code is 1,000,000 lines, but increasing this won't solve the root cause - it may only delay when the performance degradation becomes noticeable.

**Configuration reference**: `tmux/.tmux.conf:25`

Your configuration also has mouse support enabled:
```bash
set -g mouse on
```
**Configuration reference**: `tmux/.tmux.conf:28`

### iTerm2 + tmux Integration Considerations

When using iTerm2 with tmux:
- iTerm2 has native tmux integration mode which can cause additional scrollback buffer issues
- Text-mode tmux clients can sink data much faster than tmux integration
- This causes large buffers to grow in tmux integration windows
- Memory issues occur with scrollback buffers >20M lines

### Technical Details: ANSI Escape Codes and Scroll Regions

The underlying issue relates to how Claude Code uses terminal control sequences:
- Should use line-specific updates via DECSTBM (Set Top and Bottom Margins) escape sequences
- Instead uses full-screen redraws for status updates
- tmux filters/interprets ANSI escape codes, adding another layer of complexity
- Scroll region control: `\033[top;bottomr` format

## Recommended Solutions

### Immediate Workarounds

1. **Increase tmux scrollback buffer** (already done in your config):
   ```bash
   set -g history-limit 1000000  # Increase from 50000 to 1M
   ```

2. **Restart Claude Code sessions frequently**:
   - Use `/quit` command to terminate sessions after extended use
   - Prevents scrollback buffer accumulation
   - Reduces CPU usage degradation

3. **Disable iTerm2 tmux integration** (if using):
   - Use standard tmux mode instead of iTerm2's native integration
   - Reduces buffer synchronization issues

4. **Reduce visible history**:
   - Clear terminal before starting Claude Code sessions
   - Keep conversation history shorter

### Long-term Fix (Requires Claude Code Update)

The proper fix must be implemented in Claude Code's rendering strategy:
- Implement **incremental updates** instead of full-screen redraws
- Use **line-specific terminal control sequences** for status updates
- Implement **batched output** to reduce scroll rate to <100 scrolls/second
- Optimize for terminal multiplexer environments

This is an acknowledged architectural issue that Anthropic's team is aware of based on the GitHub issues.

## Architecture Insights

- Claude Code maintains its own internal scrollback buffer separate from terminal/tmux
- Streaming output strategy prioritizes immediate visual feedback over performance
- Terminal multiplexers add an additional layer that amplifies the scroll event problem
- Full-screen TUI redraws are common in terminal applications but problematic at Claude Code's update frequency

## Open Questions

1. Is there a configuration option to reduce Claude Code's update frequency?
2. Does Claude Code have a "reduced motion" or "performance mode" setting for terminal multiplexers?
3. What is the timeline for implementing incremental rendering in Claude Code?
4. Are there alternative terminal emulators that handle high scroll rates better than iTerm2 + tmux?

## Related Research

- Terminal multiplexer performance optimization
- ANSI escape code handling in tmux
- iTerm2 tmux integration architecture
- TUI rendering strategies for streaming applications

## Notes

- This issue affects multiple terminal emulators and platforms (not just iTerm2)
- The 4,000-6,700 scrolls/second rate is unprecedented in typical terminal usage
- Community consensus: This is a Claude Code architectural issue, not a user configuration problem
- Multiple GitHub issues created by different users experiencing identical symptoms

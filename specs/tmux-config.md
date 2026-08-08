# Tmux Configuration Specification

> **Version**: 1.1.0
> **Last Updated**: 2026-07-05
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md)
> **Depended By**: Install Orchestrator, Shell Config

---

## Overview

The tmux configuration provides a terminal multiplexer setup optimized for Neovim-centric development within tmux sessions. It defines a complete keybinding scheme, visual theme, session behavior, and nested-session support.

As of the Herdr migration, tmux remains installed and configured as a legacy fallback rather than the default SSH multiplexer. This spec remains authoritative for tmux behavior whenever tmux is launched manually or selected through the SSH fallback override.

The configuration is deployed as a single symlink from `~/.tmux.conf` pointing to the version-controlled source in the dotfiles repository. All behavioral requirements in this spec apply equally to the configuration file and any supporting scripts.

**Core design goals**:
- Zero-latency input for modal editing (Neovim)
- Vim-consistent navigation across panes and windows
- First-class nested tmux session support with visual mode feedback
- True color rendering for modern terminal applications
- Ergonomic prefix key on Ctrl-a instead of default Ctrl-b
- Compatibility fallback while Herdr becomes the default terminal workspace manager

---

## Dependencies

### Technology Dependencies

| Dependency | Version Constraint | Purpose |
|------------|-------------------|---------|
| tmux | 3.2+ | Required for `extended-keys`, `terminal-features`, and `set-clipboard` support |
| xclip or xsel | Any | System clipboard integration in copy mode (Linux) |
| bash | 4.0+ | Required by the reverse-panes helper script |

### Spec Dependencies

| Spec | Reason |
|------|--------|
| [Parameters](parameters.md) | Authoritative source for `TMUX_PREFIX`, `TMUX_ESCAPE_TIME`, `TMUX_DEFAULT_TERMINAL`, `TMUX_FOCUS_EVENTS`, `NESTED_SESSION_KEY` |
| [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md) | Shared terms: prefix key, deploy, backup, idempotent |
| [Design Language](DESIGN_LANGUAGE.md) | Visual tokens: `multiplexer-prefix-key`, `tmux-nested-dim`, prefix command patterns |

---

## Parameters

All parameters defined in [Parameters > Tmux](parameters.md) are authoritative. They are repeated here for reference but MUST match the Parameters spec.

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `TMUX_PREFIX` | Ctrl-a | key | Screen-compatible prefix; easier to reach than default Ctrl-b; single-key for most operations after prefix |
| `TMUX_ESCAPE_TIME` | 0 | milliseconds | Zero delay required for Neovim keybinding responsiveness; any delay causes noticeable lag in modal editing |
| `TMUX_DEFAULT_TERMINAL` | tmux-256color | terminfo | Required for true color support in Neovim and terminal applications |
| `TMUX_FOCUS_EVENTS` | on | toggle | Required for Neovim autoread and autowrite features to detect focus changes |
| `NESTED_SESSION_KEY` | F12 | key | Rarely used by applications; easy to toggle; dims status bar as visual feedback |
| `TMUX_HISTORY_LIMIT` | 50000 | lines | Large scrollback for reviewing long-running process output without truncation |
| `TMUX_DISPLAY_TIME` | 4000 | ms | Status messages visible long enough to read without lingering |
| `TMUX_STATUS_INTERVAL` | 5 | seconds | Clock updates every 5 seconds; balances responsiveness with performance |
| `TMUX_RESIZE_INCREMENT` | 5 | cells | Standard resize step for pane resizing; repeatable via `-r` flag |
| `TMUX_BASE_INDEX` | 1 | number | Windows and panes numbered starting from 1, which is more natural than 0 |
| `TMUX_STATUS_LEFT_LENGTH` | 20 | characters | Maximum width for the status-left area; session name and username truncated if exceeded |
| `TMUX_STATUS_RIGHT_LENGTH` | 150 | characters | Maximum width for the status-right area; time and date display within this limit |

---

## Data Structures

### Session State

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| session_name | string | non-empty | Displayed in the status-left area; shows the tmux session name |
| active_key_table | enum | `root` \| `off` | Determines whether prefix commands are processed by outer session (`root`) or pass through to inner session (`off`) |
| mode | enum | `normal` \| `copy-mode-vi` | Current pane mode; affects keybinding availability |
| current_path | string | filesystem path | Working directory of the current pane; used as default for new panes and windows |

### Window Display State

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| window_index | integer | ≥ 1 | Window number; renumbered on window close to maintain contiguous sequence |
| window_name | string | auto-generated | Format: `{folder_name}:{command_name}` derived from pane path and running process |
| is_active | boolean | — | Indicates the currently selected window; styled distinctively in status bar |

### Pane State

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| pane_id | string | tmux internal | Unique pane identifier used by swap and join operations |
| pane_position | enum | `L` \| `D` \| `U` \| `R` | Relative position for navigation: left, down, up, right |
| pane_current_path | string | filesystem path | Inherited by new splits and windows created from this pane |
| pane_in_mode | boolean | — | Whether the pane is in copy mode; affects F12 cancel behavior |

### Nested Session Toggle State

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| prefix_override | enum | `Ctrl-a` \| `None` | When `None`, all prefix keybindings are disabled in the outer session |
| key_table | enum | `root` \| `off` | Active key table; `off` disables all tmux bindings, passing keys through |
| status_style_override | enum | `normal` \| `dimmed` | Visual indicator of which session layer is active; `dimmed` = darker background |

---

## Behavior

### Prefix Key

| Rule ID | Rule |
|---------|------|
| TMUX-PREFIX-001 | The prefix key MUST be set to `Ctrl-a`. The default `Ctrl-b` MUST be unbound. |
| TMUX-PREFIX-002 | Pressing `Ctrl-a` followed by `Ctrl-a` MUST send the prefix key through to the inner session, enabling commands in nested tmux. |

### Nested Session Support

| Rule ID | Rule |
|---------|------|
| TMUX-NEST-001 | Pressing `F12` when the `root` key table is active MUST toggle to the `off` key table, disable all prefix bindings (set prefix to `None`), dim the status bar (darker background color), and refresh the client display. |
| TMUX-NEST-002 | Pressing `F12` when the `off` key table is active MUST restore the prefix to its default value, restore the `root` key table, restore the original status bar style, and refresh the client display. |
| TMUX-NEST-003 | If a pane is in copy mode when F12 is pressed (toggling to `off`), the copy mode MUST be cancelled before the toggle takes effect. |
| TMUX-NEST-004 | The dimmed status bar MUST use foreground `colour245` on background `colour238` to provide clear visual feedback that inner session control is active. |

### Window and Pane Numbering

| Rule ID | Rule |
|---------|------|
| TMUX-INDEX-001 | Window numbering MUST start at 1 (not the default 0). |
| TMUX-INDEX-002 | Pane numbering MUST start at 1. |
| TMUX-INDEX-003 | When a window is closed, remaining windows MUST be renumbered to maintain a contiguous sequence. |

### Pane Management

| Rule ID | Rule |
|---------|------|
| TMUX-PANE-000a | The default horizontal split binding (`prefix + `"`") MUST be unbound. |
| TMUX-PANE-000b | The default vertical split binding (`prefix + `%`) MUST be unbound. |
| TMUX-PANE-001 | Splitting horizontally (prefix + `\|`) MUST create a vertical split (left/right) with the new pane inheriting the current pane's working directory. |
| TMUX-PANE-002 | Splitting vertically (prefix + `-`) MUST create a horizontal split (top/bottom) with the new pane inheriting the current pane's working directory. |
| TMUX-PANE-003 | Creating a new window (prefix + `c`) MUST create it adjacent to the current window (not at the end) and inherit the current pane's working directory. |
| TMUX-PANE-004 | Navigation across panes MUST use vim-style keys: `h` (left), `j` (down), `k` (up), `l` (right). |
| TMUX-PANE-005 | Resizing panes MUST use uppercase vim-style keys with repeat support: `H` (left by 5), `J` (down by 5), `K` (up by 5), `L` (right by 5). |
| TMUX-PANE-006 | Merging panes (prefix + `M`) MUST merge all panes from the current window into the previous window side by side, then switch focus to that previous window. |
| TMUX-PANE-007 | Breaking a pane (prefix + `B`) MUST move the current pane into a new adjacent window. |
| TMUX-PANE-008 | Exploding panes (prefix + `E`) MUST break every pane in the current window (except one) into separate adjacent windows until only one pane remains. |
| TMUX-PANE-009 | Reversing pane order (prefix + `R`) MUST swap panes such that the first becomes last and vice versa, using pairwise swaps. |
| TMUX-PANE-010 | Equalizing horizontal layout (prefix + `V`) MUST rearrange all panes into equal vertical columns. |

### Window Navigation

| Rule ID | Rule |
|---------|------|
| TMUX-WIN-001 | Moving to the previous window MUST use `Ctrl-h` (repeatable without re-pressing prefix). |
| TMUX-WIN-002 | Moving to the next window MUST use `Ctrl-l` (repeatable without re-pressing prefix). |
| TMUX-WIN-003 | Swapping the current window left (prefix + `<`) MUST move the window to the previous index and switch focus to it. |
| TMUX-WIN-004 | Swapping the current window right (prefix + `>`) MUST move the window to the next index and switch focus to it. |

### Copy Mode

| Rule ID | Rule |
|---------|------|
| TMUX-COPY-001 | Copy mode MUST use vi-style keybindings. |
| TMUX-COPY-002 | Pressing `v` in copy mode MUST begin a visual selection. |
| TMUX-COPY-003 | Pressing `y` in copy mode MUST copy the current selection to the system clipboard and exit copy mode. **Note**: the configuration binds `y` twice in copy-mode-vi — first `copy-selection-and-cancel`, then `copy-pipe-and-cancel` with the xclip pipeline. The later binding takes precedence, so `y` effectively copies via the pipeline defined in TMUX-COPY-004. The earlier binding is inert. |
| TMUX-COPY-004 | The system clipboard integration MUST use `xclip -in -selection clipboard` as the copy pipeline. |

### Terminal and Display

| Rule ID | Rule |
|---------|------|
| TMUX-TERM-001 | The default terminal MUST be set to `tmux-256color` with true color override for `xterm-256color`. |
| TMUX-TERM-002 | RGB color feature MUST be enabled for all xterm-compatible terminals. |
| TMUX-TERM-003 | Escape time MUST be set to 0 milliseconds to prevent input delay. |
| TMUX-TERM-004 | Focus events MUST be enabled for terminals that support them. |
| TMUX-TERM-005 | Extended keys MUST be enabled for modified key sequences (required by Pi coding agent). |
| TMUX-TERM-006 | Mouse support MUST be enabled. |
| TMUX-TERM-007 | System clipboard integration (`set-clipboard`) MUST be enabled. |
| TMUX-TERM-008 | Activity monitoring MUST be enabled on windows, but visual alerts MUST be disabled (no disruptive notifications). |

### Automatic Renaming and Titles

| Rule ID | Rule |
|---------|------|
| TMUX-RENAME-001 | Automatic window renaming MUST be enabled. |
| TMUX-RENAME-002 | The automatic rename format MUST be `{folder_name}:{command_name}` — the basename of the pane's current path, a colon separator, and the pane's current command. |
| TMUX-RENAME-003 | Terminal window titles MUST be set to the format `session:window.pane window_name`. |

### Status Bar

| Rule ID | Rule |
|---------|------|
| TMUX-STATUS-001 | The status bar background MUST be `colour235` with foreground `colour136`. |
| TMUX-STATUS-002 | The current window MUST be displayed with foreground `colour166` on background `colour235` in bold. Format: window index `#I`, colon separator in `colour250`, window name `#W` in `colour255`, window flags `#F` in `colour50`. |
| TMUX-STATUS-003 | Inactive windows MUST be displayed with foreground `colour244` on background `colour235`. Format: window index `#I`, colon separator in `colour237`, window name `#W` in `colour250`, window flags `#F` in `colour244`. |
| TMUX-STATUS-004 | The active pane border MUST be `colour51`; inactive pane borders MUST be `colour238`. |
| TMUX-STATUS-005 | The status-left MUST show the session name (bold, `colour235` on `colour252`) followed by the current username (bold, `colour245` on `colour238`), truncated to 20 characters. |
| TMUX-STATUS-006 | The status-right MUST show the time (`colour245` on `colour238`) and the date (bold, `colour235` on `colour252`), with up to 150 characters available. |
| TMUX-STATUS-007 | The window list MUST be left-justified in the status bar. |
| TMUX-STATUS-008 | Message text MUST use foreground `colour166` on background `colour235`. |

### Configuration Reload

| Rule ID | Rule |
|---------|------|
| TMUX-RELOAD-001 | Pressing prefix + `r` MUST reload the configuration file and display the message "Config reloaded!". |

### Deployment

| Rule ID | Rule |
|---------|------|
| TMUX-DEPLOY-001 | The configuration MUST be deployed by creating a symlink from `~/.tmux.conf` to the repository source. |
| TMUX-DEPLOY-002 | If a regular file (non-symlink) exists at `~/.tmux.conf`, it MUST be backed up with a timestamp before the symlink is created. |
| TMUX-DEPLOY-003 | If a symlink already exists at `~/.tmux.conf`, it MUST be removed before creating the new symlink. |
| TMUX-DEPLOY-004 | The deployment function MUST verify tmux is installed before attempting to deploy; if missing, it MUST attempt to install base tools first. |

---

## Error Handling

| Error Case | Trigger | Detection | Response | Recovery |
|------------|---------|-----------|----------|----------|
| Missing tmux binary | Deployment attempted without tmux installed | `command -v tmux` returns non-zero | Print warning; attempt to install base tools; abort configuration phase if installation fails | Install tmux manually and re-run install |
| Symlink conflict (regular file) | `~/.tmux.conf` exists as a non-symlink file | File exists AND is not a symlink | Back up existing file with timestamp; remove original; create symlink | No recovery needed — backup preserves original |
| Symlink conflict (existing symlink) | `~/.tmux.conf` exists as a symlink | File exists AND is a symlink | Remove existing symlink; create new symlink pointing to dotfiles source | No recovery needed — old symlink is replaced |
| Missing clipboard tool | Copy mode yank issued without xclip/xsel | Copy operation produces no error but clipboard is empty | No runtime error; clipboard integration silently degrades | Install xclip (Linux) or use built-in clipboard (macOS) |
| Nested session toggle in copy mode | F12 pressed while pane is in copy mode | Pane is in copy mode (`#{pane_in_mode}` is true) | Cancel copy mode before toggling key table | No recovery needed — mode is cancelled gracefully |
| Reverse panes script not found | Prefix + R pressed but helper script is missing | Script file not at expected path | Tmux shell command fails silently; panes remain in original order | Ensure the dotfiles repository is intact and the symlink is correct |

---

## Implementation Notes

1. **Single-file configuration**: The entire tmux configuration resides in one file. Any helper scripts (e.g., reverse-panes) are referenced by repository-relative path within the dotfiles repository. This keeps the deployment simple (one symlink) while allowing auxiliary scripts.

2. **Symlink-only deployment**: The configuration MUST NOT be copied — it MUST be symlinked. This ensures changes in the repository are immediately active after a config reload (`prefix + r`).

3. **Nested session design**: The F12 toggle is a two-state machine (`root` ↔ `off`). The visual indicator (dimmed status bar) is critical for operator awareness. Without it, users cannot tell which session layer receives prefix commands.

4. **Copy mode clipboard fallback**: On Linux, `xclip` is the primary clipboard integration tool. On macOS, the system clipboard is accessed natively. The configuration uses `xclip -in -selection clipboard` which will fail silently on macOS; the `set-clipboard on` setting handles macOS clipboard integration independently.

5. **Pane split inheritance**: All new panes and windows inherit `#{pane_current_path}` from the originating pane. This is a deliberate choice so that opening a new split or window in a project directory retains the working directory, rather than defaulting to the home directory.

6. **Adjacent window creation**: New windows created with `prefix + c` use the `-a` flag to place the window next to the current one rather than at the end. This preserves spatial locality in the window list.

7. **Repeatable resize**: The resize bindings use the `-r` flag, allowing multiple resize steps without re-pressing the prefix key. This applies to both pane resize (`H`/`J`/`K`/`L`) and window navigation (`Ctrl-h`/`Ctrl-l`).

8. **Pane merge edge case**: The merge operation (prefix + `M`) joins panes into the previous window (index minus 1). When only one window exists, the merge has no target and produces no effect. This is acceptable — the binding simply has no visible result.

---

## Test Scenarios

```
TS-TMUX-001: Prefix key is Ctrl-a
Category: Integration
Priority: Critical
Preconditions: Tmux session is active with the deployed configuration
Input: Press Ctrl-a followed by any command key (e.g., ? for help)
Expected Output: Tmux help or the command executes; Ctrl-b produces no response

TS-TMUX-002: Prefix sent to nested session
Category: Integration
Priority: High
Preconditions: Running inside a nested tmux session (tmux within tmux)
Input: Press Ctrl-a, then Ctrl-a, then c
Expected Output: New window created in the inner session, not the outer session

TS-TMUX-003: F12 toggles to inner session control
Category: Integration
Priority: Critical
Preconditions: Running inside nested tmux sessions
Input: Press F12 (toggle to inner mode)
Expected Output: Status bar background dims to colour238; all outer tmux keybindings are disabled; keystrokes pass through to inner session

TS-TMUX-004: F12 toggles back to outer session
Category: Integration
Priority: Critical
Preconditions: F12 has already been pressed (inner mode active)
Input: Press F12 again (toggle back to outer mode)
Expected Output: Status bar restores to normal style; prefix key is re-enabled; outer tmux keybindings work again

TS-TMUX-005: F12 cancels copy mode before toggling
Category: Integration
Priority: High
Preconditions: A pane is in copy mode (prefix + [)
Input: Press F12 while pane is in copy mode
Expected Output: Copy mode is cancelled; then toggle to inner session mode occurs; status bar dims

TS-TMUX-006: Window numbering starts at 1
Category: Unit
Priority: Critical
Preconditions: Fresh tmux session
Input: Create a new window (prefix + c)
Expected Output: First window is numbered 1; second window is numbered 2

TS-TMUX-007: Windows renumber on close
Category: Unit
Priority: High
Preconditions: Three windows open (indices 1, 2, 3)
Input: Close window 2 (prefix + &)
Expected Output: Window 3 is renumbered to 2; no gap in numbering

TS-TMUX-008: Pane split inherits current path
Category: Integration
Priority: High
Preconditions: Pane is in a directory other than home (e.g., ~/projects/myapp)
Input: Press prefix + | (horizontal split)
Expected Output: New pane opens in the same directory ~/projects/myapp

TS-TMUX-009: New window inherits current path and is adjacent
Category: Integration
Priority: High
Preconditions: Two windows exist, current window is 1, in ~/projects/myapp
Input: Press prefix + c (new window)
Expected Output: New window appears as window 2 (between 1 and old 2), with working directory ~/projects/myapp

TS-TMUX-010: Vim-style pane navigation
Category: Unit
Priority: Critical
Preconditions: Multiple panes open (e.g., left and right)
Input: Press prefix + l (navigate right)
Expected Output: Focus moves to the pane to the right; prefix + h returns to left pane

TS-TMUX-011: Repeatable pane resize
Category: Unit
Priority: Medium
Preconditions: Multiple panes with room to resize
Input: Press prefix + L, then L again (without re-pressing prefix)
Expected Output: Pane resizes right by 5 cells, then another 5 cells, without requiring prefix between presses

TS-TMUX-012: Copy mode vi selection and yank
Category: Integration
Priority: High
Preconditions: Pane has visible text output
Input: Enter copy mode (prefix + [), press v, select text with movement keys, press y
Expected Output: Selected text is copied to system clipboard; copy mode exits

TS-TMUX-013: Config reload
Category: Unit
Priority: Medium
Preconditions: Configuration file has been modified
Input: Press prefix + r
Expected Output: Message "Config reloaded!" appears; new settings take effect immediately

TS-TMUX-014: Deployment creates symlink
Category: Integration
Priority: Critical
Preconditions: No existing file at ~/.tmux.conf
Input: Run the install script's tmux configuration phase
Expected Output: ~/.tmux.conf is a symlink pointing to the dotfiles repository source

TS-TMUX-015: Deployment backs up existing config
Category: Integration
Priority: High
Preconditions: A regular (non-symlink) file exists at ~/.tmux.conf
Input: Run the install script's tmux configuration phase
Expected Output: Original file is moved to ~/.tmux.conf.backup.{timestamp}; symlink is created; warning message is printed

TS-TMUX-016: Deployment replaces stale symlink
Category: Integration
Priority: High
Preconditions: A symlink exists at ~/.tmux.conf pointing to an old location
Input: Run the install script's tmux configuration phase
Expected Output: Old symlink is removed; new symlink pointing to current dotfiles location is created

TS-TMUX-017: Deployment fails without tmux
Category: Integration
Priority: Medium
Preconditions: tmux binary is not installed and cannot be installed
Input: Run the install script's tmux configuration phase
Expected Output: Warning is printed; configuration phase fails gracefully; other phases continue if possible

TS-TMUX-018: Zero escape time
Category: Unit
Priority: Critical
Preconditions: Tmux session is active with the deployed configuration
Input: Press Escape key in Neovim while in tmux
Expected Output: Escape registers immediately with no perceptible delay

TS-TMUX-019: True color rendering
Category: Visual
Priority: High
Preconditions: Terminal emulator supports true color
Input: Open Neovim with a colorful colorscheme inside tmux
Expected Output: Colors render correctly without banding or approximation; true color test patterns display accurately

TS-TMUX-020: Merge panes into previous window
Category: Integration
Priority: Medium
Preconditions: Two windows exist; current window has multiple panes
Input: Press prefix + M
Expected Output: All panes from current window are joined into the previous window side by side; focus switches to previous window

TS-TMUX-021: Explode panes into separate windows
Category: Integration
Priority: Medium
Preconditions: Current window has multiple panes
Input: Press prefix + E
Expected Output: All panes except one are broken into separate adjacent windows; each new window has one pane

TS-TMUX-022: Reverse pane order
Category: Integration
Priority: Low
Preconditions: Window with 3+ panes in a known order
Input: Press prefix + R
Expected Output: Pane order is reversed (first becomes last, last becomes first)

TS-TMUX-023: Automatic rename format
Category: Unit
Priority: Medium
Preconditions: Pane is in ~/projects/myapp running vim
Input: Observe the window name in the status bar
Expected Output: Window name displays as "myapp:vim" (basename of path, colon, command name)

TS-TMUX-024: Focus events enabled
Category: Unit
Priority: High
Preconditions: Neovim is running inside tmux with autoread/autowrite
Input: Switch focus away from terminal, then switch back
Expected Output: Neovim detects the focus change and triggers autoread/autowrite events

TS-TMUX-025: Extended keys enabled
Category: Unit
Priority: Medium
Preconditions: Pi coding agent or other tool requiring modified key sequences is running in tmux
Input: Press modified key combinations (e.g., Ctrl-Shift-arrow)
Expected Output: Modified key sequences are passed through correctly to the application
```

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.1.0 | 2026-07-05 | Clarified tmux's role as a legacy fallback during Herdr migration while preserving all existing tmux behavior requirements. |
| 1.0.0 | 2026-05-01 | Initial specification extracted from existing tmux configuration and install script |

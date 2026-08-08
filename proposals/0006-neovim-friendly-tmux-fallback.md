# 0006 — Neovim-friendly tmux fallback

**Status:** Shipped

**Created:** 2026-08-08

## What shipped

The dotfiles owner retains a complete, dependable tmux environment whenever Herdr is unavailable, unsuitable for a host, or explicitly bypassed. Tmux is a migration fallback rather than the default SSH workspace, but launching it still provides the same deliberate terminal behavior used before the Herdr transition. The fallback is capable enough for sustained development rather than limited to emergency shell access.

Neovim remains responsive and visually correct inside tmux. Escape reaches modal editing without perceptible multiplexer delay, full terminal color is preserved, focus changes reach applications, and modified key combinations remain distinguishable. Mouse and clipboard integration coexist with keyboard-first operation, while activity tracking avoids disruptive visual alerts.

The owner uses Ctrl-a as the tmux prefix and Vim-style movement for panes and copy mode. New panes and windows open in the current project context instead of returning to the home directory. New windows appear next to the current work, window numbering remains predictable, and automatic names expose both location and active command. Common pane operations support splitting, resizing, merging, separating, reordering, and equalizing running work without restarting its processes.

Nested tmux sessions remain first-class. The owner can send one prefix command through to an inner session or toggle the outer session’s controls off entirely. While inner-session control is active, the outer status bar visibly dims so there is no ambiguity about which layer will receive commands. Toggling back restores outer controls and appearance. Entering the toggle from copy mode exits copy mode first, avoiding a half-switched interaction state.

Vi-style copy mode supports visual selection and sends copied text to the available system clipboard. The status bar displays enough session, user, window, time, and date context to orient the owner without dominating terminal space. Repository changes to the configuration can be reloaded into a running session, keeping the version-controlled source authoritative without requiring tmux to restart.

## Why it exists

Herdr becoming the default does not eliminate machines, nested workflows, or recovery situations where tmux remains useful. A neglected fallback would force the owner to relearn default bindings precisely when the primary workflow is unavailable. It would also reintroduce input lag, color degradation, lost working-directory context, and ambiguous nested-session control.

The owner already has strong tmux and Vim muscle memory. Preserving that environment makes migration reversible per host and lets tmux continue serving the cases Herdr deliberately does not cover. Visible nesting state prevents commands from reaching the wrong session, while project-context inheritance and pane reorganization keep long-running development work intact. One repository-owned configuration ensures fallback behavior does not drift across machines.

## Out of scope

- Restoring tmux as the default SSH multiplexer while Herdr remains the selected replacement.
- Making tmux imitate Herdr’s workspace and agent-restoration model.
- Hiding which nested session currently owns keyboard input.
- Replacing running pane processes merely to reorganize a layout.
- Maintaining independent per-machine copies of repository-owned tmux behavior.
- Guaranteeing external clipboard integration when the host lacks a supported clipboard facility.

## FAQ

**Why keep tmux fully configured when it is no longer the default?**

Tmux remains the supported fallback for hosts and nested workflows that are not ready for Herdr. Reducing it to an unconfigured emergency binary was rejected because the owner would lose familiar navigation and development guarantees precisely during fallback use.

**Revisit if:** All active hosts and workflows operate through Herdr for a sustained period without invoking tmux manually or through SSH fallback.

**Why use Ctrl-a instead of tmux’s upstream prefix?**

Ctrl-a matches the owner’s established multiplexer muscle memory and the Herdr migration convention. Returning tmux to its upstream prefix was rejected because switching between fallback and default environments would change every command sequence.

**Revisit if:** Ctrl-a conflicts with a required application or the owner adopts a different shared multiplexer convention.

**Why remove the escape delay?**

Modal editing depends on Escape taking effect immediately. Retaining tmux’s input delay was rejected because it makes routine Neovim mode changes feel sluggish and can interfere with rapid key sequences.

**Revisit if:** Tmux or terminal input handling changes so immediate Escape causes ambiguous or lost key sequences in supported applications.

**Why use Vim-style pane navigation and copy behavior?**

Shared directional and selection habits reduce context switching between Neovim and the surrounding terminal. Default tmux movement and copy bindings were rejected because they introduce a separate navigation vocabulary for the same daily workflow.

**Revisit if:** The primary editor changes or a terminal-wide navigation standard provides demonstrably better consistency.

**Why do new panes and windows inherit the current project context?**

Splitting work usually continues within the same repository or task. Opening in the home directory was rejected because every split would require redundant navigation and could start commands in the wrong location.

**Revisit if:** Daily use shows that most new panes intentionally begin outside the current working context.

**Why are new windows placed adjacent to the current one?**

A new window usually extends the current task, so spatial proximity preserves context. Always appending at the end was rejected because related work becomes separated as the session grows.

**Revisit if:** The owner adopts a stable naming or grouping workflow where global append order is more useful than locality.

**Why support explicit outer and inner session control?**

Nested tmux requires a clear way to direct prefix commands to the intended layer. Leaving both sessions active without a control boundary was rejected because commands can affect the wrong session and nested operation becomes error-prone.

**Revisit if:** Nested tmux is retired or tmux provides native unambiguous routing between session layers.

**Why dim the status bar during inner-session control?**

The active key-routing layer is otherwise invisible. No visual feedback was rejected because the owner could resize, close, or navigate the wrong session while believing the other layer was active.

**Revisit if:** Tmux exposes a clearer persistent indicator of which session owns prefix input.

**Why keep one repository-owned configuration?**

A canonical source keeps fallback behavior consistent across machines and allows live reload after edits. Copied per-machine configurations were rejected because fixes and keybinding changes would drift.

**Revisit if:** Supported hosts require materially incompatible tmux behavior that cannot be expressed conditionally without making the shared experience unreliable.

## Open questions

None

# 0003 — Herdr-first terminal workspaces

**Status:** Superseded by [0014](0014-model-native-agent-environment.md)

**Later change:** [0013](0013-execution-owned-tab-cleanup.md) changed tab cleanup before the complete Herdr workflow was retired by [0014](0014-model-native-agent-environment.md).

**Created:** 2026-08-08

## What shipped

The dotfiles owner enters a Herdr workspace by default when starting an SSH shell. Repositories, tasks, and investigations can each have a top-level workspace containing tabs and panes, giving terminal work a structure that can survive reconnects and supported agent restarts. The same Herdr behavior is available across installation profiles rather than being confined to a specialized setup.

The transition preserves the controls used most often in tmux. Ctrl-a remains the multiplexer prefix key, and daily pane and tab movement uses familiar Vim-style navigation. Herdr’s own workspace vocabulary and lifecycle are adopted instead of disguising workspaces as tmux sessions. Advanced tmux-only pane arrangements are not copied preemptively; they can be considered when real use demonstrates that a missing operation matters.

Tmux remains installed, configured, and available as a legacy fallback. An owner can select it for an SSH host that is not ready for Herdr without changing repository-owned shell configuration. Nested Herdr sessions are blocked to avoid ambiguous control and restoration behavior, while tmux remains available when a legacy nested multiplexer workflow is necessary.

Herdr can retain pane history and restore supported agent conversations, but that runtime state stays on the machine. Sessions, pane contents, sockets, logs, and generated state do not become dotfiles. The repository owns only durable configuration and the integration material intentionally distributed to supported agents.

Agent workflows use one shared Herdr operating layer for terminal transport, agent startup, prompt delivery, output inspection, and settled-state observation. Claude-specific interaction and bounded worker supervision compose that shared behavior rather than duplicating it. Integrations are deployed from repository-owned sources, keeping agent configuration reproducible and preventing an upstream installer from becoming an untracked second owner of live configuration.

## Why it exists

Before this migration, tmux was both the default SSH multiplexer and the mental model for terminal work. It provided familiar controls but did not supply Herdr’s workspace-oriented agent experience. Switching outright would have broken established key habits, removed a working fallback, and encouraged exact emulation of tmux concepts instead of learning the replacement’s native model.

The owner needs a gradual replacement path that is useful every day while remaining reversible per machine. Preserving the prefix and common navigation reduces the cost of switching, while explicit workspaces make repositories and investigations easier to resume. Keeping runtime state local also allows history and restoration without committing terminal contents or generated machine state. Repository-owned integrations ensure the same agent behavior can be reproduced through the normal dotfiles deployment flow.

## Out of scope

- Removing tmux before the migration has demonstrated that the fallback is no longer needed.
- Reproducing every advanced tmux pane-layout operation in Herdr.
- Supporting Herdr-inside-Herdr nesting.
- Tracking sessions, pane history, sockets, logs, or other generated Herdr runtime state.
- Giving a generic Herdr transport layer ownership of agent-specific interaction behavior.
- Shipping an independent liveness monitor or autonomous active-worker termination workflow. Post-completion cleanup of execution-owned tabs is governed by [0013](0013-execution-owned-tab-cleanup.md).

## FAQ

**Why does Herdr become the default while tmux remains installed?**

Herdr provides the workspace and agent-oriented experience selected for new work. Immediate tmux removal was rejected because existing hosts and nested workflows still need a dependable migration fallback. The default moves forward without making every machine cross the boundary at once.

**Revisit if:** All active hosts and daily workflows operate through Herdr for a sustained period without using the tmux fallback.

**Why is Ctrl-a retained as the Herdr prefix key?**

Ctrl-a preserves the owner’s established multiplexer muscle memory. Adopting the upstream Ctrl-b default was rejected because it adds friction to every common command without improving the Herdr workspace model.

**Revisit if:** Ctrl-a conflicts with a required application or Herdr introduces a demonstrably more effective interaction model that justifies retraining.

**Why adopt Herdr workspaces instead of emulating tmux sessions?**

A Herdr workspace is the top-level unit for a repository, task, or investigation, with tabs and panes beneath it. Exact tmux emulation was rejected because it would preserve the old mental model and obscure Herdr’s native restoration and agent behavior.

**Revisit if:** Real workflows show that workspace boundaries cannot represent the owner’s recurring organization needs.

**Why are nested Herdr launches blocked?**

Nested Herdr would make prefix handling, identity, and restoration boundaries ambiguous. Supporting it was rejected while tmux can cover the limited legacy cases that require a nested multiplexer.

**Revisit if:** Herdr provides explicit nested-session semantics with unambiguous input routing and restoration ownership.

**Why does pane history remain outside the repository?**

Pane history and session data are useful local runtime state, not durable configuration. Tracking them was rejected because they are generated, machine-specific, potentially sensitive, and continuously changing.

**Revisit if:** Herdr introduces a separate portable workspace definition that contains no pane content, credentials, machine state, or unstable identifiers.

**Why are Herdr integrations repository-owned?**

Agent integrations are captured as durable repository sources and deployed through the same ownership flow as other agent configuration. Allowing an integration installer to mutate live locations directly was rejected because it creates untracked configuration and a competing deployment authority.

**Revisit if:** Herdr offers a declarative integration interface that can be reproduced from repository-owned configuration without direct unmanaged mutation.

**Why are generic transport and agent-specific workflows separate?**

The generic Herdr layer owns reusable terminal and agent transport. Claude-specific interaction and bounded supervision compose it while retaining their own behavior. Copying transport mechanics into each workflow was rejected because commands and waiting semantics would drift.

**Revisit if:** Herdr’s supported agent interface becomes so agent-specific that no stable shared transport behavior remains.

**Why are advanced tmux operations deferred?**

The migration includes the daily controls required for practical use. Implementing complete parity was rejected because it would optimize speculative gaps and make Herdr imitate tmux before actual usage identifies what is missing.

**Revisit if:** A recurring workflow is blocked or materially slowed by a specific missing pane operation.

## Open questions

None

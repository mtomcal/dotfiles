# 0011 — Selective idempotent install

**Status:** Shipped

**Later change:** Standard profile contents are simplified by [0014](0014-model-native-agent-environment.md); the selective, idempotent module design remains.

**Created:** 2026-08-08

## What shipped

The dotfiles owner can provision or repair the complete development environment through one install entry point on supported Ubuntu/Debian and macOS machines. The install identifies the host platform, offers common environment profiles or exact module selection, resolves missing prerequisites, presents the resulting scope, and runs the selected capabilities in dependency order.

Full, Minimal, and Work profiles provide repeatable starting points for common host roles, while Custom selection supports one-off and machine-specific combinations. The same module model works through an interactive menu or command-line selection, so a person can review a guided install and automation can request a deterministic subset. Standard profiles omit platform-inapplicable capabilities; explicitly requesting an unsupported capability produces a visible failure rather than silently installing a substitute.

Install is safe to rerun. Existing satisfactory tools remain in place or follow their supported update path, managed configuration converges on its repository source, and conflicting unmanaged files are preserved according to the deployment policy. Mutable application settings, credentials, sessions, service secrets, and other local state retain their ownership across repairs and upgrades.

Each module owns the depth of its installation and configuration behavior. The orchestrator owns selection, platform gates, prerequisite expansion, ordering, confirmation, execution, and reporting rather than duplicating every tool’s mechanics. Prerequisites are added only when the current machine lacks them, and duplicate prerequisites collapse into one ordered operation.

A failed module is recorded without preventing independent later modules from running. The completion report distinguishes successful and failed capabilities, returns an overall failure when necessary, and identifies manual follow-up such as restarting a shell, authenticating a tool, or changing an unsupported editor setting. Herdr appears in every standard environment while tmux remains the migration fallback. Beads tooling appears in development-oriented profiles, but normal install never creates, synchronizes, migrates, or deletes private command-repo state.

## Why it exists

A dotfiles environment spans package managers, upstream installers, language runtimes, editors, terminal tools, coding agents, services, and repository-managed configuration. Running those setup steps manually makes their ordering implicit, causes machines to drift, and turns repair into a memory exercise. One monolithic all-or-nothing script would create a different problem by forcing every host into the same role and making an unrelated failure block useful progress.

The owner needs one understandable front door with deep modules behind it. Profiles make frequent choices cheap, exact selection supports partial hosts, and environment-aware dependency resolution avoids replacing tools that already satisfy prerequisites. Confirmation makes interactive scope visible before mutation, while failure aggregation produces a useful partially completed environment and a precise rerun target. Keeping stateful bootstrap and destructive cleanup outside normal installation ensures that a routine setup or repair cannot unexpectedly alter operational data.

## Out of scope

- Supporting operating systems other than Ubuntu/Debian and macOS through best-effort guesses.
- Implementing every tool’s internal provisioning behavior in the orchestrator.
- Silently substituting a different application when an explicitly selected module is unsupported.
- Enabling code-server through a standard profile without explicit host-level selection.
- Creating, synchronizing, migrating, or deleting a private command repo during normal install.
- Treating a partial success as complete success when one or more selected modules failed.
- Collecting or managing Git identity without an explicitly implemented user workflow.

## FAQ

**Why is there one top-level install entry point?**

One entry point gives setup, upgrades, and repair the same platform detection, selection, ordering, and reporting behavior. Separate installers per tool or subsystem were rejected because their dependency and ownership assumptions would drift and users would need to remember execution order.

**Revisit if:** A platform-native package or configuration manager can provide the same cross-platform module selection and repository ownership guarantees without duplicating orchestration.

**Why explicitly support only Ubuntu/Debian and macOS?**

These are the owner’s actual host families and have complete package, service, architecture, and recovery behavior. Best-effort execution elsewhere was rejected because an apparently successful install could leave unsupported substitutions or partially configured tools.

**Revisit if:** The owner adopts another operating-system family and its full module behavior is implemented and exercised.

**Why offer both profiles and exact module selection?**

Profiles make recurring host roles concise, while exact selection handles partial installs, repair, and unique machines. Profiles alone were rejected because they force unnecessary tools; modules alone were rejected because common environments would require long repeated selections.

**Revisit if:** Host roles stabilize around a different selection mechanism that remains equally useful for partial repair.

**Why are standard profiles platform-aware while explicit unsupported selections fail?**

A standard profile expresses user intent at the environment level and should choose the applicable platform implementation. An explicit module request is a direct request for that capability and should not be silently ignored or replaced. Always skipping was rejected because automation could report success without delivering the requested result.

**Revisit if:** Every cross-platform capability gains a clearly equivalent implementation under one module identity.

**Why resolve prerequisites from the current machine?**

An already available prerequisite does not need its installer added again. A fixed dependency chain was rejected because it performs redundant work and may replace a valid owner-managed installation. Modules still verify their own assumptions before acting.

**Revisit if:** Command presence proves too weak and a richer compatibility check requires uniform prerequisite management.

**Why present resolved scope before an interactive install?**

Dependency expansion can add work the user did not select directly. Immediate execution was rejected because the final mutation scope would be hidden. Confirmation lets the owner review platform choices and prerequisites before changes begin.

**Revisit if:** The install runs in an explicitly noninteractive context whose supplied selection already authorizes the resolved dependency closure.

**Why do modules run sequentially in dependency order?**

Many capabilities depend on tools or configuration established earlier. Unbounded parallel execution was rejected because package managers, mutable configuration, and shared installation state can conflict or expose incomplete prerequisites.

**Revisit if:** Independent module groups can be proven free of shared writers and dependency races, and parallel execution materially improves installation time.

**Why continue after an individual module fails?**

Independent modules can still produce a useful environment and useful diagnostic evidence. Halting on every failure was rejected because one optional download or service would block unrelated shell, editor, or agent setup. The overall result remains failed so partial completion is never hidden.

**Revisit if:** A failed module invalidates the safety or correctness of every remaining selected module and cannot be represented through dependencies.

**Why does each module retain its own installation logic?**

The orchestrator should provide a small interface—selection, ordering, invocation, and result—while each module owns the complexity of its tool. Centralizing all mechanics was rejected because the top level would couple every subsystem and become difficult to test or change independently.

**Revisit if:** Repeated module behavior reveals a deeper shared service that can centralize mechanics without exposing tool-specific complexity to the orchestrator.

**Why is code-server explicit only?**

Selecting code-server installs and enables a persistent authenticated network service. Including it automatically in a Linux profile was rejected because network reachability and service lifecycle require a deliberate host decision.

**Revisit if:** The service no longer creates a persistent listener or every relevant Linux host intentionally adopts the browser-editor role.

**Why are Herdr and tmux both present in standard environments?**

Herdr is the default terminal workspace, while tmux remains the migration and nesting fallback. Removing tmux immediately was rejected because active hosts and legacy workflows may still require it.

**Revisit if:** All active hosts and workflows operate through Herdr for a sustained period without using tmux.

**Why are Beads installation and command-repo lifecycle separate?**

Installing the tool is repeatable environment provisioning. Choosing, synchronizing, migrating, or deleting a private command repo changes operational state and requires separate authority. Combining them was rejected because routine setup could unexpectedly mutate or destroy durable coordination data.

**Revisit if:** Beads provides a transactionally safe lifecycle operation whose stateful effects remain explicit and separately authorized during install.

## Open questions

None

# 0005 — Additive Zsh environment

**Status:** Shipped

**Later change:** Herdr selection and Beads routing are superseded by the tmux-only shell behavior in [0014](0014-model-native-agent-environment.md).

**Created:** 2026-08-08

## What shipped

The dotfiles owner gets the same productive Zsh environment on supported Linux and macOS machines while retaining a clean, independently updateable Oh My Zsh installation. Install makes Zsh the primary interactive shell, prepares the framework, and adds the repository’s custom shell configuration to the existing startup flow. Repeated install does not duplicate that integration or replace unrelated shell setup.

Every new shell applies the owner’s stable preferences after framework initialization. Neovim is the default editor for tools that honor editor settings, and familiar Vim command names continue to open it. Short aliases provide consistent access to terminal applications, coding agents, Herdr, and the tmux fallback. Herdr and tmux retain separate command families so the migration does not silently change the meaning of established tmux shortcuts.

Command discovery favors durable user-owned tools over system packages and globals tied to the currently selected Node runtime. Go tools and runtime managers become available in the correct platform context without hardcoding a macOS package-manager location. Changing directories can select the project’s requested Node version, while the user-owned coding-agent commands remain discoverable afterward.

Optional integrations do not make a partially provisioned machine noisy or unusable. Node version management and smart directory navigation initialize when installed and remain silent when absent. Typing a directory name as though it were a command reports an error instead of changing location implicitly, making command mistakes visible.

Eligible SSH sessions enter Herdr by default, can choose tmux as a per-machine fallback, or can disable automatic multiplexer entry. Local shells and shells already inside either multiplexer are left alone. When explicit Beads bootstrap state is valid, every shell routes ordinary coordination commands to the private external command repo. Missing or stale bootstrap state does not break shell startup or create coordination state in a source repository.

## Why it exists

A useful development shell combines framework behavior, personal commands, language runtimes, and machine-local integration. Keeping all of that in one framework-owned startup file makes updates and reinstalls risky, while copying fragments by hand causes machines to drift. Runtime managers can also reorder command discovery so coding-agent commands disappear after changing Node versions.

The owner needs one shell layer that remains authoritative for personal behavior without taking ownership of the entire Zsh installation. Loading custom behavior after Oh My Zsh protects both sides of that boundary. Conditional integration supports machines with different selected modules, explicit SSH rules prevent accidental nested multiplexers, and machine-local command-repo routing connects durable coordination without storing host-specific locations in the repository.

## Out of scope

- Replacing the owner’s complete shell startup file or taking ownership of unrelated local customization.
- Repointing established tmux shortcuts to Herdr during migration.
- Installing optional tools merely because a shell starts.
- Hiding missing commands through implicit directory changes.
- Hardcoding package-manager-specific runtime locations where the platform can resolve them.
- Tracking machine-local command-repo locations in dotfiles.
- Blocking ordinary shell use when command-repo bootstrap state is absent or invalid.

## FAQ

**Why use Zsh with Oh My Zsh as the interactive shell base?**

Zsh supplies the interactive behavior the owner prefers, while Oh My Zsh provides maintained completion, plugins, and framework conventions. A custom shell built entirely from repository code was rejected because it would duplicate framework maintenance without improving the owner’s core workflow.

**Revisit if:** The framework becomes unmaintained, materially slows shell startup, or prevents required shell behavior from remaining repository-owned.

**Why is custom configuration added to the existing startup flow instead of replacing it?**

The repository extends the owner’s shell after the base framework loads. Replacing the complete startup file was rejected because it would take ownership of framework-generated and machine-local configuration. Additive loading allows both layers to update independently.

**Revisit if:** The repository intentionally becomes authoritative for the complete Zsh startup lifecycle and can preserve all required local variation.

**Why does repository customization load after Oh My Zsh?**

Loading last ensures the owner’s editor choice, aliases, command priority, and options are not overwritten by framework initialization. Loading before the framework was rejected because final behavior could vary with framework updates.

**Revisit if:** Oh My Zsh provides a stable supported extension phase that guarantees equivalent precedence without end-of-file sourcing.

**Why do user-owned commands take priority over runtime-managed globals?**

Coding-agent commands installed for the user must survive and remain discoverable across Node version changes. Letting the active Node runtime take precedence was rejected because changing projects could unexpectedly select a different or missing global command.

**Revisit if:** The Node version manager provides one stable shared global-command layer with equivalent isolation and update behavior.

**Why do Herdr and tmux keep separate shortcuts?**

Herdr is the default for new SSH work, while tmux remains a migration fallback. Reusing tmux shortcuts for Herdr was rejected because familiar commands would silently change meaning and make fallback operation harder.

**Revisit if:** Tmux is fully retired and the owner explicitly chooses to reassign its shortcut namespace.

**Why is implicit directory changing disabled?**

A mistyped or unavailable command should fail visibly. Automatically treating a matching directory name as navigation was rejected because it can hide command mistakes and unexpectedly change shell state.

**Revisit if:** The owner explicitly prefers implicit navigation after evaluating its command-error risk in daily use.

**Why are optional integrations silent when unavailable?**

Machines can legitimately install only a subset of modules. Emitting startup errors for absent optional tools was rejected because every shell would become noisy before provisioning or on intentionally minimal hosts.

**Revisit if:** An optional tool becomes mandatory for every supported installation profile.

**Why is multiplexer auto-entry limited to eligible SSH sessions?**

Remote sessions benefit from persistence, but local shells and already-multiplexed sessions should not be wrapped again. Universal auto-entry was rejected because it creates accidental nesting and changes ordinary local terminal behavior.

**Revisit if:** Herdr provides a supported universal shell-entry mechanism that safely detects and preserves every local, remote, and nested context.

**Why is command-repo routing loaded from local bootstrap state?**

Each host may use a different checkout location for the same private command repo. Tracking that location was rejected because it is machine-specific, while silently creating source-local coordination state was rejected because it fragments durable authority.

**Revisit if:** Beads gains location-independent private command-repo discovery that requires no machine-local routing state.

## Open questions

None

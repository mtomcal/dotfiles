# 0001 — Safe dotfiles deployment

**Status:** Shipped

**Created:** 2026-08-08

## What shipped

The dotfiles owner can apply the repository’s configuration to a new or existing Linux or macOS environment without manually moving each application’s files into place. Repository-owned configuration remains canonical, while applications find it in their expected system locations. Editing a managed source takes effect without maintaining a second copy.

Deployment is safe to repeat. A second install converges on the same managed state instead of creating duplicate configuration, repeatedly rewriting correct links, or producing new backups for already-managed targets. When an unmanaged file or directory occupies a managed location, install preserves it as a timestamped backup before deploying the repository-owned configuration. Existing links can be corrected to the canonical source without treating the link itself as user data.

The deployment boundary follows ownership rather than assuming every application file belongs in version control. Mutable settings, generated credentials, runtime history, session state, certificates, and machine-specific values remain local. Optional repository sources can be absent without breaking unrelated configuration. Parent locations are prepared as needed, and supported platform differences are handled by the owning install module.

Some tools require a narrower integration. The custom shell configuration is added to the user’s existing shell setup instead of replacing it. Codex receives a local configuration copy because the tool writes machine- and project-specific values. Visual Studio Code targets share the repository-owned settings, keybindings, and snippets while retaining their broader mutable user state. Supported agents expose one canonical shared skill catalog, with Pi retaining its tracked visibility layer for agent-specific composition.

## Why it exists

Before this deployment behavior, adopting the repository on an existing machine risked a choice between manual reconciliation and destructive replacement. Configuration could drift between the repository and live application locations, while rerunning setup could overwrite local work or require repeated cleanup. Application-owned state could also leak into version control when an entire configuration area was treated as repository-owned.

The owner needs install to be both the initial setup path and the routine repair path. Safe backups protect pre-existing work, idempotency makes repeated use ordinary, and explicit ownership boundaries keep generated or private state local. Together these properties let the repository remain authoritative without pretending that every file an application touches is durable dotfiles configuration.

## Out of scope

- Capturing arbitrary local application state into the repository; capture and deployment have different ownership and safety requirements.
- Managing credentials, certificates, runtime history, sessions, or machine-specific application state.
- Replacing complete mutable editor user directories when only stable configuration surfaces are repository-owned.
- Centralizing every deployment operation into one subsystem; owning install modules may retain their own implementation while providing the same user guarantees.

## FAQ

**Why does managed configuration remain in the repository instead of being copied into each application location?**

Repository-owned configuration is canonical and deployed through symbolic links. Independent copies were rejected because edits could diverge and require synchronization. Local copies remain appropriate only where an application writes machine- or project-specific values.

**Revisit if:** A supported application cannot reliably consume symbolic links or begins mutating a repository-owned file with local-only values.

**Why are unmanaged files backed up instead of overwritten or blocking install?**

Install preserves an existing non-link file or directory before replacing it. Silent overwrite was rejected because it loses user data; refusing all conflicts was rejected because it prevents install from serving as an unattended setup and repair path.

**Revisit if:** Deployment gains an equally automatic conflict mechanism that proves user content remains recoverable without timestamped backups.

**Why is Codex configuration a local copy?**

Codex configuration remains local because Codex writes machine- and project-specific values. A repository link was rejected because those writes could leak local state into version control. Existing local configuration is preserved by default, while explicit replacement remains possible.

**Revisit if:** Codex separates immutable shared configuration from all machine- and project-specific state through a supported configuration interface.

**Why is the existing shell configuration extended rather than replaced?**

The managed custom shell configuration is conditionally sourced from the user’s existing shell setup. Replacing the complete shell file was rejected because it would take ownership of unrelated user configuration. Repeated install does not add the source instruction more than once.

**Revisit if:** The repository deliberately becomes authoritative for the user’s complete shell startup configuration.

**Why are only selected Visual Studio Code surfaces managed?**

Settings, keybindings, and snippets form the managed layer. Managing the complete user directory was rejected because it also contains mutable history, profiles, synchronization data, workspace state, and other application-owned material. Local code-server credentials and certificate state remain outside deployment ownership.

**Revisit if:** Supported editor targets provide a stable, documented configuration root containing only repository-safe state.

**Why does Pi retain a visibility layer for shared skills?**

Claude, Codex, and Copilot can expose the canonical shared catalog directly, while Pi uses a tracked visibility layer whose entries select shared skills. Direct Pi exposure was rejected because it would remove Pi-specific composition control.

**Revisit if:** Pi no longer needs agent-specific catalog composition or supports that composition without a tracked visibility layer.

## Open questions

None

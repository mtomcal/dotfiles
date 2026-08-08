# 0008 — Two-target VS Code managed layer

**Status:** Shipped

**Created:** 2026-08-08

## What shipped

The dotfiles owner gets one repository-authoritative Visual Studio Code experience across two deliberate targets: official Visual Studio Code Desktop on macOS and code-server on Ubuntu/Debian. Shared settings, keybindings, snippets, and extension requirements provide familiar editing behavior on either target, while target-specific extension catalogs absorb marketplace, licensing, and runtime differences.

The managed layer owns only stable editor configuration. Accounts, authentication, UI history, workspace state, named profiles, extension state, certificates, service credentials, and machine-specific network values remain local. Editing a managed setting through either editor updates the repository-owned source, making changes visible for review instead of creating an unnoticed second configuration copy.

Desktop Visual Studio Code participates in the normal macOS development environment and retains Microsoft Marketplace and Remote SSH compatibility. code-server is available only through explicit Ubuntu/Debian selection because it installs and enables a persistent browser-accessible service. The service uses password authentication and encrypted transport, preserves its local bind and generated security state across reruns, and leaves firewall and trusted-network reachability under operator control.

The shared editor experience supports project conventions, Python, JavaScript and TypeScript, Markdown, TOML, Mermaid diagrams, GitHub workflows, Vim-style editing, formatting, diagnostics, testing, and debugging. Opinionated web formatters and linters activate only when the project has selected them. Desktop and browser targets can choose different Python intelligence extensions where their marketplaces require it without splitting the shared settings layer.

Extension reconciliation ensures required capabilities are present or updated but does not remove unlisted experiments. Existing desktop configuration can be imported through a separate explicit capture operation. Capture never runs during install, never silently overwrites repository sources, and initially treats discovered extensions as desktop-specific until the owner deliberately promotes them. Missing language runtimes produce guidance without making editor configuration fail.

## Why it exists

The owner works from a native macOS desktop and from browser-accessible Linux hosts. Maintaining independent editor configurations causes keybindings, snippets, language behavior, and extension expectations to drift. Treating the complete editor user area as dotfiles creates the opposite problem by capturing credentials, history, profiles, and machine-specific state that should never be shared.

A narrow managed layer provides portability without claiming ownership of the whole application. Target-specific catalogs acknowledge that Microsoft Marketplace and Open VSX do not provide identical extensions. Explicit code-server selection makes enabling a network service an intentional act, while local security-state preservation keeps routine updates from rotating credentials or changing reachability. Separating capture from deployment also prevents a normal install from writing unreviewed local state back into the repository.

## Out of scope

- Managing Visual Studio Code Desktop on Linux, code-server on macOS, Windows, Codespaces, or Remote Tunnels.
- Managing named profiles, accounts, authentication, history, workspace storage, UI layout, or extension global state.
- Making cloud Settings Sync authoritative for repository-owned configuration.
- Removing extensions that are absent from the managed catalogs.
- Installing project dependencies or globally selecting one JavaScript test framework.
- Configuring firewalls, discovering private-network products, or choosing which networks may reach code-server.
- Replacing VSCodeVim with an embedded Neovim runtime.

## FAQ

**Why does one managed layer serve two editor targets?**

The owner expects the same core editing behavior on desktop and browser hosts. Independent configurations were rejected because settings, keybindings, snippets, and extension intent would drift. Target-specific catalogs retain the necessary marketplace differences without duplicating the shared experience.

**Revisit if:** The two targets require incompatible settings or interaction models that cannot remain understandable in one shared layer.

**Why is official Visual Studio Code Desktop limited to macOS?**

The desktop role exists for the owner’s macOS workflow and preserves Microsoft Marketplace and Remote SSH compatibility. Installing a substitute distribution or adding an unmanaged Linux desktop role was rejected because neither reproduces the selected environment.

**Revisit if:** The owner adopts a supported Linux desktop workflow with a deliberate distribution and marketplace contract.

**Why is code-server explicitly selected rather than included by default?**

code-server creates a persistent authenticated network service. Enabling it through every Linux profile was rejected because network exposure requires an intentional host-level decision even when authentication and encryption are configured.

**Revisit if:** code-server stops providing a persistent listener or every supported Linux host deliberately adopts the browser-editor role.

**Why are only selected editor surfaces repository-owned?**

Settings, keybindings, snippets, and extension requirements are stable and portable. The complete user area also contains mutable and potentially sensitive state. Managing it wholesale was rejected because history, credentials, profiles, and machine values would leak or conflict across hosts.

**Revisit if:** The editors provide a documented portable configuration root that excludes all mutable and secret state.

**Why is Settings Sync disabled manually?**

Cloud synchronization would create a second authority capable of writing repository-managed files. Patching internal databases or the signed application to enforce disablement was rejected because no supported persistent interface exists and unsupported mutation would be fragile.

**Revisit if:** Visual Studio Code exposes a supported enforceable policy that disables Settings Sync for the managed profile.

**Why are extension catalogs required-presence lists rather than exact inventories?**

Managed capabilities must remain installed, while the owner can experiment with additional extensions. Pruning unlisted extensions was rejected because it turns ordinary reconciliation into destructive state enforcement.

**Revisit if:** A dedicated locked-down editor role requires an exact audited extension inventory.

**Why are capture and deployment separate operations?**

Capture writes selected local configuration into repository sources; deployment writes reviewed sources to editor targets. Combining them was rejected because a routine install could import credentials, machine-specific values, or unreviewed extensions.

**Revisit if:** The editor provides a safe declarative export containing only managed surfaces with reliable secret and machine-state exclusion.

**Why must projects opt into Prettier and ESLint behavior?**

Project configuration demonstrates that the repository selected those tools. Applying them globally was rejected because saving a file could introduce broad style changes or competing formatter behavior in projects that use different conventions.

**Revisit if:** The owner adopts an explicit cross-project default that governs repositories without local configuration.

**Why use VSCodeVim instead of embedded Neovim?**

VSCodeVim provides portable modal editing while allowing both targets to share native editor settings and extension behavior. Embedding Neovim was rejected because it would couple this layer to the separate Lua custom layer and create another runtime dependency.

**Revisit if:** VSCodeVim can no longer provide the required editing behavior and embedded Neovim becomes equally portable across both targets.

**Why does code-server preserve local bind and security state?**

Bind choice, password, and certificate material belong to the host. Replacing them during routine updates was rejected because it can break access, expose a different interface, or rotate credentials unexpectedly.

**Revisit if:** code-server supplies an external secret and listener-management interface that safely separates durable host policy from generated service configuration.

**Why are private-network products absent from tracked configuration?**

The repository defines a generic authenticated and encrypted endpoint while the operator controls trusted reachability. Naming a particular network product, host, or private address was rejected because it leaks machine infrastructure and makes portable configuration depend on one transport.

**Revisit if:** The repository intentionally adopts and can publicly document one managed network product as part of its durable scope.

## Open questions

None

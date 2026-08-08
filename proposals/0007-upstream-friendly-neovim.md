# 0007 — Upstream-friendly Neovim

**Status:** Shipped

**Created:** 2026-08-08

## What shipped

The dotfiles owner gets a full Neovim development environment without maintaining a private fork of the editor’s starter configuration. Official kickstart supplies the independently updateable base for plugin management, language-server integration, and common editor behavior. A repository-owned custom layer adds the owner’s language workflows, formatting, linting, testing, debugging, Git tools, file navigation, and visual refinements through kickstart’s supported extension seam.

Updating kickstart does not erase personal behavior, and changing the custom layer does not dirty the upstream checkout. Install reconnects the layers when needed, refreshes plugins and editor-managed tools, and preserves useful package data during routine updates. Existing unrelated editor configuration is protected before the managed environment takes ownership.

Specialized capabilities load when their filetype, command, or interaction makes them relevant. Git review tools appear for review work, Markdown rendering appears for Markdown, and Go debugging and testing appear for Go development. This keeps ordinary startup focused while still making deeper workflows available through consistent leader-key commands.

Files format automatically on save where the project has selected an applicable formatter. Opinionated JavaScript and TypeScript tools activate only when the project carries their configuration, preventing the personal editor from imposing a style on an unrelated repository. When no dedicated formatter applies, an available language server can provide formatting. Manual formatting remains available when the owner wants explicit control.

Python development includes language intelligence, environment-aware linting, and quiet recovery when optional lint tooling is unavailable. Go development includes language intelligence, import management, formatting, race-aware uncached tests, and debugger integration. Git status, diffs, file history, commits, pulls, and pushes can be inspected without leaving Neovim. The file explorer reveals dotfiles and ignored files for environment-aware work, and its essential symbols remain legible over SSH without requiring a patched font.

## Why it exists

A complete hand-maintained Neovim configuration duplicates the maintenance already performed by kickstart and makes upstream improvements expensive to adopt. Editing kickstart directly creates the opposite problem: every update risks merge conflicts or silently losing personal behavior. Eagerly loading every specialized plugin also makes the editor pay for workflows that may not be used in a session.

The owner needs a stable editor foundation that can advance independently from personal workflow. A separate custom layer creates that ownership boundary. Project-aware formatting respects repository decisions, language-specific tooling reduces context switching, and in-editor Git review supports the owner’s primary coding workflow. Preserving package data while repairing disposable cache state makes repeated installation a practical recovery tool rather than a destructive reset.

## Out of scope

- Forking kickstart or patching its internals to carry personal editor behavior.
- Applying JavaScript or TypeScript formatting when a project has not selected the relevant tool.
- Requiring Nerd Fonts for essential navigation or Git status information.
- Loading every specialized plugin during ordinary startup.
- Replacing project-owned dependency management with global editor packages.
- Guaranteeing optional linting, formatting, parser, or plugin refreshes during a transient package-service failure.

## FAQ

**Why build on kickstart instead of owning the complete Neovim configuration?**

Kickstart provides a maintained base for common editor concerns, while the repository owns only differentiated workflow. A full private configuration was rejected because it duplicates upstream maintenance; direct kickstart edits were rejected because they make updates conflict with personal behavior.

**Revisit if:** Kickstart stops exposing a stable extension seam or diverges materially from the owner’s required editor model.

**Why is all customization kept in one separate layer?**

One custom layer gives personal behavior a clear repository-owned boundary and lets kickstart update independently. Scattering edits through the upstream checkout or linking plugins individually was rejected because ownership becomes hard to inspect and updates become fragile.

**Revisit if:** Kickstart introduces a supported modular extension model that provides stronger isolation without distributing ownership across upstream files.

**Why are specialized plugins loaded on demand?**

Most sessions do not need every debugger, renderer, test adapter, and Git interface. Eager loading was rejected because it increases startup work and couples unrelated workflows. Features become available when an action or file type demonstrates the need.

**Revisit if:** Measured loading complexity or interaction latency outweighs the startup benefit for a particular capability.

**Why does formatting fall back to the language server?**

A dedicated formatter is preferred when configured, but language-server formatting provides useful coverage for other file types. Doing nothing was rejected because common files would lose consistent save behavior; forcing one global formatter was rejected because language ecosystems differ.

**Revisit if:** Language-server formatting proves nondeterministic or conflicts with project-owned formatters in supported workflows.

**Why do opinionated web formatters require project configuration?**

A repository’s formatter configuration is evidence that the project has selected that style tool. Applying it without that evidence was rejected because merely opening and saving a file could create broad unsolicited changes.

**Revisit if:** The owner adopts a repository-wide default formatting policy that explicitly governs projects without local configuration.

**Why are Python lint failures non-intrusive?**

Linting is useful feedback but an unavailable optional linter should not interrupt editing with repeated notifications. Intrusive failure reporting was rejected because transient environment issues can make every buffer event noisy. Manual recovery remains available.

**Revisit if:** Silent degradation causes recurring missed defects and the editor can surface one actionable notification without repeated disruption.

**Why use race-aware, uncached Go tests?**

Go tests should expose concurrency defects and execute current behavior rather than reuse stale results. Faster cached runs without race detection were rejected for the integrated test workflow because they provide weaker evidence during development.

**Revisit if:** Project size makes this default prohibitively slow and an equally reliable staged test policy is adopted.

**Why keep Git review and commit workflows inside Neovim?**

Diffs, history, status, and commit operations are tightly coupled to the code under review. Requiring a context switch for every operation was rejected because it breaks the owner’s primary editor-centered workflow, while external Git tools remain available for broader tasks.

**Revisit if:** In-editor Git tooling becomes unreliable or an external interface provides materially better review flow without navigation cost.

**Why are dotfiles and ignored files visible in the explorer?**

Configuration and generated environment files are often relevant in this repository and during debugging. Hiding them by default was rejected because it conceals important project context and makes a dotfiles repository awkward to navigate.

**Revisit if:** Visibility creates persistent noise in ordinary non-dotfiles projects and a reliable context-sensitive default becomes available.

**Why avoid requiring Nerd Fonts?**

The editor must remain legible over SSH and on minimally provisioned terminals. Font-specific essential symbols were rejected because missing glyphs can make navigation and Git state unreadable.

**Revisit if:** Every supported terminal environment guarantees the same patched-font coverage.

**Why preserve editor package data while repairing caches?**

Installed language tools are useful durable local data, while caches and dirty plugin checkouts are replaceable. Clearing everything on every update was rejected because it causes unnecessary downloads and destroys working package state.

**Revisit if:** Preserved package data repeatedly causes incompatibility that cannot be detected and repaired selectively.

## Open questions

None

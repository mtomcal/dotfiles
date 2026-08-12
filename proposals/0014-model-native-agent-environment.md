# 0014 — Model-native agent environment

**Status:** Accepted

**Created:** 2026-08-12

## Decision

The dotfiles use tmux as the sole supported terminal multiplexer. Eligible SSH shells run `tmux new-session -A -s main` unless `DOTFILES_TMUX_AUTO_ATTACH=0`; local shells and shells already inside tmux do not attach again. The existing Neovim-friendly tmux configuration remains authoritative.

Beads and Herdr are removed without replacement. The installer no longer provisions their binaries, configuration, integrations, routing, bootstrap lifecycle, or workflow support. Agent work uses ordinary human-readable repository artifacts when durable state is useful, but the dotfiles define no orchestration framework or mandatory task schema.

Pi and its profile, extension, wrapper, model, session, and authentication surfaces are retired. The Codex and Pi Docker sandbox wrappers, images, and shared base-image definition are also retired. Codex, Claude Code, and GitHub Copilot CLI remain the supported coding-agent harnesses.

Skills are exceptional rather than foundational. The repository begins with empty `skills/claude`, `skills/codex`, and `skills/copilot` catalogs, each exposed only to its matching harness. A skill is added only when model weights do not contain required material or a repeatable tool contract needs durable instructions. Content and style may differ between harnesses; no shared canonical skill source or cross-harness compatibility requirement remains. Legacy specialized test-quality agents are removed for the same reason.

Historical proposals remain intact as records of what previously shipped. Their status or later-change notes point here instead of rewriting the decisions in place. Local deprovisioning is a one-time cleanup, not a permanent uninstall feature in the repository, and remote Beads data is not deleted.

## Why

The retired coordination stack imposed concepts, storage, synchronization, hooks, and recovery rules that outweighed their value in the owner’s current workflow. Beads state was also harder for a person to inspect and edit than Markdown. Current model generations can perform most formerly skill-encoded work directly, making a large shared catalog another maintenance and context burden.

Tmux already provides the preferred interaction model and a mature repository-owned configuration. Returning it to the default removes a second multiplexer and its agent-state integrations. Per-harness skill roots acknowledge that different models need different information and instruction styles without requiring every useful exception to become a universal abstraction.

## Out of scope

- Migrating Beads records into a replacement task system.
- Preserving local Beads, Herdr, Pi, or sandbox runtime state after the authorized cleanup.
- Deleting the remote Beads repository or its remote data.
- Adding an uninstall command for other machines.
- Replacing native harness capabilities with speculative skills.

## Consequences

There is no durable orchestration database, automatic dependency graph, Herdr session reporting, Pi provider surface, or repository-managed agent sandbox. Work that needs durable explanation should leave concise, human-readable artifacts in the relevant repository. Skills may be duplicated or diverge across harnesses when that is genuinely useful, and the owner accepts that tradeoff in exchange for lower baseline complexity.

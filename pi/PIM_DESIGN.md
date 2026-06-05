# Pi Profile Lifecycle

This note explains the design intent behind `pim` and Pi profile deployment.

Read it before changing:

- `pi/lib/pim.sh`
- `pi/pim.sh`
- `install.sh` Pi profile deployment
- `pi/profiles/*`
- Pi profile sections in `specs/`

## Mental Model

Pi profile plumbing has four distinct layers:

| Layer | Location | Purpose |
|------|----------|---------|
| Profile source | `pi/profiles/<profile>/` | Authoring inputs: overrides, local skills, and `extensions.list` |
| Resolved output | `pi/profiles/<profile>/resolved/` | Committed deployable artifact built from base inputs plus profile overrides |
| Profile runtime | `~/.pi/profiles/<profile>/agent/` | Deployed runtime tree used by the Pi binary |
| Compatibility path | `~/.pi/agent` | Stable pointer to the active profile runtime for bare `pi` and `pis` |

These layers are intentionally separate. A profile directory is not the runtime directory, and the compatibility path is not a source of truth by itself.

## Why Resolved Output Exists

Resolved output is committed because deployment and authoring are decoupled on purpose:

- installation can deploy known-good profile artifacts without rebuilding them
- resolved changes are reviewable in Git
- profile composition is explicit instead of being reconstructed at install time
- runtime deployment stays a symlink operation instead of a second build system

`pim build <profile>` exists to refresh this artifact without changing the active profile.

## Why Runtime Exists Separately

Runtime state lives under `~/.pi/profiles/<profile>/agent/` because Pi writes and reads from a stable on-disk agent directory while profiles need isolated state.

The runtime layer:

- keeps per-profile sessions separate
- shares auth through `~/.pi/auth.json`
- lets multiple profiles coexist without mutating each other
- allows active-profile switching by swapping one symlink instead of rewriting files

## Command Intent

| Command | Intent |
|--------|--------|
| `pim create <profile>` | Scaffold source inputs only |
| `pim build <profile>` | Source -> resolved output only |
| `pim activate <profile>` / `pim use <profile>` / bare `pim <profile>` | Build, deploy, then switch the active compatibility path |
| `install.sh` Pi deploy | Deploy committed resolved outputs for all profiles without rebuilding them |

The design goal is predictable separation:

- build changes artifacts
- deploy changes runtime symlinks
- activate changes active state after build and deploy succeed

## Invariants

- `shared/skills/` is the canonical cross-agent skill catalog. If a workflow matters across harnesses, it belongs there.
- `pi/skills/` is a Pi visibility layer, not the canonical home for shared workflows.
- Duplicate names between shared skills and profile-local skills are build errors.
- The active profile must remain unchanged if build or deploy fails.
- A profile with an empty enabled extension set may have no committed `resolved/extensions/` directory because Git cannot represent empty directories. Deploy logic must treat a missing directory as an empty set, not as corruption.

## Common Misreads

- "resolved output" is not mutable runtime state.
- "profile source" is not what Pi executes directly.
- "active profile" is a pointer choice, not a rebuild.
- `pi/skills/update-specs` should not own the workflow if the same workflow is useful to Codex, Claude, or Gemini in this repo.

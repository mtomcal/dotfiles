# Pi Profile Management Implementation Plan
## Profile-first Pi config with shared binary

**Based on spec commit:** `57d1227` - `Spec Pi profile management`

> **Status:** Spec-driven plan. The source of truth is the committed spec delta for Pi profiles, active profile switching, shared skills inclusion, duplicate skill errors, `pim`, and profile-aware `pi`/`pis` wrappers.

## Overview

Implement a Pi profile manager for this dotfiles repo. The installed Pi binary remains shared across profiles, while each profile gets separate resolved config, agents, extensions, skills, sessions, and history. `pim` owns profile creation, build, inspection, validation, and active profile switching. Bare `pi` and `pis` run the active profile through `~/.pi/agent`; explicit wrappers such as `pi-coding` and `pis-local` target one profile directly.

## Spec Delta To Implement

1. Pi supports multiple profile-specific agent config variants under `pi/profiles/<profile>/`.
2. Every profile includes `shared/skills/`; profile-local skill names that duplicate shared skill names are build errors.
3. Profile output is committed under `pi/profiles/<profile>/resolved/`.
4. Runtime profile directories deploy to `~/.pi/profiles/<profile>/agent/`.
5. `~/.pi/agent` is the active profile compatibility symlink.
6. `~/.pi/active-profile` stores the active profile name.
7. `pim` supports at least `list`, `current`, `use <profile>`, `path <profile>`, `doctor`, `create <profile>`, and `build [profile]`.
8. `pim create <profile>` scaffolds authoring inputs and generates resolved output immediately.
9. Bare `pi` and `pis` use the active profile; `pi-<profile>` and `pis-<profile>` target the named profile without changing active profile.
10. `install.sh` deploys all committed profile output and wrapper commands without rebuilding profile output at install time.

## Current Code State

### Already Correct

- Pi is installed as one npm package under `~/.local`, outside fnm-managed Node versions.
- `pi/pis.sh` already handles sandbox image build, project mounts, API key forwarding, and Pi args passthrough.
- Pi extensions and subagent tests already have a Vitest test pattern, but profile management itself is shell/install logic rather than TypeScript extension logic.
- `shared/skills/` is the canonical cross-agent skills source.

### Out Of Alignment

- `install_pi()` in `install.sh` deploys a single runtime config to `~/.pi/agent` from `pi/settings.json`, `pi/models.json`, `pi/agents`, `pi/skills`, and all extensions.
- `pi/pis.sh` hardcodes `PI_AGENT_DIR="$HOME/.pi/agent"` and has no profile selection or dry-run test surface.
- There is no `pim` command, no `pi/base/`, no `pi/profiles/`, no profile build operation, and no duplicate-skill validation.
- The real npm `pi` binary currently owns the same command name the profile wrapper must own.

### Important Implementation Constraint

Keep the first implementation shell-native and conservative. Do not introduce a new package manager, JSON merge library, or generated code framework unless a red test proves shell composition is not enough. For v1, base-plus-overrides can mean full-file replacement: profile files override base files, and missing profile files fall back to base files.

## Intended Implementation Shape

Create a small shell profile manager with pure helper functions in `pi/lib/pim.sh` and thin command wrappers in `pi/pim.sh`, `pi/pi-profile.sh`, and an updated `pi/pis.sh`. The profile authoring layout should be:

```text
pi/base/
  settings.json
  models.json
  agents/
  skills/
  extensions/<extension> -> ../extensions/<extension> or copied symlink targets
pi/profiles/<name>/
  profile.env
  settings.json        # optional full-file override
  models.json          # optional full-file override
  agents/              # optional full directory override/addition model defined by tests
  skills/              # profile-local skills
  extensions.list      # enabled extension names
  resolved/            # committed generated output
```

The build step materializes `resolved/` from base plus profile-local inputs, validates duplicate skill names against `shared/skills/`, and creates symlinks in resolved output where practical. The install step deploys committed `resolved/` output into runtime directories and sets the active profile pointer.

For the npm `pi` binary, `install_pi()` should preserve the real executable as `~/.local/bin/pi-bin` or another stable internal name, then install `~/.local/bin/pi` as the wrapper. The wrapper calls the real binary with a profile-specific `HOME`/config path strategy that Pi actually honors. If Pi only reads `~/.pi/agent`, explicit wrappers must temporarily point `~/.pi/agent` for the process or set an environment variable if Pi supports one; this must be confirmed during implementation before choosing the final wrapper mechanism.

## Red/Green TDD Slices

### Slice 1: Profile Build Core

#### Red - Write tests first, no implementation code yet

Create `pi/tests/pim-build.test.sh`. Use temp directories for dotfiles root, shared skills, base profile inputs, and profile-local inputs.

- Test file: `pi/tests/pim-build.test.sh`
- What the first test proves: `pim_build_profile` creates `resolved/settings.json`, `resolved/models.json`, `resolved/agents`, `resolved/skills`, and `resolved/extensions` for a profile from base inputs.
- Assertion strategy: filesystem assertions with exact paths and symlink targets; no snapshots.
- Existing tests to rewrite: none.
- Follow-up mini-cycles:
  - duplicate shared/profile-local skill name fails with non-zero exit and leaves old `resolved/` untouched
  - profile full-file `settings.json` override wins over base
  - `extensions.list` includes only named extensions in `resolved/extensions`

Run `bash pi/tests/pim-build.test.sh`. It must fail because no profile manager exists.

**Hard gate: Do not proceed to Green until the test file exists, the first test fails, and no implementation files have been changed.**

#### Green - Make the red test pass, minimum change only

- Source file: create `pi/lib/pim.sh`
- What to change: implement `pim_build_profile`, `pim_resolve_profile_paths`, duplicate skill detection, and minimal copy/symlink materialization helpers.
- Constraint: do not implement CLI parsing or install integration in this slice.
- Spec delta this satisfies: items 2, 3, and part of 7.
- Next mini-cycle: add each follow-up behavior test, observe red, then add the smallest helper change.

Run `bash pi/tests/pim-build.test.sh` after each mini-cycle and confirm it passes.

#### Refactor - Clean up while keeping tests green

- Extract path helpers only if repeated logic appears across build behaviors.
- Keep CLI output formatting out of `pi/lib/pim.sh`.

Run `bash pi/tests/pim-build.test.sh` again.

### Slice 2: `pim` CLI Commands

#### Red - Write tests first, no implementation code yet

Create `pi/tests/pim-cli.test.sh`.

- Test file: `pi/tests/pim-cli.test.sh`
- What the first test proves: `pim list` prints profile names discovered under `pi/profiles/`.
- Assertion strategy: command output and exit code from a temp repo with fixture profiles.
- Existing tests to rewrite: none.
- Follow-up mini-cycles:
  - `pim current` reads `~/.pi/active-profile`
  - `pim path <profile>` prints `~/.pi/profiles/<profile>/agent`
  - `pim use <profile>` atomically updates `~/.pi/agent` and `~/.pi/active-profile`
  - `pim doctor` fails when active profile points to missing runtime
  - `pim create <profile>` scaffolds authoring inputs and immediately builds `resolved/`

Run `bash pi/tests/pim-cli.test.sh`. It must fail because `pi/pim.sh` does not exist.

**Hard gate: Do not proceed to Green until the first CLI test fails.**

#### Green - Make the red test pass, minimum change only

- Source file: create `pi/pim.sh`
- What to change: source `pi/lib/pim.sh`, parse subcommands, and implement only the command under test before moving to the next mini-cycle.
- Constraint: CLI commands should accept test overrides such as `PIM_DOTFILES_DIR` and `PIM_HOME` so tests never touch the real home directory.
- Spec delta this satisfies: items 5, 6, 7, and 8.
- Next mini-cycle: add and satisfy each command behavior in order.

Run `bash pi/tests/pim-cli.test.sh` after each mini-cycle.

#### Refactor - Clean up while keeping tests green

- Normalize error messages and usage output after all command tests pass.
- Keep profile build logic in `pi/lib/pim.sh`, not duplicated in `pi/pim.sh`.

Run `bash pi/tests/pim-build.test.sh` and `bash pi/tests/pim-cli.test.sh`.

### Slice 3: Initial Profile Migration

#### Red - Write tests first, no implementation code yet

Create `pi/tests/profile-layout.test.sh`.

- Test file: `pi/tests/profile-layout.test.sh`
- What the first test proves: the repo contains a default `coding` profile with committed `resolved/settings.json`, `resolved/models.json`, `resolved/agents`, `resolved/skills`, and `resolved/extensions`.
- Assertion strategy: repo path existence checks and content equivalence against current Pi config where expected.
- Existing tests to rewrite: none.
- Follow-up mini-cycles:
  - `coding` profile includes all current subagent roles
  - `coding` profile includes current Pi-only skills plus all shared skills without duplicates
  - `coding` profile enables `subagent`, `web-search`, and `inherit-last-model`

Run `bash pi/tests/profile-layout.test.sh`. It must fail because the profile layout does not exist.

**Hard gate: Do not proceed to Green until the layout test fails.**

#### Green - Make the red test pass, minimum change only

- Source files/directories: create `pi/base/`, `pi/profiles/coding/`, and committed `pi/profiles/coding/resolved/`.
- What to change: migrate current `pi/settings.json`, `pi/models.json`, `pi/agents`, and Pi-only skills into the new authoring/resolved structure for the default `coding` profile.
- Constraint: do not delete legacy `pi/settings.json`, `pi/models.json`, `pi/agents`, or `pi/skills` until install and wrapper migration is green.
- Spec delta this satisfies: items 1, 2, 3, and 8.
- Next mini-cycle: add each layout assertion, observe red, then add the minimal file movement/copy/symlink.

Run `bash pi/tests/profile-layout.test.sh` after each mini-cycle.

#### Refactor - Clean up while keeping tests green

- Document profile authoring expectations in `pi/profiles/README.md`.
- Keep generated `resolved/` output committed and deterministic.

Run all three shell tests.

### Slice 4: Install Deployment

#### Red - Write tests first, no implementation code yet

Create `pi/tests/install-pi-profiles.test.sh`.

- Test file: `pi/tests/install-pi-profiles.test.sh`
- What the first test proves: a testable install helper deploys all committed profile outputs to `~/.pi/profiles/<profile>/agent`.
- Assertion strategy: run install helper with `DOTFILES_DIR` and `HOME` pointed at temp directories; inspect symlinks and state files.
- Existing tests to rewrite: none.
- Follow-up mini-cycles:
  - `~/.pi/agent` points to the active/default profile runtime
  - `~/.pi/active-profile` contains `coding` on first install
  - missing profile `resolved/` fails the Pi module
  - reinstall is idempotent and does not create backups for already-correct symlinks
  - wrapper commands `pim`, `pi`, `pis`, `pi-coding`, and `pis-coding` are deployed

Run `bash pi/tests/install-pi-profiles.test.sh`. It must fail because `install_pi()` still deploys the old single config.

**Hard gate: Do not proceed to Green until the first install deployment test fails.**

#### Green - Make the red test pass, minimum change only

- Source file: `install.sh`
- What to change: extract profile-aware deploy helpers from `install_pi()`, deploy profile runtime symlinks, manage `~/.pi/agent`, write `~/.pi/active-profile`, and install wrapper scripts.
- Constraint: keep npm install/update behavior unchanged except for preserving the real Pi binary behind the wrapper.
- Spec delta this satisfies: items 4, 5, 6, 9, and 10.
- Next mini-cycle: add and satisfy each install behavior in order.

Run `bash pi/tests/install-pi-profiles.test.sh` after each mini-cycle.

#### Refactor - Clean up while keeping tests green

- Consolidate symlink backup logic if repeated inside `install_pi()`.
- Keep unrelated agent install modules untouched.

Run all shell tests plus `git diff --check`.

### Slice 5: Pi And Pis Wrappers

#### Red - Write tests first, no implementation code yet

Create `pi/tests/pi-wrappers.test.sh`.

- Test file: `pi/tests/pi-wrappers.test.sh`
- What the first test proves: bare `pi` wrapper resolves the active profile runtime from `~/.pi/agent`.
- Assertion strategy: wrapper dry-run mode prints resolved profile/runtime path and real binary path without launching Pi or Docker.
- Existing tests to rewrite: none.
- Follow-up mini-cycles:
  - `pi-coding` resolves `~/.pi/profiles/coding/agent` without changing active profile
  - `pis` uses active profile runtime for mounts
  - `pis-coding` uses named profile runtime for mounts
  - profile-specific sessions mount read-write while shared auth is available without duplication

Run `bash pi/tests/pi-wrappers.test.sh`. It must fail because wrappers and dry-run behavior do not exist.

**Hard gate: Do not proceed to Green until the first wrapper test fails.**

#### Green - Make the red test pass, minimum change only

- Source files: create `pi/pi.sh`, update `pi/pis.sh`, and create any thin generated wrapper template needed by install.
- What to change: implement profile resolution, dry-run output for tests, and profile-specific runtime selection for bare and named wrappers.
- Constraint: do not rebuild Docker images during tests; keep `pis --build` behavior intact for real use.
- Spec delta this satisfies: item 9 and runtime state isolation decisions.
- Next mini-cycle: add and satisfy each wrapper behavior.

Run `bash pi/tests/pi-wrappers.test.sh` after each mini-cycle.

#### Refactor - Clean up while keeping tests green

- Share profile resolution code by sourcing `pi/lib/pim.sh` rather than duplicating path logic.
- Keep Docker argument construction readable and close to the existing `pis.sh` layout.

Run all shell tests.

### Slice 6: Cleanup And Backward Compatibility

#### Red - Write tests first, no implementation code yet

Add compatibility tests to `pi/tests/profile-layout.test.sh` and `pi/tests/install-pi-profiles.test.sh`.

- Test file: existing shell tests
- What the first test proves: legacy `pi/settings.json`, `pi/models.json`, `pi/agents`, and `pi/skills` are either retained as compatibility pointers or removed only after install no longer references them.
- Assertion strategy: search/install helper assertions that no active install path depends on old single-profile sources.
- Existing tests to rewrite: any tests added earlier that accidentally endorse old paths.
- Follow-up mini-cycles:
  - stale single-profile references are absent from active specs and install code
  - `pim doctor` reports actionable errors for broken active symlink, missing shared skills, and duplicate skills

Run the relevant shell test and observe failure.

**Hard gate: Do not proceed to Green until the compatibility test fails.**

#### Green - Make the red test pass, minimum change only

- Source files: `install.sh`, `pi/lib/pim.sh`, `pi/pim.sh`, and legacy Pi files if needed.
- What to change: either convert legacy files/directories into documented compatibility shims or remove them after all references are gone.
- Constraint: do not remove user auth/session data; this slice only changes repo-managed sources.
- Spec delta this satisfies: consistency across the spec suite and codebase.

Run the targeted tests after each mini-cycle.

#### Refactor - Clean up while keeping tests green

- Remove dead comments and old single-profile wording from scripts.
- Keep changelog/history references intact.

Run all verification commands.

## Verification

### Local Verification Sequence

1. `bash pi/tests/pim-build.test.sh`
2. `bash pi/tests/pim-cli.test.sh`
3. `bash pi/tests/profile-layout.test.sh`
4. `bash pi/tests/install-pi-profiles.test.sh`
5. `bash pi/tests/pi-wrappers.test.sh`
6. `git diff --check`
7. `rg -n 'pi/settings.json|pi/models.json|~/.pi/agent/settings.json|~/.pi/agent/models.json|~/.pi/agent/skills.*pi/skills' install.sh pi specs`
8. `npm test --prefix pi/extensions/subagent`
9. Dry-run install against a temp HOME if the install helper supports it; otherwise run the extracted install helper tests as the install verification substitute.

### Subagent Verification Passes

#### Test verifier pass

Use `test-quality-verifier` on:
- `pi/tests/pim-build.test.sh`
- `pi/tests/pim-cli.test.sh`
- `pi/tests/install-pi-profiles.test.sh`
- `pi/tests/pi-wrappers.test.sh`

Prompt focus:

`Review the Pi profile shell tests for weak assertions. Find places where the tests would pass even if shared skills were omitted from a profile, duplicate profile-local skill names were silently allowed, wrappers targeted the active profile when a named profile was requested, or install mutated the wrong HOME.`

#### Pre-mortem pass

Use a generic reviewer or premortem agent on:
- `install.sh`
- `pi/lib/pim.sh`
- `pi/pim.sh`
- `pi/pi.sh`
- `pi/pis.sh`
- `pi/profiles/`

Prompt focus:

`Perform a pre-mortem on Pi profile management. Assume tests pass but the feature ships with a bad developer experience. Focus on profile switching corrupting runtime state, npm updates clobbering the pi wrapper, shared skills disappearing from profiles, profile-local duplicates being missed, sandbox mounts leaking state across profiles, and install not being idempotent.`

## Acceptance Criteria

1. `pim create <profile>` creates authoring inputs and committed resolved output for a usable profile.
2. `pim build <profile>` regenerates deterministic resolved output and fails on duplicate shared/profile-local skill names.
3. Every Pi profile includes all `shared/skills/` entries.
4. `pim use <profile>` updates `~/.pi/agent` and `~/.pi/active-profile` without rewriting wrapper scripts.
5. Bare `pi` and `pis` use the active profile.
6. `pi-<profile>` and `pis-<profile>` use the named profile without changing the active profile.
7. `install.sh --modules pi` deploys all committed profile output and wrapper commands idempotently.
8. The default `coding` profile preserves the current Pi setup's settings, models, agents, skills, and enabled extensions.
9. Shared `auth.json` remains available while sessions/history are profile-local.
10. All quality gates pass.

## Implementation Checklist

- [ ] **Slice 1 / Cycle A: Build default resolved profile** - Create `pi/tests/pim-build.test.sh`, write one behavior test for resolved output creation.
- [ ] **Slice 1 / Cycle A: RED** - Run `bash pi/tests/pim-build.test.sh`, observe missing `pim_build_profile` failure.
- [ ] **Slice 1 / Cycle A: GREEN** - Create `pi/lib/pim.sh` and implement minimal profile build output creation.
- [ ] **Slice 1 / Cycle A: GREEN** - Run `bash pi/tests/pim-build.test.sh`, observe pass.
- [ ] **Slice 1 / Cycle B: Duplicate skill error** - Add duplicate shared/profile-local skill test.
- [ ] **Slice 1 / Cycle B: RED** - Run `bash pi/tests/pim-build.test.sh`, observe duplicate is not rejected.
- [ ] **Slice 1 / Cycle B: GREEN** - Implement duplicate skill validation in `pi/lib/pim.sh`.
- [ ] **Slice 1 / Cycle B: GREEN** - Run `bash pi/tests/pim-build.test.sh`, observe pass.
- [ ] **Slice 1: REFACTOR** - Extract path helpers if needed and rerun `bash pi/tests/pim-build.test.sh`.

- [ ] **Slice 2 / Cycle A: CLI list** - Create `pi/tests/pim-cli.test.sh`, write `pim list` test.
- [ ] **Slice 2 / Cycle A: RED** - Run `bash pi/tests/pim-cli.test.sh`, observe missing CLI failure.
- [ ] **Slice 2 / Cycle A: GREEN** - Create `pi/pim.sh` with minimal `list`.
- [ ] **Slice 2 / Cycle A: GREEN** - Run `bash pi/tests/pim-cli.test.sh`, observe pass.
- [ ] **Slice 2 / Cycles B-F** - Add and satisfy `current`, `path`, `use`, `doctor`, and `create` one at a time.
- [ ] **Slice 2: REFACTOR** - Normalize CLI parsing and rerun build and CLI tests.

- [ ] **Slice 3 / Cycle A: Coding profile layout** - Create `pi/tests/profile-layout.test.sh`, write default profile resolved-output test.
- [ ] **Slice 3 / Cycle A: RED** - Run `bash pi/tests/profile-layout.test.sh`, observe missing layout failure.
- [ ] **Slice 3 / Cycle A: GREEN** - Create `pi/base/` and `pi/profiles/coding/` with committed `resolved/`.
- [ ] **Slice 3 / Cycle A: GREEN** - Run `bash pi/tests/profile-layout.test.sh`, observe pass.
- [ ] **Slice 3 / Cycles B-D** - Add and satisfy tests for agents, skills, and enabled extensions.
- [ ] **Slice 3: REFACTOR** - Add `pi/profiles/README.md` and rerun all shell tests created so far.

- [ ] **Slice 4 / Cycle A: Install deploys profiles** - Create `pi/tests/install-pi-profiles.test.sh`, write profile runtime deploy test.
- [ ] **Slice 4 / Cycle A: RED** - Run `bash pi/tests/install-pi-profiles.test.sh`, observe old single-profile deployment failure.
- [ ] **Slice 4 / Cycle A: GREEN** - Update `install.sh` Pi deployment helper for profile runtimes.
- [ ] **Slice 4 / Cycle A: GREEN** - Run `bash pi/tests/install-pi-profiles.test.sh`, observe pass.
- [ ] **Slice 4 / Cycles B-E** - Add and satisfy active symlink, active-profile file, missing output failure, idempotency, and wrapper deployment tests.
- [ ] **Slice 4: REFACTOR** - Consolidate symlink helpers if needed and rerun all shell tests plus `git diff --check`.

- [ ] **Slice 5 / Cycle A: Bare pi wrapper** - Create `pi/tests/pi-wrappers.test.sh`, write dry-run active profile resolution test.
- [ ] **Slice 5 / Cycle A: RED** - Run `bash pi/tests/pi-wrappers.test.sh`, observe missing wrapper behavior.
- [ ] **Slice 5 / Cycle A: GREEN** - Create `pi/pi.sh` and minimal dry-run profile resolution.
- [ ] **Slice 5 / Cycle A: GREEN** - Run `bash pi/tests/pi-wrappers.test.sh`, observe pass.
- [ ] **Slice 5 / Cycles B-D** - Add and satisfy named `pi-<profile>`, active `pis`, and named `pis-<profile>` tests.
- [ ] **Slice 5: REFACTOR** - Share profile resolution through `pi/lib/pim.sh` and rerun all shell tests.

- [ ] **Slice 6 / Cycle A: Legacy path cleanup** - Add compatibility/stale-reference tests.
- [ ] **Slice 6 / Cycle A: RED** - Run targeted tests, observe old path dependency failure.
- [ ] **Slice 6 / Cycle A: GREEN** - Remove or convert legacy single-profile repo sources after all install references are gone.
- [ ] **Slice 6 / Cycle A: GREEN** - Run targeted tests, observe pass.
- [ ] **Slice 6: REFACTOR** - Remove stale script comments and rerun all verification commands.

- [ ] Run local verification sequence.
- [ ] Run test-quality-verifier pass and address findings.
- [ ] Run pre-mortem pass and address findings.

## References

- `/Users/mtomcal/dotfiles/specs/UBIQUITOUS_LANGUAGE.md`
- `/Users/mtomcal/dotfiles/specs/ai-agent-config.md`
- `/Users/mtomcal/dotfiles/specs/install-orchestrator.md`
- `/Users/mtomcal/dotfiles/specs/tool-provisioning.md`
- `/Users/mtomcal/dotfiles/specs/parameters.md`
- `/Users/mtomcal/dotfiles/specs/symlink-manager.md`
- `/Users/mtomcal/dotfiles/install.sh`
- `/Users/mtomcal/dotfiles/pi/pis.sh`
- `/Users/mtomcal/dotfiles/pi/settings.json`
- `/Users/mtomcal/dotfiles/pi/models.json`
- `/Users/mtomcal/dotfiles/pi/agents/`
- `/Users/mtomcal/dotfiles/pi/skills/`
- `/Users/mtomcal/dotfiles/shared/skills/`

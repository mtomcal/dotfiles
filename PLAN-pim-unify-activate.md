# pim unify build/deploy Implementation Plan
## Collapse pim into one activation surface

> **Status**: PLANNING — 8 design decisions resolved via grill-me session + spec delta. Ready for TDD implementation.

---

## Context Basis

### Spec Delta (commit `9643cb7` merged to main)

1. **B4.3 §7**: Surface commands narrowed to `list`, `current`, `path <profile>`, `doctor`, `create <profile>`. Zero arguments displays a dashboard listing all profiles under `pi/profiles/`, showing each name, its runtime path, valid resolved/redeployed status, with active clearly marked.
2. **B4.3 §8**: Profile activation is the single unified entry point for build + deploy. Always compiles source into resolved output, then deploys all symlinks regardless of whether resolved already exists. Atomic: both phases must succeed; if either fails, abort without updating active state — leave existing active profile completely unmodified. Entry via `pim activate <profile>`, `pim use <profile>`, or bare `pim <profile>` when `<profile>` is not a recognized subcommand.
3. **B4.3 §9**: `pim create <profile>` must only scaffold authoring inputs (profile.env, agents/, skills/ dirs, extensions.list). Does NOT generate resolved output or deploy.
4. **AIAGT-015 update**: Duplicate skill error aborts profile activation with explicit name, preserving existing active state.
5. **UBIQUITOUS_LANGUAGE.md**: Added `**activate**` and `**dashboard**` terms to Agent Domain.

### Grill Decisions

| # | Question | Decision | Source |
|---|----------|----------|--------|
| Q1 | Which command is the authority? | `pim use <profile>` is the unified surface; it always builds then deploys | grill-me |
| Q2 | How does bare `pim` behave? | Dashboard: shows available profiles with active marker + runtime path + valid-resolved + deployed status | grill-me |
| Q3 | Are build/deploy still visible as surface commands? | No. Both vanish from CLI; become internal only called by the unified activate pipeline | grill-me |
| Q4 | When does `use` trigger build? | Always — every call recompiles from source | grill-me |
| Q5 | Repeated calls to same profile? | Full idempotent re-execution on every call. No caching or freshness check | grill-me |
| Q6 | Bare pim + one-word arg (e.g., `pim coding`)? | If the argument is not a recognized subcommand, treat it as an activiation target: `pim use <profile>` / `pim activate <profile>`. Git-style disambiguation | grill-me |
| Q7 | What about `pim create`? | Scaffold-only. Creates dir + scaffolds profile.env, agents/, skills/, extensions.list. User must then run activation separately | grill-me |
| Q8 | Fail handling: build fails vs deploy fails? | Abort on first failure, never update active state. Build failure → don't swap symlinks or touch active-profile. Deploy failure → resolved dir was written but active profile unchanged and user's current symlink untouched | grill-me |

---

## Overview

Collapse `pim build` and `pim deploy` into a single unified activation pipeline triggered by the existing `pim use <profile>` command (also via explicit `pim activate <profile>` for readability). The new surface commands are: **list**, **current**, **path <profile>**, **doctor**, **create <profile>** — plus dashboards on bare zero-arg `pim`. Users switch profiles by typing `pim use coding` or `pim coding`, and activation always recompiles + deploys fresh.

---

## Context Input

### Spec Delta To Implement

1. The visible pim surface MUST NOT include `build` or `deploy` commands in usage output.
2. Zero-argument pim MUST display a dashboard: profile name, runtime path, resolved status (`YES`/`NO`), deployed status (`YES`/`NO`, based on whether active symlink points to existing runtime), with the active profile marked by `*`.
3. Profile activation (via `activate` subcommand, `use` subcommand, or bare arg) MUST always run full build pipeline then deploy pipeline. Skip nothing.
4. Activation MUST be atomic: if build fails OR deploy fails, do not update `~/.pi/agent`, do not update `~/.pi/active-profile`. Leave everything as it was before the call. If an active profile was previously selected, restore it on failure.
5. `pim create <profile>` MUST ONLY scaffold — mkdir, profile.env (with PI_PROFILE=), agents/ dir, skills/ dir, and copy base extensions.list if present. No build, no deploy.
6. The first argument of pim, when not matching a known subcommand (`list`, `current`, `path`, `doctor`, `create`, `activate`, `use`), MUST be treated as a profile name to activate — provided it passes `pim_validate_profile_name`. Print an activation message ("activated profile: X") similar to current usage.

### Current Code State

#### What is already correct
- **lib/pim.sh**: All core functions (`pim_build_profile`, `pim_deploy_profile`, `pim_resolve_profile_paths`, `pim_replace_symlink`, etc.) are correctly implemented and tested. They do not need changes — they are internal implementation details exposed through the new unified pipeline.
- **cmd_list / cmd_current / cmd_path**: These work correctly; no behavioral change needed.
- **test infrastructure**: Helper functions (`new_tmp`, `run_pim`, `assert_eq`, `assert_symlink_to`) provide solid testing scaffolding.
- **Atomic symlink swap in `cmd_use`** (lines ~83-91): The temp-link + mv pattern is already atomic; keep it for activate pipeline.

#### What is currently out of spec / needs change
- **`pim.sh:cmd_build` (~line 107)**: Exposed as surface command — must be removed from CLI and called only by the activate pipeline (the function itself stays in lib/pim.sh).
- **`pim.sh:cmd_deploy` (~line 123)**: Same — remove from surface, call only internally.
- **`pim.sh:main` case dispatch**: Routes to `build` and `deploy` subcommands — must be replaced with activation router that delegates to the unified activate function.
- **`pim.sh:cmd_use` (~line 70)**: Currently checks if runtime exists, only deploys if missing, never builds. Must become: always call `pim_build_profile` then `pim_deploy_profile`, then atomically swap active state.
- **`pim.sh:cmd_create` (~line 94)**: Calls `pim_build_profile` internally at the end — must be removed per spec B4.3 §9.
- **Dashboard**: No implementation exists yet for zero-arg pim. Will add a new internal function `cmd_dashboard`.
- **Bare arg routing**: No disambiguation logic; unrecognized args currently hit `*) usage; exit 2`.

#### Important implementation constraint
Do not modify files in `pi/lib/pim.sh` or any of its helper functions (`pim_build_profile`, `pim_deploy_profile`, `pim_resolve_profile_paths`, `pim_link_entries`, `pim_materialize_extensions`, etc.). These are tested, correct, and form the internal library that the new surface calls into. Only modify `pi/pim.sh` (the CLI entry point).

---

## Intended Implementation Shape

The implementation lives entirely in `pi/pim.sh`. Lib functions stay untouched. The changes are:

1. **Add `cmd_dashboard`** — iterates over profile dirs, checks resolved/redeployed status, prints formatted output with active marker.
2. **Add `cmd_activate`** — calls `pim_build_profile`, then `pim_deploy_profile`, then atomically updates `~/.pi/agent` + `~/.pi/active-profile`. If anything fails mid-pipeline, restore original active state if it changed partway and exit non-zero.
3. **Update `cmd_use`** — delegates to `cmd_activate` (or make `use` an alias for `activate`).
4. **Replace `main` case block** — remove `build`/`deploy` routes, add `activate` + bare arg disambiguation logic. If first arg is not a known subcommand but passes profile validation, route to activate.
5. **Remove auto-build from `cmd_create`** — delete the `pim_build_profile` call at the bottom of create.

Slices follow this dependency order: new surface (dashboard) → core pipeline (activate) → routing changes (bare args + use/activate aliases) → removal of old commands → test updates.

---

## Red/Green TDD Slices

### Slice 1: Dashboard (zero-arg pim output)

#### Red — Write tests first, no implementation code yet

Test file: `pi/tests/pim-cli.test.sh` (append new test functions at bottom).

What the test proves: Zero-argument pim displays profile names, runtime paths, resolved/deployed status, and active marker.

Append to `pi/tests/pim-cli.test.sh`:

```bash
test_dashboards_lists_profiles_with_metadata() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$home/.pi/profiles/coding/agent"
    mkdir -p "$home/pi/profiles/local/resolved"  ## (simulate built)

    printf 'local\n' > "$home/.pi/active-profile"
    ln -sf "$home/.pi/profiles/local/agent" "$home/.pi/agent"
```

The output includes profile names, runtime paths, resolved/deployed status (`YES`/`NO`), and `* local` active marker.

Assertion strategy: capture stdout, grep for profile names, check format lines contain runtime path, verify active marker line exists.

Existing tests to rewrite: none — add only new test functions.

Follow-up mini-cycle: add a second test that verifies non-built profiles show resolved status `NO`.

Run the test suite. You must see the test fail because `cmd_dashboard` does not exist yet.

**Hard gate: Do not proceed to Green until you have created the test code and run it, observed failure.** No implementation in pim.sh should be written at this stage.

#### Green — Make the red test pass, minimum change only

Source file: `pi/pim.sh` (add function, wire into main)

What to change:
1. Add `cmd_dashboard` function that reads `$PIM_DOTFILES_DIR/pi/profiles/` or falls back to default profiles dir, iterates each subdirectory, checks resolved/redeployed status for each, prints formatted table with active marker (`* profile_name`).
2. Add dashboard routing in `main`: if zero args → dispatch to `cmd_dashboard`.

Constraint: Minimal — do not introduce new helper functions beyond what the dashboard needs. Status checking can be inline checks using `[[ -d ]]/resolved && [[ -L ~/.pi/active-profile ]]` patterns already present elsewhere in pim.sh or lib/pim.sh.

Decisions/spec delta this satisfies: Spec B4.3 §7 (dashboard behavior), Decision Q2.

Next mini-cycle: test that non-deployed profiles show `NO` for deployed status.

#### Refactor — Clean up while keeping tests green

- [ ] None needed initially
- Run the dashboard test confirming still green.

---

### Slice 2: Bare arg routing (pim <profile> = activation)

#### Red — Write tests first, no implementation code yet

Append to `pi/tests/pim-cli.test.sh`:

```bash
test_bare_profile_name_triggers_activation() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    
    # Pre-build and deploy the coding profile so activation has source to act on
    PIM_DOTFILES_DIR="$root" bash "$PIM" build coding >/dev/null 2>&1 || true
    
    run_pim "$root" "$home" coding 2>/tmp/pim-bare.out
```

Output includes "activated profile: coding"; `~/.pi/agent` points to coding; active-profile file contains "coding".

Run the test suite. Must fail because bare arg `coding` hits `*) usage; exit 2`.

**Hard gate: Do not proceed to Green until you have written this test and observed failure.**

#### Green — Make the red test pass, minimum change only

Source file: `pi/pim.sh` (main function)

What to change: In `main`, after shifting off commands, before the default `*) usage` case, add logic that treats an unrecognized first argument as a profile name to activate — if it passes `pim_validate_profile_name`. This dispatches to the activate pipeline with explicit activation output.

Decisions/spec delta this satisfies: Decision Q6, Spec B4.3 §8 (bare arg routing), Spec B4.3 §9 (surface narrow).

#### Refactor — Clean up while keeping tests green

- [ ] None needed if minimal pattern is followed; the bare-arg disambiguation fits inside the existing case-block default path or as a pre-check.
- Run bash suite confirming still green.

---

### Slice 3: Unified activate pipeline function

This is the core slice — builds then deploys atomically.

#### Red — Write tests first, no implementation code yet

Append to `pi/tests/pim-cli.test.sh`:

```bash
test_activate_always_builds_then_deploys() {
    local root home output status
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$root/pi/profiles/coding/skills"  ## (profile needs skills dir)
```

Run the test suite. Must fail because `cmd_activate` does not exist yet.

**Hard gate: Do not proceed to Green until you have written this test and observed failure.**

#### Green — Make the red test pass, minimum change only

Source file: `pi/pim.sh` (add `cmd_activate`)

What to change:
1. Add `cmd_activate() { ... }` function that:
   - Calls `pim_build_profile "$profile"` via lib/pim.sh functions
   - Then calls `pim_deploy_profile "$profile"`
   - Then atomically swaps `~/.pi/agent` + writes `~/.pi/active-profile` (reuse temp-link+mv pattern already in `cmd_use`)

Constraint: Minimal — call into existing lib functions; do not rewrite them. The atomic swap preserves the temp-link pattern from `cmd_use` (~line 83-91).

Follow-up mini-cycle: test that build failure leaves active state unmodified.

#### Refactor — Clean up while keeping tests green

- [ ] Consider whether to have `use` delegate to `activate` or vice versa
- Run bash suite confirming still green.

---

### Slice 4: Build-failure atomicity (preserve active state)

#### Red — Write tests first, no implementation code yet

Append to `pi/tests/pim-cli.test.sh`:

```bash
test_activate_preserves_active_state_when_build_fails() {
    ## Build a profile dir with duplicate skill names so build aborts.
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$root/pi/profiles/coding/skills/shared-one"  ## duplicate of shared skill
```

#### Green — Make the red test pass, minimum change only

Source file: `pi/pim.sh` (`cmd_activate`)

What to change: Add pre-pipeline backup of current active state before calling build/probe. If activation pipeline encounters any error (from `pim_build_profile` or `pim_deploy_profile`), restore the backed-up active state. Use a try/except pattern in bash: set trap on ERR that restores, or capture exit codes per phase and only commit atomic swap if both succeed.

Decisions/spec delta this satisfies: Decision Q8 (fail handling).

#### Refactor — Clean up while keeping tests green

- [ ] Extract the backup+restore logic into a small helper function in `cmd_activate` to keep it readable
- Run bash suite confirming still green.

---

### Slice 5: Remove auto-build from create + swap build/deploy → activate surface commands

#### Red — Write tests first, no implementation code yet

Append to `pi/tests/pim-cli.test.sh`:
**Test A (scaffold-only)**: Re-run `test_create_scaffolds_and_builds_profile` with new assertion that `resolved/` directory does NOT exist after create. Name: `test_create_is_scaffold_only`.

```bash
test_create_is_scaffold_only() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    run_pim "$root" "$home" create review >/dev/null

    [[ -f "$root/pi/profiles/review/profile.env" ]] || fail "missing profile.env"
    [[ -L "$root/pi/profiles/review/resolved/settings.json" ]] && fail "resolved should NOT exist after create"
}
```

**Test B (use = built profile)**: Add `test_use_always_builds_and_deploys_profile` — call use on a fresh profile (no prior build or deploy). Expected: resolved and runtime both exist, active symlink is set.

Run the test suite. Test A must fail because create currently auto-buil

#### Green — Make the red pass, minimum change only

Source file: `pi/pim.sh`

What to change:
1. In `cmd_create`: Remove the final `PIM_DOTFILES_DIR="$root" pim_build_profile "$profile"` call (line ~97). That's it for scaffold-only.
2. Wire `use` to activate: Replace `cmd_use` body with a delegation to `cmd_activate`. Or alias `activate` → `use` in `main` — pick the simpler routing path. Remove the "if runtime missing, deploy" logic from `cmd_use` since activation always deploys regardless.
3. In `main`'s case block: Remove `build)` and `deploy)` cases. Replace with `activate | use)`.

Constraint: Minimal. The only behavioral changes are to `cmd_create` (delete one line), main routing, and possibly collapsing the `use`/`activate` codepaths.

Decisions/spec delta this satisfies: Spec B4.3 §7 (surface narrow), Grill Decision Q3 (build/deploy surface removed).

#### Refactor — Clean up while keeping tests green

- [ ] If you have both cmd_use and cmd_activate code paths, consider whether to keep one or fully deprecate the other
- Run bash suite confirming still green.

---

### Slice 6: Update / cleanup existing tests for new behavior

#### Red — Verify affected test expectations match new spec

Current tests that need adjustment (check each):

1. `test_create_scaffolds_and_builds_profile` → must change to `test_create_is_scaffold_only` (no longer assert resolved exists).
2. `test_use_deploys_built_profile_when_runtime_is_missing` → rename to `test_activate_always_builds_and_deploys` — verify build always happens even when runtime already exists. Remove the `build local >/dev/null` step since activate now builds itself.
3. `test_deploy_command_deploys_built_profile` → must be removed entirely (deploy is no longer a surface command).
4. Any test that calls `pim build` — replace with implicit activation path or delete.

#### Green — Update test assertions and remove dead tests

File: `pi/tests/pim-cli.test.sh`

Update:
- Rewrite `test_create_scaffolds_and_builds_profile` → `test_create_is_scaffold_only` (assert resolved does NOT exist)
- Rename `test_use_deploys_built_profile_when_runtime_is_missing` → simplify to just call activate on a fresh profile, verify everything deployed
- Remove `test_deploy_command_deploys_built_profile` test entirely (no deploy command exists)
- Update any test that invokes `run_pim "$root" "$home" build ...` — activation now happens via activate/use; or if the test only needed resolved output for setup, call activate directly

Run full test suite. All tests must pass with new behavior.

#### Refactor — Clean up while keeping tests green

- [ ] Ensure all test function names match their behavior (no misleading names)
- Verify no stale test code remains
- Run bash suite confirming still green.

---

## Reviewer Findings

| Finding in previous exploration | How addressed in plan |
|-------------------------------|------------------------|
| Spec B4.3 §8 says "always builds then deploys" | Slice 3 implements this as the core activate pipeline. No conditional skips |
| Duplicate skill errors must preserve active state | Slice 4 adds atomicity/rollback logic: backup before build, restore on failure |
| Bare arg disambiguation pattern (git-style) | Slice 2 adds profile-name detection to main routing when first arg doesn't match a known subcommand |

---

## Acceptance Criteria

1. `[pim use <profile>]` always rebuilds resolved output from source AND deploys symlinks, regardless of whether runtime already exists.
2. Activation failure (build or deploy) MUST not modify `~/.pi/agent`, `~/.pi/active-profile`, or any other active state — existing profile remains fully intact.
3. **Bare `pim` with zero arguments** prints a dashboard listing all available profiles, each showing name, runtime path, resolved status (YES/NO), deployed status (YES/NO), and an asterisk on the active profile.
4. Bare `pim <profile_name>` triggers activation (build + deploy) when `<profile_name>` is not a recognized subcommand but passes `pim_validate_profile_name`. Prints "activated profile: X".
5. **`pim create <profile>`** only scaffolds `profile.env`, `agents/`, `skills/`, and `extensions.list`. No `resolved/` directory is created.
6. `build` and `deploy` do NOT appear in pim usage output or accept arguments via the CLI. Usage lists: `list, current, <profile>, path <profile>, doctor, create <profile>, activate <profile>`.
7. **`pim doctor`** remains available as a diagnostic, unchanged behavior (validates active profile, duplicate skills, symlink consistency).
8. All existing tests pass after behavioral updates; new tests cover dashboard, bare-arg routing, activation atomicity, and scaffold-only create.

---

## Implementation Checklist

- [ ] **Slice 1 / Cycle A: Dashboard lists profiles** — Append test to `pi/tests/pim-cli.test.sh` verifying zero-arg pim outputs profile entries with resolved/deployed status and active marker
- [ ] **Slice 1 / Cycle A: RED** — Run `bash ./pi/tests/pim-cli.test.sh`, observe failure for dashboard test (cmd_dashboard not implemented)
- [ ] **Slice 1: GREEN** — Implement `cmd_dashboard` in `pi/pim.sh`; add zero-arg case in `main` dispatcher
- [ ] **Slice 1 / Cycle A: GREEN** — Run `bash ./pi/tests/pim-cli.test.sh`, observe pass for dashboard test
- [ ] **Slice 1 / Cycle B: Dashboard shows NO status for non-deployed profiles** — Write second dashboard test that creates a profile with resolved output but no deployed runtime
- [ ] **Slice 1 / Cycle B: RED** — Run `bash ./pi/tests/pim-cli.test.sh`, observe failure (dashboard doesn't show per-profile status yet)
- [ ] **Slice 1 / Cycle B: GREEN** — Implement per-profile status detection inside cmd_dashboard (check resolved/ exists, check active symlink)
- [ ] **Slice 1 / Cycle B: GREEN** — Run `bash ./pi/tests/pim-cli.test.sh`, observe pass for both tests
- [ ] **Slice 1: REFACTOR** — Clean up any formatting/format strings in dashboard output (or "none needed")
- [ ] **Slice 1: REFACTOR** — Run `bash ./pi/tests/pim-cli.test.sh`, confirm still green
- [ ] **Slice 2 / Cycle A: Bare profile name triggers activation** — Append test to pim-cli.test.sh that sets up a built profile then calls pim with bare profile arg ("coding") and verifies activate output, active symlink, and active-profile file
- [ ] **Slice 2 / Cycle A: RED** — Run `bash ./pi/tests/pim-cli.test.sh`, observe failure (pim coding hits usage error)
- [ ] **Slice 2: GREEN** — Add bare-arg disambiguation in main function; add route for non-subcommand first args to activate pipeline
- [ ] **Slice 2 / Cycle A: GREEN** — Run `bash ./pi/tests/pim-cli.test.sh`, observe pass for bare-arg test
- [ ] **Slice 2: REFACTOR** — "None needed if minimal disambiguation pattern works" (check if cleanup is needed)
- [ ] **Slice 2: REFACTOR** — Run `bash ./pi/tests/pim-cli.test.sh`, confirm still green
- [ ] **Slice 3 / Cycle A: Activate always builds then deploys** — Append test to pim-cli.test.sh that sets up a fresh profile dir and runs activate, verifying both resolved/ was created and active state was set
- [ ] **Slice 3 / Cycle A: RED** — Run `bash ./pi/tests/pim-cli.test.sh`, observe failure (cmd_activate not implemented)
- [ ] **Slice 3: GREEN** — Implement `cmd_activate` in pim.sh; delegate activate/use to it in main routing
- [ ] **Slice 3 / Cycle A: GREEN** — Run `bash ./pi/tests/pim-cli.test.sh`, observe pass
- [ ] **Slice 4 / Cycle A: Activate preserves state on build failure** — Test that a profile with duplicate skills fails activation without modifying active-profile or agent symlink
- [ ] **Slice 4 / Cycle A: RED** — Run `bash ./pi/tests/pim-cli.test.sh`, observe failure (no atomicity/rollback logic)
- [ ] **Slice 4: GREEN** — Add pre-pipeline active-state backup + post-failure restore in cmd_activate; use temp-link+mv pattern from existing cmd_use code
- [ ] **Slice 4 / Cycle A: GREEN** — Run `bash ./pi/tests/pim-cli.test.sh`, observe pass
- [ ] **Slice 5 / Cycle A: Create is scaffold-only** — Rewrite test_create_scaffolds_and_builds_profile to assert resolved/ does NOT exist after create
- [ ] **Slice 5 / Cycle A: RED** — Run `bash ./pi/tests/pim-cli.test.sh`, observe failure (create still auto-buil

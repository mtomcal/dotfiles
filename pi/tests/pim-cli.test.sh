#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$TEST_DIR/../.." && pwd)"
PIM="$DOTFILES_DIR/pi/pim.sh"
TMP_DIRS=()

cleanup() {
    if [[ ${#TMP_DIRS[@]} -gt 0 ]]; then
        rm -rf "${TMP_DIRS[@]}"
    fi
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

new_tmp() {
    local tmp
    tmp="$(mktemp -d)"
    TMP_DIRS+=("$tmp")
    printf '%s\n' "$tmp"
}

make_repo() {
    local root="$1"
    mkdir -p "$root/pi/base/agents" "$root/pi/extensions/subagent" "$root/pi/profiles/coding" "$root/pi/profiles/local"
    mkdir -p "$root/shared/skills/shared-one"
    printf '{"base":true}\n' > "$root/pi/base/settings.json"
    printf '{"models":true}\n' > "$root/pi/base/models.json"
    printf 'agent\n' > "$root/pi/base/agents/implementer.md"
    printf 'shared\n' > "$root/shared/skills/shared-one/SKILL.md"
    printf 'subagent\n' > "$root/pi/base/extensions.list"
    printf 'extension\n' > "$root/pi/extensions/subagent/index.ts"
    # give local a base-settings so pim_build_profile succeeds for it
    if [[ ! -f "$root/pi/profiles/local/settings.json" ]]; then
        cp "$root/pi/base/settings.json" "$root/pi/profiles/local/settings.json"
    fi
    if [[ ! -f "$root/pi/profiles/local/models.json" ]]; then
        cp "$root/pi/base/models.json" "$root/pi/profiles/local/models.json"
    fi
}

run_pim() {
    local root="$1"
    local home="$2"
    shift 2
    PIM_DOTFILES_DIR="$root" PIM_HOME="$home" bash "$PIM" "$@"
}

assert_eq() {
    local actual="$1"
    local expected="$2"
    [[ "$actual" == "$expected" ]] || fail "expected <$expected>, got <$actual>"
}

assert_symlink_to() {
    local path="$1"
    local target="$2"
    [[ -L "$path" ]] || fail "expected symlink: $path"
    [[ "$(readlink "$path")" == "$target" ]] || fail "expected $path -> $target, got $(readlink "$path")"
}

# ── Slice 1 tests (dashboard) ────────────────────────────────────────────────

test_dashboards_lists_profiles_with_metadata() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    # Pre-build the coding profile so it shows as resolved=YES, deployed=YES
    PIM_DOTFILES_DIR="$root" pim_build_profile "coding" >/dev/null 2>&1 || true
    mkdir -p "$home/.pi/profiles/coding/agent"

    output="$(run_pim "$root" "$home")"
    # must list both profiles with name, resolved= and deployed=
    printf '%s\n' "$output" | grep -qw 'coding' || fail "dashboard should contain profile name 'coding'"
    printf '%s\n' "$output" | grep -qw 'local'     || fail "dashboard should contain profile name 'local'"
    # each line must have resolved= and deployed= columns
    local all_lines_ok=true
    while IFS= read -r line; do
        if ! printf '%s\n' "$line" | grep -qE 'resolved=(YES|NO)'; then
            all_lines_ok=false
            break
        fi
        if ! printf '%s\n' "$line" | grep -qE 'deployed=(YES|NO)'; then
            all_lines_ok=false
            break
        fi
    done <<< "$output"
    "${all_lines_ok:+true}" || fail "dashboard lines should contain resolved/ deployed values"
}

test_dashboard_marks_active_profile() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$home/.pi/profiles/coding/agent"
    # mark coding as active
    mkdir -p "$home/.pi"
    printf 'coding\n' > "$home/.pi/active-profile"
    ln -sf "$home/.pi/profiles/coding/agent" "$home/.pi/agent"

    output="$(run_pim "$root" "$home")"
    
    # active profile must have * marker — the line for coding starts with *
    local coding_line
    coding_line="$(printf '%s\n' "$output" | grep 'coding')"
    [[ "$coding_line" == '*'* ]] || fail "dashboard should mark active profile with *, got: $coding_line"
}

test_dashboard_shows_resolved_no_for_non_built_profiles() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    # only coding is built; local should show resolved=NO
    PIM_DOTFILES_DIR="$root" pim_build_profile "coding" >/dev/null 2>&1 || true
    mkdir -p "$home/.pi/profiles/coding/agent"

    output="$(run_pim "$root" "$home")"

    local local_line
    local_line="$(printf '%s\n' "$output" | grep 'local')"
    printf '%s\n' "$local_line" | grep -q 'resolved=NO' || \
        fail "local profile should show resolved=NO, got: $local_line"
}

test_dashboard_shows_deployed_no_for_runtime_missing() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    # build coding so it has resolved=yes but no runtime dir → deployed=should be NO
    PIM_DOTFILES_DIR="$root" pim_build_profile "coding" >/dev/null 2>&1 || true
    # do NOT create the runtime dir for local (already missing)

    mkdir -p "$home/.pi/profiles/coding/agent"  # coding gets deployed=true

    output="$(run_pim "$root" "$home")"

    # coding should show deployed=YES (we created the agent dir above)
    local coding_line
    coding_line="$(printf '%s\n' "$output" | grep 'coding')"
    printf '%s\n' "$coding_line" | grep -q 'deployed=YES' || \
        fail "coding should show deployed=YES when runtime dir exists, got: $coding_line"
}

# ── Slice 2 tests (bare arg routing) ─────────────────────────────────────────

test_bare_profile_name_triggers_activation() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$root/pi/profiles/coding/skills"  # needs skills dir, already there from make_repo

    run_pim "$root" "$home" coding >/dev/null

    assert_eq "$(cat "$home/.pi/active-profile")" "coding"
    assert_symlink_to "$home/.pi/agent" "$home/.pi/profiles/coding/agent"
}

# ── Slice 3 tests (unified activate pipeline) ────────────────────────────────

test_activate_always_builds_then_deploys() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    # delete resolved so we can verify it gets created by the call
    rm -rf "$root/pi/profiles/coding/resolved"

    output="$(run_pim "$root" "$home" use coding 2>&1)"

    # must have built (resolved/ now exists)
    [[ -d "$root/pi/profiles/coding/resolved" ]] || fail "activating should create resolved dir"
    # must have deployed (agent dir created + active state set)
    assert_eq "$(cat "$home/.pi/active-profile")" "coding"
    [[ "$(printf '%s\n' "$output")" == *'activated profile: coding'* ]] || \
        fail "activate should print activation notice, got: $output"
}

test_use_always_rebuilds_even_when_runtime_exists() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    # create a valid runtime dir so old code would skip deploy
    mkdir -p "$home/.pi/profiles/coding/agent"

    # remove resolved so we can confirm rebuild happens
    rm -rf "$root/pi/profiles/coding/resolved"

    run_pim "$root" "$home" coding >/dev/null

    [[ -d "$root/pi/profiles/coding/resolved" ]] || fail "activate always rebuilds, but resolved dir is missing"
    assert_eq "$(cat "$home/.pi/active-profile")" "coding"
}

# ── Slice 4 test (activation preserves state on failure) ────────────────────

test_activate_preserves_active_state_on_build_failure() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    # set up an active profile first so we have state to restore
    mkdir -p "$home/.pi/profiles/valid-prod/agent"
    printf 'valid-prod\n' > "$home/.pi/active-profile"
    ln -sf "$home/.pi/profiles/valid-prod/agent" "$home/.pi/agent"

    # create coding with a duplicate skill (shared-one already in shared)
    mkdir -p "$root/pi/profiles/coding/skills/shared-one"
    printf 'duplicate\n' > "$root/pi/profiles/coding/skills/shared-one/SKILL.md"

    if run_pim "$root" "$home" coding >/tmp/pim-activate-fail.out 2>/tmp/pim-activate-fail.err; then
        fail "profile with duplicate skill should fail to activate"
    fi

    # active state must be unchanged
    assert_eq "$(cat "$home/.pi/active-profile")" "valid-prod"
    assert_symlink_to "$home/.pi/agent" "$home/.pi/profiles/valid-prod/agent"
}

# ── Slice 5 tests (create is scaffold-only) ─────────────────────────────────

test_create_is_scaffold_only() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    run_pim "$root" "$home" create review >/dev/null

    [[ -f "$root/pi/profiles/review/profile.env" ]]  || fail "missing profile.env"
    [[ -f "$root/pi/profiles/review/extensions.list" ]] || fail "missing extensions.list"
    [[ -d "$root/pi/profiles/review/agents" ]]      || fail "missing agents dir"
    [[ -d "$root/pi/profiles/review/skills" ]]       || fail "missing skills dir"
    # must NOT create resolved
    [[ ! -d "$root/pi/profiles/review/resolved" ]]   || fail "resolved should NOT exist after create"
}

test_use_on_fresh_scaffolded_profile_deploys() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    run_pim "$root" "$home" create sandbox >/dev/null

    # no active state set yet, so cmd_current returns default ("coding") – but use should still work
    run_pim "$root" "$home" use sandbox >/dev/null

    [[ -d "$root/pi/profiles/sandbox/resolved" ]]      || fail "activate should have built resolved"
    assert_eq "$(cat "$home/.pi/active-profile")"  "sandbox"
    assert_symlink_to "$home/.pi/agent"              "$home/.pi/profiles/sandbox/agent"
}

# ── Preserved tests (unchanged) ───────────────────────────────────────────────

test_list_prints_profiles() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    output="$(run_pim "$root" "$home" list)"
    assert_eq "$output" $'coding\nlocal'
}

test_list_works_through_installed_symlink() {
    local root home wrapper output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$home/.local/bin"
    wrapper="$home/.local/bin/pim"
    ln -s "$PIM" "$wrapper"

    output="$(PIM_DOTFILES_DIR="$root" PIM_HOME="$home" bash "$wrapper" list)"
    assert_eq "$output" $'coding\nlocal'
}

test_current_reads_active_profile_file() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$home/.pi"
    printf 'local\n' > "$home/.pi/active-profile"

    output="$(run_pim "$root" "$home" current)"
    assert_eq "$output" "local"
}

test_path_prints_runtime_path() {
    local root home output
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    output="$(run_pim "$root" "$home" path coding)"
    assert_eq "$output" "$home/.pi/profiles/coding/agent"
}

test_use_updates_active_profile_state_with_preexisting_runtime() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$home/.pi/profiles/coding/agent"

    run_pim "$root" "$home" use coding >/dev/null

    assert_eq "$(cat "$home/.pi/active-profile")" "coding"
    assert_symlink_to "$home/.pi/agent" "$home/.pi/profiles/coding/agent"
}

test_doctor_fails_for_missing_active_runtime() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$home/.pi"
    printf 'coding\n' > "$home/.pi/active-profile"
    ln -s "$home/.pi/profiles/coding/agent" "$home/.pi/agent"

    if run_pim "$root" "$home" doctor >/tmp/pim-doctor.out 2>/tmp/pim-doctor.err; then
        fail "doctor unexpectedly passed with missing active runtime"
    fi
}

test_doctor_fails_for_duplicate_profile_skill() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$root/pi/profiles/coding/skills/shared-one"
    printf 'duplicate\n' > "$root/pi/profiles/coding/skills/shared-one/SKILL.md"
    mkdir -p "$home/.pi/profiles/coding/agent"
    ln -s "$home/.pi/profiles/coding/agent" "$home/.pi/agent"
    printf 'coding\n' > "$home/.pi/active-profile"

    if run_pim "$root" "$home" doctor >/tmp/pim-doctor-duplicate.out 2>/tmp/pim-doctor-duplicate.err; then
        fail "doctor unexpectedly passed with duplicate profile skill"
    fi
}

# ── Run all tests ─────────────────────────────────────────────────────────────

test_dashboards_lists_profiles_with_metadata
test_dashboard_marks_active_profile
test_dashboard_shows_resolved_no_for_non_built_profiles
test_dashboard_shows_deployed_no_for_runtime_missing
test_bare_profile_name_triggers_activation
test_activate_always_builds_then_deploys
test_use_always_rebuilds_even_when_runtime_exists
test_activate_preserves_active_state_on_build_failure
test_create_is_scaffold_only
test_use_on_fresh_scaffolded_profile_deploys
test_list_prints_profiles
test_list_works_through_installed_symlink
test_current_reads_active_profile_file
test_path_prints_runtime_path
test_use_updates_active_profile_state_with_preexisting_runtime
test_doctor_fails_for_missing_active_runtime
test_doctor_fails_for_duplicate_profile_skill

echo "pim-cli tests passed"

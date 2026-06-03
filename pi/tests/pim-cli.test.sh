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

test_use_updates_active_profile_state() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    mkdir -p "$home/.pi/profiles/coding/agent"

    run_pim "$root" "$home" use coding >/dev/null

    assert_eq "$(cat "$home/.pi/active-profile")" "coding"
    assert_symlink_to "$home/.pi/agent" "$home/.pi/profiles/coding/agent"
}

test_use_deploys_built_profile_when_runtime_is_missing() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    run_pim "$root" "$home" build local >/dev/null

    run_pim "$root" "$home" use local >/dev/null

    assert_eq "$(cat "$home/.pi/active-profile")" "local"
    assert_symlink_to "$home/.pi/agent" "$home/.pi/profiles/local/agent"
    assert_symlink_to "$home/.pi/profiles/local/agent/settings.json" "$root/pi/profiles/local/resolved/settings.json"
    assert_symlink_to "$home/.pi/profiles/local/agent/auth.json" "$home/.pi/auth.json"
}

test_deploy_command_deploys_built_profile() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"
    run_pim "$root" "$home" build coding >/dev/null

    run_pim "$root" "$home" deploy coding >/dev/null

    assert_symlink_to "$home/.pi/profiles/coding/agent/models.json" "$root/pi/profiles/coding/resolved/models.json"
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

test_create_scaffolds_and_builds_profile() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    run_pim "$root" "$home" create review >/dev/null

    [[ -f "$root/pi/profiles/review/profile.env" ]] || fail "missing profile.env"
    [[ -f "$root/pi/profiles/review/extensions.list" ]] || fail "missing extensions.list"
    [[ -L "$root/pi/profiles/review/resolved/settings.json" ]] || fail "missing resolved settings symlink"
    [[ -L "$root/pi/profiles/review/resolved/skills/shared-one" ]] || fail "missing shared skill in resolved output"
}

test_build_command_builds_profile() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    make_repo "$root"

    run_pim "$root" "$home" build coding >/dev/null

    [[ -L "$root/pi/profiles/coding/resolved/extensions/subagent" ]] || fail "missing resolved extension"
}

test_list_prints_profiles
test_list_works_through_installed_symlink
test_current_reads_active_profile_file
test_path_prints_runtime_path
test_use_updates_active_profile_state
test_use_deploys_built_profile_when_runtime_is_missing
test_deploy_command_deploys_built_profile
test_doctor_fails_for_missing_active_runtime
test_doctor_fails_for_duplicate_profile_skill
test_create_scaffolds_and_builds_profile
test_build_command_builds_profile

echo "pim-cli tests passed"

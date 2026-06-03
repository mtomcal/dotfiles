#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$TEST_DIR/../.." && pwd)"
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

assert_contains() {
    local output="$1"
    local expected="$2"
    [[ "$output" == *"$expected"* ]] || fail "expected output to contain <$expected>, got <$output>"
}

setup_runtime() {
    local home="$1"
    local profile="$2"
    mkdir -p "$home/.pi/profiles/$profile/agent/sessions"
    printf '{}\n' > "$home/.pi/profiles/$profile/agent/auth.json"
}

test_bare_pi_uses_active_profile_runtime() {
    local home output
    home="$(new_tmp)"
    setup_runtime "$home" coding
    mkdir -p "$home/.local/bin" "$home/.pi"
    printf 'coding\n' > "$home/.pi/active-profile"
    ln -s "$home/.pi/profiles/coding/agent" "$home/.pi/agent"
    touch "$home/.local/bin/pi-bin"

    output="$(HOME="$home" PIM_DOTFILES_DIR="$DOTFILES_DIR" PI_WRAPPER_DRY_RUN=1 bash "$DOTFILES_DIR/pi/pi.sh")"

    assert_contains "$output" "profile=coding"
    assert_contains "$output" "runtime=$home/.pi/profiles/coding/agent"
    assert_contains "$output" "binary=$home/.local/bin/pi-bin"
}

test_named_pi_uses_profile_runtime_without_changing_active() {
    local home wrapper output
    home="$(new_tmp)"
    setup_runtime "$home" coding
    setup_runtime "$home" local
    mkdir -p "$home/.local/bin" "$home/.pi"
    printf 'coding\n' > "$home/.pi/active-profile"
    ln -s "$home/.pi/profiles/coding/agent" "$home/.pi/agent"
    touch "$home/.local/bin/pi-bin"
    wrapper="$home/.local/bin/pi-local"
    ln -s "$DOTFILES_DIR/pi/pi.sh" "$wrapper"

    output="$(HOME="$home" PIM_DOTFILES_DIR="$DOTFILES_DIR" PI_WRAPPER_DRY_RUN=1 bash "$wrapper")"

    assert_contains "$output" "profile=local"
    assert_contains "$output" "runtime=$home/.pi/profiles/local/agent"
    [[ "$(cat "$home/.pi/active-profile")" == "coding" ]] || fail "named wrapper changed active profile"
    [[ "$(readlink "$home/.pi/agent")" == "$home/.pi/profiles/coding/agent" ]] || fail "named wrapper changed active symlink"
}

test_bare_pis_uses_active_profile_runtime() {
    local home output
    home="$(new_tmp)"
    setup_runtime "$home" coding
    mkdir -p "$home/.pi"
    printf 'coding\n' > "$home/.pi/active-profile"
    ln -s "$home/.pi/profiles/coding/agent" "$home/.pi/agent"

    output="$(HOME="$home" PIM_DOTFILES_DIR="$DOTFILES_DIR" PIS_DRY_RUN=1 bash "$DOTFILES_DIR/pi/pis.sh" --no-rebuild)"

    assert_contains "$output" "profile=coding"
    assert_contains "$output" "runtime=$home/.pi/profiles/coding/agent"
    assert_contains "$output" "$home/.pi/profiles/coding/agent/sessions"
}

test_named_pis_uses_named_profile_runtime() {
    local home wrapper output
    home="$(new_tmp)"
    setup_runtime "$home" coding
    setup_runtime "$home" local
    mkdir -p "$home/.pi"
    printf 'coding\n' > "$home/.pi/active-profile"
    ln -s "$home/.pi/profiles/coding/agent" "$home/.pi/agent"
    wrapper="$home/.local/bin/pis-local"
    mkdir -p "$(dirname "$wrapper")"
    ln -s "$DOTFILES_DIR/pi/pis.sh" "$wrapper"

    output="$(HOME="$home" PIM_DOTFILES_DIR="$DOTFILES_DIR" PIS_DRY_RUN=1 bash "$wrapper" --no-rebuild)"

    assert_contains "$output" "profile=local"
    assert_contains "$output" "runtime=$home/.pi/profiles/local/agent"
    [[ "$(cat "$home/.pi/active-profile")" == "coding" ]] || fail "named pis changed active profile"
}

test_bare_pi_uses_active_profile_runtime
test_named_pi_uses_profile_runtime_without_changing_active
test_bare_pis_uses_active_profile_runtime
test_named_pis_uses_named_profile_runtime

echo "pi-wrappers tests passed"

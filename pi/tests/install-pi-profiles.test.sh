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

assert_symlink_to() {
    local path="$1"
    local target="$2"
    [[ -L "$path" ]] || fail "expected symlink: $path"
    [[ "$(readlink "$path")" == "$target" ]] || fail "expected $path -> $target, got $(readlink "$path")"
}

assert_file_contains() {
    local path="$1"
    local text="$2"
    [[ -f "$path" ]] || fail "expected file: $path"
    [[ "$(cat "$path")" == "$text" ]] || fail "expected $path to contain <$text>, got <$(cat "$path")>"
}

source_install() {
    INSTALL_SH_NO_MAIN=1 source "$DOTFILES_DIR/install.sh"
}

test_deploys_all_committed_profile_outputs() {
    local home runtime
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_profiles

    runtime="$home/.pi/profiles/coding/agent"
    assert_symlink_to "$runtime/settings.json" "$DOTFILES_DIR/pi/profiles/coding/resolved/settings.json"
    assert_symlink_to "$runtime/models.json" "$DOTFILES_DIR/pi/profiles/coding/resolved/models.json"
    assert_symlink_to "$runtime/agents" "$DOTFILES_DIR/pi/profiles/coding/resolved/agents"
    assert_symlink_to "$runtime/skills" "$DOTFILES_DIR/pi/profiles/coding/resolved/skills"
    assert_symlink_to "$runtime/extensions/subagent" "$DOTFILES_DIR/pi/profiles/coding/resolved/extensions/subagent"
    assert_symlink_to "$runtime/extensions/herdr-agent-state" "$DOTFILES_DIR/pi/profiles/coding/resolved/extensions/herdr-agent-state"

    runtime="$home/.pi/profiles/local/agent"
    assert_symlink_to "$runtime/settings.json" "$DOTFILES_DIR/pi/profiles/local/resolved/settings.json"
    assert_symlink_to "$runtime/models.json" "$DOTFILES_DIR/pi/profiles/local/resolved/models.json"
    assert_symlink_to "$runtime/agents" "$DOTFILES_DIR/pi/profiles/local/resolved/agents"
    assert_symlink_to "$runtime/skills" "$DOTFILES_DIR/pi/profiles/local/resolved/skills"
    [[ ! -e "$runtime/extensions/subagent" ]] || fail "local profile should not deploy subagent extension"
    assert_symlink_to "$runtime/extensions/herdr-agent-state" "$DOTFILES_DIR/pi/profiles/local/resolved/extensions/herdr-agent-state"
}

test_sets_active_profile_on_first_install() {
    local home
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_profiles

    assert_file_contains "$home/.pi/active-profile" "coding"
    assert_symlink_to "$home/.pi/agent" "$home/.pi/profiles/coding/agent"
}

test_missing_resolved_output_fails() {
    local root home
    root="$(new_tmp)"
    home="$(new_tmp)"
    mkdir -p "$root/pi/profiles/broken"

    source_install
    if HOME="$home" DOTFILES_DIR="$root" deploy_pi_profiles >/tmp/install-pi.out 2>/tmp/install-pi.err; then
        fail "deploy unexpectedly passed with missing resolved output"
    fi
}

test_deploy_accepts_profile_without_resolved_extensions_dir() {
    local root home runtime
    root="$(new_tmp)"
    home="$(new_tmp)"
    mkdir -p "$root/pi/profiles/local/resolved/agents" "$root/pi/profiles/local/resolved/skills"
    printf '{"settings":true}\n' > "$root/pi/profiles/local/resolved/settings.json"
    printf '{"models":true}\n' > "$root/pi/profiles/local/resolved/models.json"

    source_install
    HOME="$home" prepare_pi_shared_auth
    HOME="$home" DOTFILES_DIR="$root" deploy_pi_profile_runtime local

    runtime="$home/.pi/profiles/local/agent"
    assert_symlink_to "$runtime/settings.json" "$root/pi/profiles/local/resolved/settings.json"
    assert_symlink_to "$runtime/models.json" "$root/pi/profiles/local/resolved/models.json"
    assert_symlink_to "$runtime/agents" "$root/pi/profiles/local/resolved/agents"
    assert_symlink_to "$runtime/skills" "$root/pi/profiles/local/resolved/skills"
    [[ -d "$runtime/extensions" ]] || fail "missing runtime extensions dir"
}

test_reinstall_is_idempotent_for_profile_symlinks() {
    local home before after
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_profiles
    before="$(find "$home/.pi" -maxdepth 4 -type l -print -exec readlink {} \; | sort)"
    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_profiles
    after="$(find "$home/.pi" -maxdepth 4 -type l -print -exec readlink {} \; | sort)"

    [[ "$before" == "$after" ]] || fail "reinstall changed symlink layout"
    [[ -z "$(find "$home/.pi" -name '*.backup.*' -print)" ]] || fail "unexpected backups on idempotent reinstall"
}

test_deploys_profile_wrappers() {
    local home bin
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_profiles
    bin="$home/.local/bin"

    assert_symlink_to "$bin/pim" "$DOTFILES_DIR/pi/pim.sh"
    assert_symlink_to "$bin/pi" "$DOTFILES_DIR/pi/pi.sh"
    assert_symlink_to "$bin/pis" "$DOTFILES_DIR/pi/pis.sh"
    assert_symlink_to "$bin/pi-coding" "$DOTFILES_DIR/pi/pi.sh"
    assert_symlink_to "$bin/pis-coding" "$DOTFILES_DIR/pi/pis.sh"
    assert_symlink_to "$bin/pi-local" "$DOTFILES_DIR/pi/pi.sh"
    assert_symlink_to "$bin/pis-local" "$DOTFILES_DIR/pi/pis.sh"
}

test_profiles_share_auth_but_keep_profile_sessions() {
    local home runtime
    home="$(new_tmp)"
    mkdir -p "$home/.pi"
    printf '{"token":"shared"}\n' > "$home/.pi/auth.json"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_profiles

    runtime="$home/.pi/profiles/coding/agent"
    assert_symlink_to "$runtime/auth.json" "$home/.pi/auth.json"
    [[ -d "$runtime/sessions" ]] || fail "missing profile-local sessions directory"
    [[ ! -L "$runtime/sessions" ]] || fail "sessions must not be shared symlink"
}

test_install_code_has_no_single_profile_pi_source_dependencies() {
    if grep -Eq 'DOTFILES_DIR/pi/(settings\.json|models\.json|agents|skills)' "$DOTFILES_DIR/install.sh"; then
        fail "install.sh still depends on legacy single-profile Pi sources"
    fi
    if grep -Eq '\.pi/agent/(settings\.json|models\.json|skills)' "$DOTFILES_DIR/install.sh"; then
        fail "install.sh still deploys direct single-profile Pi agent paths"
    fi
}

test_deploys_all_committed_profile_outputs
test_sets_active_profile_on_first_install
test_missing_resolved_output_fails
test_deploy_accepts_profile_without_resolved_extensions_dir
test_reinstall_is_idempotent_for_profile_symlinks
test_deploys_profile_wrappers
test_profiles_share_auth_but_keep_profile_sessions
test_install_code_has_no_single_profile_pi_source_dependencies

echo "install-pi-profiles tests passed"

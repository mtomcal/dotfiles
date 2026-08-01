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

assert_absent() {
    local path="$1"
    [[ ! -e "$path" && ! -L "$path" ]] || fail "expected path to be absent: $path"
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

test_deploys_pi_config_with_local_settings() {
    local home agent
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_config

    agent="$home/.pi/agent"
    [[ -d "$agent" ]] || fail "missing Pi agent dir"
    assert_file_contains "$agent/settings.json" "{}"
    [[ ! -L "$agent/settings.json" ]] || fail "settings.json must be local state, not a symlink"
    assert_symlink_to "$agent/models.json" "$DOTFILES_DIR/pi/models.json"
    assert_symlink_to "$agent/skills" "$DOTFILES_DIR/pi/skills"
    assert_symlink_to "$agent/extensions/herdr-agent-state.ts" "$DOTFILES_DIR/pi/extensions/herdr-agent-state.ts"
    assert_absent "$agent/extensions/herdr-agent-state"
    assert_symlink_to "$agent/extensions/inherit-last-model" "$DOTFILES_DIR/pi/extensions/inherit-last-model"
    assert_symlink_to "$agent/extensions/web-search" "$DOTFILES_DIR/pi/extensions/web-search"
    assert_absent "$agent/extensions/subagent"
    [[ -d "$agent/sessions" ]] || fail "missing sessions dir"
    [[ ! -L "$agent/sessions" ]] || fail "sessions must be local state, not a symlink"
    assert_file_contains "$agent/auth.json" "{}"
    [[ ! -L "$agent/auth.json" ]] || fail "auth.json must be local state, not a symlink"
}

test_deploy_migrates_managed_settings_to_local_state() {
    local home agent legacy_settings before after
    home="$(new_tmp)"
    source_install

    agent="$home/.pi/agent"
    legacy_settings="$(new_tmp)/settings.json"
    printf '{"local":true}\n' > "$legacy_settings"
    mkdir -p "$agent"
    ln -s "$legacy_settings" "$agent/settings.json"
    before="$(cat "$agent/settings.json")"

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_config

    [[ ! -L "$agent/settings.json" ]] || fail "settings.json must be migrated from a symlink"
    after="$(cat "$agent/settings.json")"
    [[ "$after" == "$before" ]] || fail "settings migration did not preserve existing settings"
}

test_deploy_prunes_stale_extension_symlinks() {
    local home agent stale_target
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_config
    agent="$home/.pi/agent"
    stale_target="$DOTFILES_DIR/pi/extensions/subagent"
    ln -s "$stale_target" "$agent/extensions/subagent"

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_config

    assert_absent "$agent/extensions/subagent"
}

test_reinstall_is_idempotent_for_pi_config_symlinks() {
    local home before after
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_config
    before="$(find "$home/.pi" -maxdepth 4 -type l -print -exec readlink {} \; | sort)"
    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_config
    after="$(find "$home/.pi" -maxdepth 4 -type l -print -exec readlink {} \; | sort)"

    [[ "$before" == "$after" ]] || fail "reinstall changed symlink layout"
    [[ -z "$(find "$home/.pi" -name '*.backup.*' -print)" ]] || fail "unexpected backups on idempotent reinstall"
}

test_deploys_pi_wrappers_only() {
    local home bin
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" deploy_pi_wrappers
    bin="$home/.local/bin"

    assert_symlink_to "$bin/pi" "$DOTFILES_DIR/pi/pi.sh"
    assert_symlink_to "$bin/pis" "$DOTFILES_DIR/pi/pis.sh"
    assert_absent "$bin/pim"
    assert_absent "$bin/pi-coding"
    assert_absent "$bin/pis-coding"
}

test_install_code_has_no_profile_or_subagent_dependencies() {
    if grep -Eq 'deploy_pi_profiles|deploy_pi_profile_runtime|pim\.sh|active-profile|\.pi/profiles|pi/profiles|pi/base|pi/agents|extensions/subagent' "$DOTFILES_DIR/install.sh"; then
        fail "install.sh still depends on removed Pi profile or subagent surfaces"
    fi
}

test_deploys_pi_config_with_local_settings
test_deploy_migrates_managed_settings_to_local_state
test_deploy_prunes_stale_extension_symlinks
test_reinstall_is_idempotent_for_pi_config_symlinks
test_deploys_pi_wrappers_only
test_install_code_has_no_profile_or_subagent_dependencies

echo "install-pi tests passed"

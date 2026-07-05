#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$TEST_DIR/../.." && pwd)"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_exists() {
    [[ -e "$1" || -L "$1" ]] || fail "expected path to exist: $1"
}

assert_same_target_or_content() {
    local actual="$1"
    local expected="$2"
    assert_exists "$actual"
    if [[ -L "$actual" ]]; then
        local resolved
        resolved="$(cd "$(dirname "$actual")" && realpath "$(readlink "$actual")")"
        cmp -s "$resolved" "$expected" || fail "expected $actual target content to match $expected"
    else
        cmp -s "$actual" "$expected" || fail "expected $actual content to match $expected"
    fi
}

assert_resolved_contains_dir_entries() {
    local resolved_dir="$1"
    local source_dir="$2"
    local entry name
    for entry in "$source_dir"/*; do
        [[ -e "$entry" || -L "$entry" ]] || continue
        name="$(basename "$entry")"
        assert_exists "$resolved_dir/$name"
    done
}

test_coding_profile_has_resolved_runtime_outputs() {
    local resolved="$DOTFILES_DIR/pi/profiles/coding/resolved"

    assert_same_target_or_content "$resolved/settings.json" "$DOTFILES_DIR/pi/settings.json"
    assert_same_target_or_content "$resolved/models.json" "$DOTFILES_DIR/pi/models.json"
    assert_exists "$resolved/agents"
    assert_exists "$resolved/skills"
    assert_exists "$resolved/extensions"
}

test_coding_profile_includes_current_agents() {
    assert_resolved_contains_dir_entries "$DOTFILES_DIR/pi/profiles/coding/resolved/agents" "$DOTFILES_DIR/pi/agents"
}

test_coding_profile_includes_shared_and_pi_only_skills() {
    local resolved="$DOTFILES_DIR/pi/profiles/coding/resolved/skills"
    assert_resolved_contains_dir_entries "$resolved" "$DOTFILES_DIR/shared/skills"

    local skill name
    for skill in "$DOTFILES_DIR/pi/skills"/*; do
        [[ -d "$skill" && ! -L "$skill" ]] || continue
        name="$(basename "$skill")"
        assert_exists "$resolved/$name"
    done
}

test_coding_profile_enables_current_extensions() {
    local resolved="$DOTFILES_DIR/pi/profiles/coding/resolved/extensions"
    assert_exists "$resolved/subagent"
    assert_exists "$resolved/web-search"
    assert_exists "$resolved/inherit-last-model"
    assert_exists "$resolved/herdr-agent-state"
}

test_local_profile_uses_profile_specific_runtime_inputs() {
    local resolved="$DOTFILES_DIR/pi/profiles/local/resolved"

    assert_same_target_or_content "$resolved/settings.json" "$DOTFILES_DIR/pi/profiles/local/settings.json"
    assert_same_target_or_content "$resolved/models.json" "$DOTFILES_DIR/pi/profiles/local/models.json"
    assert_exists "$resolved/agents"
    assert_exists "$resolved/skills"
}

test_local_profile_enables_only_herdr_extension() {
    local resolved="$DOTFILES_DIR/pi/profiles/local/resolved/extensions"
    assert_exists "$resolved/herdr-agent-state"
    [[ ! -e "$resolved/subagent" ]] || fail "local profile should not enable subagent extension"
    [[ ! -e "$resolved/web-search" ]] || fail "local profile should not enable web-search extension"
    [[ ! -e "$resolved/inherit-last-model" ]] || fail "local profile should not enable inherit-last-model extension"
}

test_legacy_single_profile_sources_are_retained_for_compatibility() {
    assert_exists "$DOTFILES_DIR/pi/settings.json"
    assert_exists "$DOTFILES_DIR/pi/models.json"
    assert_exists "$DOTFILES_DIR/pi/agents"
    assert_exists "$DOTFILES_DIR/pi/skills"
}

test_coding_profile_has_resolved_runtime_outputs
test_coding_profile_includes_current_agents
test_coding_profile_includes_shared_and_pi_only_skills
test_coding_profile_enables_current_extensions
test_local_profile_uses_profile_specific_runtime_inputs
test_local_profile_enables_only_herdr_extension
test_legacy_single_profile_sources_are_retained_for_compatibility

echo "profile-layout tests passed"

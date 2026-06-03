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

assert_exists() {
    [[ -e "$1" || -L "$1" ]] || fail "expected path to exist: $1"
}

assert_symlink_to() {
    local path="$1"
    local target="$2"
    [[ -L "$path" ]] || fail "expected symlink: $path"
    local resolved expected
    resolved="$(cd "$(dirname "$path")" && realpath "$(readlink "$path")")"
    expected="$(realpath "$target")"
    [[ "$resolved" == "$expected" ]] || fail "expected $path to resolve to $expected, got $resolved"
    [[ "$(readlink "$path")" != /* ]] || fail "expected relative symlink target for $path, got $(readlink "$path")"
}

assert_not_contains() {
    local path="$1"
    local unexpected="$2"
    [[ ! -e "$path" ]] || ! grep -q "$unexpected" "$path" || fail "expected $path not to contain $unexpected"
}

make_repo() {
    local root="$1"
    mkdir -p "$root/pi/base/agents" "$root/pi/extensions/subagent" "$root/pi/extensions/web-search"
    mkdir -p "$root/pi/profiles/coding/skills/local-only"
    mkdir -p "$root/shared/skills/shared-one"

    printf '{"base":true}\n' > "$root/pi/base/settings.json"
    printf '{"models":true}\n' > "$root/pi/base/models.json"
    printf 'agent\n' > "$root/pi/base/agents/implementer.md"
    printf 'shared\n' > "$root/shared/skills/shared-one/SKILL.md"
    printf 'local\n' > "$root/pi/profiles/coding/skills/local-only/SKILL.md"
    printf 'subagent\nweb-search\n' > "$root/pi/profiles/coding/extensions.list"
    printf 'extension\n' > "$root/pi/extensions/subagent/index.ts"
    printf 'extension\n' > "$root/pi/extensions/web-search/index.ts"
}

new_tmp() {
    local tmp
    tmp="$(mktemp -d)"
    TMP_DIRS+=("$tmp")
    printf '%s\n' "$tmp"
}

test_build_profile_creates_resolved_output() {
    local tmp
    tmp="$(new_tmp)"
    make_repo "$tmp"

    # shellcheck source=/dev/null
    source "$DOTFILES_DIR/pi/lib/pim.sh"
    PIM_DOTFILES_DIR="$tmp" pim_build_profile coding

    local resolved="$tmp/pi/profiles/coding/resolved"
    assert_symlink_to "$resolved/settings.json" "$tmp/pi/base/settings.json"
    assert_symlink_to "$resolved/models.json" "$tmp/pi/base/models.json"
    assert_symlink_to "$resolved/agents/implementer.md" "$tmp/pi/base/agents/implementer.md"
    assert_symlink_to "$resolved/skills/shared-one" "$tmp/shared/skills/shared-one"
    assert_symlink_to "$resolved/skills/local-only" "$tmp/pi/profiles/coding/skills/local-only"
    assert_symlink_to "$resolved/extensions/subagent" "$tmp/pi/extensions/subagent"
    assert_symlink_to "$resolved/extensions/web-search" "$tmp/pi/extensions/web-search"
}

test_duplicate_profile_skill_fails_and_preserves_old_resolved() {
    local tmp
    tmp="$(new_tmp)"
    make_repo "$tmp"
    mkdir -p "$tmp/pi/profiles/coding/resolved"
    printf 'keep-me\n' > "$tmp/pi/profiles/coding/resolved/sentinel.txt"
    mkdir -p "$tmp/pi/profiles/coding/skills/shared-one"
    printf 'duplicate\n' > "$tmp/pi/profiles/coding/skills/shared-one/SKILL.md"

    # shellcheck source=/dev/null
    source "$DOTFILES_DIR/pi/lib/pim.sh"
    if PIM_DOTFILES_DIR="$tmp" pim_build_profile coding >/tmp/pim-build.out 2>/tmp/pim-build.err; then
        fail "duplicate skill build unexpectedly succeeded"
    fi

    assert_exists "$tmp/pi/profiles/coding/resolved/sentinel.txt"
}

test_profile_settings_override_wins() {
    local tmp
    tmp="$(new_tmp)"
    make_repo "$tmp"
    printf '{"profile":true}\n' > "$tmp/pi/profiles/coding/settings.json"

    # shellcheck source=/dev/null
    source "$DOTFILES_DIR/pi/lib/pim.sh"
    PIM_DOTFILES_DIR="$tmp" pim_build_profile coding

    assert_symlink_to "$tmp/pi/profiles/coding/resolved/settings.json" "$tmp/pi/profiles/coding/settings.json"
}

test_extensions_list_limits_resolved_extensions() {
    local tmp
    tmp="$(new_tmp)"
    make_repo "$tmp"
    printf 'subagent\n' > "$tmp/pi/profiles/coding/extensions.list"

    # shellcheck source=/dev/null
    source "$DOTFILES_DIR/pi/lib/pim.sh"
    PIM_DOTFILES_DIR="$tmp" pim_build_profile coding

    assert_symlink_to "$tmp/pi/profiles/coding/resolved/extensions/subagent" "$tmp/pi/extensions/subagent"
    [[ ! -e "$tmp/pi/profiles/coding/resolved/extensions/web-search" ]] || fail "unexpected web-search extension"
}

test_build_profile_creates_resolved_output
test_duplicate_profile_skill_fails_and_preserves_old_resolved
test_profile_settings_override_wins
test_extensions_list_limits_resolved_extensions

echo "pim-build tests passed"

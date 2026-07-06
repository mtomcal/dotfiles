#!/usr/bin/env bash

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
DOTFILES_DIR="$(cd "$TEST_DIR/.." && pwd)"
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

source_install() {
    INSTALL_SH_NO_MAIN=1 source "$DOTFILES_DIR/install.sh"
}

run_tests() {
    local suite_name="${1:-tests}"
    local test_name
    local count=0

    while IFS= read -r test_name; do
        "$test_name"
        count=$((count + 1))
        printf 'ok - %s\n' "$test_name"
    done < <(declare -F | awk '{ print $3 }' | grep '^test_' | sort)

    printf '%s passed (%d tests)\n' "$suite_name" "$count"
}

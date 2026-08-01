#!/usr/bin/env bash

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
DOTFILES_DIR="$(cd "$TEST_DIR/.." && pwd)"

# One disposable root per test process. Every temporary artifact lives under
# it, so cleanup never depends on a caller registering individual paths.
SUITE_TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tests.XXXXXX")"
SUITE_TMP_SEQUENCE=0

cleanup() {
    if [[ -n "${SUITE_TMP_ROOT:-}" && -d "$SUITE_TMP_ROOT" ]]; then
        rm -rf "$SUITE_TMP_ROOT"
    fi
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Allocate a disposable directory and assign it to the caller's variable:
#
#     local home
#     new_tmp_var home
#
# Assignment happens in the calling shell instead of through command
# substitution, so allocation and cleanup ownership stay in one process.
new_tmp_var() {
    local __new_tmp_var_name="$1"
    local __new_tmp_var_dir

    SUITE_TMP_SEQUENCE=$((SUITE_TMP_SEQUENCE + 1))
    __new_tmp_var_dir="$SUITE_TMP_ROOT/dir-$SUITE_TMP_SEQUENCE"
    mkdir -p "$__new_tmp_var_dir"
    printf -v "$__new_tmp_var_name" '%s' "$__new_tmp_var_dir"
}

# Path for a named scratch artifact (captured output, logs) under the suite
# root. Tests use this instead of a fixed /tmp path.
tmp_artifact() {
    printf '%s/%s' "$SUITE_TMP_ROOT" "$1"
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

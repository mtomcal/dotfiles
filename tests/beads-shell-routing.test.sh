#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

# BR-SHELL-017: on startup the shell exports BEADS_DIR only when the local
# bootstrap config names an absolute, existing .beads directory. Every other
# case must leave BEADS_DIR unset without erroring, so a machine that never
# ran bootstrap still gets an ordinary shell.
#
# The routing block is sourced out of the tracked zsh config so the test
# exercises the deployed text rather than a copy of it.
route_with() {
    local config_path="$1"

    (
        set +u
        unset BEADS_DIR
        BEADS_COMMAND_CONFIG_PATH="$config_path"
        # shellcheck disable=SC1090
        source <(awk '/# BEADS-ROUTING-START/,/# BEADS-ROUTING-END/' \
            "$DOTFILES_DIR/zsh/.zshrc.custom")
        printf '%s' "${BEADS_DIR:-}"
    )
}

write_config() {
    printf 'BEADS_DIR=%s\n' "$2" >"$1"
}

test_valid_config_exports_beads_dir() {
    local home
    new_tmp_var home
    mkdir -p "$home/command/.beads"
    write_config "$home/env" "$home/command/.beads"

    local routed
    routed="$(route_with "$home/env")"
    [[ "$routed" == "$home/command/.beads" ]] \
        || fail "expected BEADS_DIR=$home/command/.beads, got '$routed'"
}

test_absent_config_leaves_beads_dir_unset() {
    local home
    new_tmp_var home

    local routed
    routed="$(route_with "$home/nonexistent")"
    [[ -z "$routed" ]] || fail "expected no BEADS_DIR, got '$routed'"
}

test_config_naming_missing_directory_is_ignored() {
    local home
    new_tmp_var home
    write_config "$home/env" "$home/command/.beads"

    local routed
    routed="$(route_with "$home/env")"
    [[ -z "$routed" ]] || fail "stale path must not be exported, got '$routed'"
}

test_relative_path_is_ignored() {
    local home
    new_tmp_var home
    mkdir -p "$home/command/.beads"
    write_config "$home/env" "command/.beads"

    local routed
    routed="$(route_with "$home/env")"
    [[ -z "$routed" ]] || fail "relative path must not be exported, got '$routed'"
}

test_malformed_config_is_ignored() {
    local home
    new_tmp_var home
    printf 'this is not a config\n' >"$home/env"

    local routed
    routed="$(route_with "$home/env")"
    [[ -z "$routed" ]] || fail "malformed config must not export, got '$routed'"
}

# A missing or broken bootstrap must never make the shell noisy.
test_routing_is_silent_in_every_case() {
    local home
    new_tmp_var home
    mkdir -p "$home/ok/.beads"
    write_config "$home/valid" "$home/ok/.beads"
    write_config "$home/stale" "$home/gone/.beads"
    printf 'garbage\n' >"$home/malformed"

    local config
    for config in "$home/valid" "$home/stale" "$home/malformed" "$home/absent"; do
        local output
        output="$(route_with "$config" 2>&1 >/dev/null)"
        [[ -z "$output" ]] \
            || fail "routing emitted output for $(basename "$config"): $output"
    done
}

run_tests "beads-shell-routing"

#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

# --- version floor -----------------------------------------------------------

test_beads_version_meets_requirement_accepts_minimum_and_newer() {
    source_install

    beads_version_meets_requirement "0.59.0" || fail "exact minimum should pass"
    beads_version_meets_requirement "0.59.1" || fail "patch above minimum should pass"
    beads_version_meets_requirement "1.1.2" || fail "released 1.x should pass"
    beads_version_meets_requirement "0.100.0" || fail "0.100 must sort above 0.59, not below"
}

test_beads_version_meets_requirement_rejects_older() {
    source_install

    ! beads_version_meets_requirement "0.58.9" || fail "below minimum should fail"
    ! beads_version_meets_requirement "0.9.0" || fail "0.9 must sort below 0.59"
    ! beads_version_meets_requirement "" || fail "empty version should fail"
}

test_beads_reported_version_parses_installer_output() {
    local bin
    new_tmp_var bin

    source_install

    cat >"$bin/bd" <<'STUB'
#!/usr/bin/env bash
echo "bd version 1.1.2 (20e493e56: HEAD@20e493e569c9)"
STUB
    chmod +x "$bin/bd"

    local parsed
    parsed="$(beads_reported_version "$bin/bd")"
    [[ "$parsed" == "1.1.2" ]] || fail "expected 1.1.2, got '$parsed'"
}

# --- embedded capability -----------------------------------------------------
#
# A CGO_ENABLED=0 build is server-mode-only: it cannot use embedded Dolt and
# fails at first `bd init` rather than at install time. Detect it up front.

test_beads_binary_is_embedded_capable_rejects_nocgo_build() {
    local bin
    new_tmp_var bin

    source_install

    printf 'build\tCGO_ENABLED=0\n' >"$bin/bd"
    chmod +x "$bin/bd"

    ! beads_binary_is_embedded_capable "$bin/bd" \
        || fail "a CGO_ENABLED=0 binary must be rejected"
}

test_beads_binary_is_embedded_capable_accepts_release_build() {
    local bin
    new_tmp_var bin

    source_install

    printf 'build\tCGO_ENABLED=1\nsome other build metadata\n' >"$bin/bd"
    chmod +x "$bin/bd"

    beads_binary_is_embedded_capable "$bin/bd" \
        || fail "an embedded-capable binary must be accepted"
}

test_beads_binary_is_embedded_capable_reports_missing_binary() {
    local bin
    new_tmp_var bin

    source_install

    ! beads_binary_is_embedded_capable "$bin/absent" \
        || fail "a missing binary must not report embedded capability"
}

# --- profile and dependency wiring -------------------------------------------

select_profile() {
    local profile="$1"

    parse_arguments --profile "$profile"
    SELECTED_MODULES=($(expand_profile "$profile"))
}

test_full_and_work_profiles_include_beads() {
    local os
    local profile

    source_install

    for os in ubuntu macos; do
        OS="$os"
        for profile in full work; do
            SELECTED_MODULES=()
            select_profile "$profile"
            [[ " ${SELECTED_MODULES[*]} " == *" beads "* ]] \
                || fail "$os $profile profile missing beads"
        done
    done
}

test_minimal_profile_omits_beads() {
    local os

    source_install

    for os in ubuntu macos; do
        OS="$os"
        SELECTED_MODULES=()
        select_profile minimal
        [[ " ${SELECTED_MODULES[*]} " != *" beads "* ]] \
            || fail "$os minimal profile must omit beads"
    done
}

# Embedded storage links Dolt into the bd binary, so no profile may select a
# separate dolt module.
test_no_profile_selects_a_dolt_module() {
    local os
    local profile

    source_install

    for os in ubuntu macos; do
        OS="$os"
        for profile in full work minimal; do
            SELECTED_MODULES=()
            select_profile "$profile"
            [[ " ${SELECTED_MODULES[*]} " != *" dolt "* ]] \
                || fail "$os $profile profile must not select dolt"
        done
    done
}

test_beads_module_resolves_without_dolt() {
    local resolved

    source_install
    OS="ubuntu"

    resolved="$(resolve_dependencies beads)"
    [[ " $resolved " == *" beads "* ]] || fail "beads missing from resolution"
    [[ " $resolved " != *" dolt "* ]] || fail "beads must not resolve a dolt module"
}

run_tests "install-beads"

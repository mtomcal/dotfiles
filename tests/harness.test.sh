#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/bash32.sh"

# Write a disposable child suite that records its own temporary root, then
# either passes or fails, so cleanup can be observed from outside.
write_child_suite() {
    local path="$1"
    local outcome="$2"

    cat > "$path" << EOF
#!/usr/bin/env bash
set -euo pipefail

source "$TEST_DIR/lib/harness.sh"

test_child_allocates_temporary_state() {
    local scratch
    new_tmp_var scratch
    printf '%s\n' "\$SUITE_TMP_ROOT" > "$CHILD_ROOT_RECORD"
    printf 'artifact\n' > "\$scratch/artifact"
    printf 'artifact\n' > "\$(tmp_artifact child.out)"
    if [ "$outcome" == "fail" ]; then
        fail "deliberate child failure"
    fi
}

run_tests "child suite"
EOF
}

test_harness_removes_its_temporary_root_after_a_passing_suite() {
    local work
    local child_root

    new_tmp_var work
    CHILD_ROOT_RECORD="$work/root-path"
    write_child_suite "$work/child.test.sh" pass

    bash "$work/child.test.sh" > "$work/child.out" 2>&1 ||
        fail "expected the child suite to pass: $(cat "$work/child.out")"

    child_root="$(cat "$CHILD_ROOT_RECORD")"
    [[ -n "$child_root" ]] || fail "child suite recorded no temporary root"
    [[ ! -e "$child_root" ]] || fail "passing suite leaked its temporary root: $child_root"
}

test_harness_removes_its_temporary_root_after_a_failing_suite() {
    local work
    local child_root
    local status=0

    new_tmp_var work
    CHILD_ROOT_RECORD="$work/root-path"
    write_child_suite "$work/child.test.sh" fail

    bash "$work/child.test.sh" > "$work/child.out" 2>&1 || status=$?

    [[ "$status" -ne 0 ]] || fail "expected the child suite to fail"
    child_root="$(cat "$CHILD_ROOT_RECORD")"
    [[ -n "$child_root" ]] || fail "child suite recorded no temporary root"
    [[ ! -e "$child_root" ]] || fail "failing suite leaked its temporary root: $child_root"
}

test_temporary_directories_are_assigned_in_the_calling_shell() {
    local first
    local second

    new_tmp_var first
    new_tmp_var second

    [[ -d "$first" && -d "$second" ]] || fail "expected both temporary directories to exist"
    [[ "$first" != "$second" ]] || fail "expected distinct temporary directories"
    [[ "$first" == "$SUITE_TMP_ROOT"/* ]] || fail "temporary directory outside the suite root: $first"
    [[ "$(tmp_artifact scratch.log)" == "$SUITE_TMP_ROOT"/* ]] ||
        fail "artifact path outside the suite root"
}

test_no_test_file_writes_to_a_fixed_temporary_path() {
    local offenders
    # Built at runtime so this guard cannot match its own source line.
    local pattern='/tm''p/[A-Za-z0-9_][A-Za-z0-9_.-]*'

    offenders="$(grep -nE "$pattern" "$TEST_DIR"/*.test.sh "$TEST_DIR"/lib/*.sh || true)"
    [[ -z "$offenders" ]] || fail "fixed /tmp artifacts remain:
$offenders"
}

test_bash32_guard_flags_known_post_3_2_constructs() {
    local work
    local violations
    local construct

    new_tmp_var work

    local constructs=()
    constructs+=('declare -A registry')                    # bash32-guard: allow
    constructs+=('local -A registry')                      # bash32-guard: allow
    constructs+=('typeset -A registry')                    # bash32-guard: allow
    constructs+=('mapfile -t lines < input')               # bash32-guard: allow
    constructs+=('readarray -t lines < input')             # bash32-guard: allow
    constructs+=('printf "%s" "${name^^}"')                # bash32-guard: allow
    constructs+=('printf "%s" "${name,,}"')                # bash32-guard: allow
    constructs+=('case $x in a) run ;;& b) run ;; esac')   # bash32-guard: allow
    constructs+=('coproc reader { cat; }')                 # bash32-guard: allow
    constructs+=('echo hi &>> log')                        # bash32-guard: allow
    constructs+=('if [[ -v name ]]; then :; fi')           # bash32-guard: allow

    for construct in "${constructs[@]}"; do
        printf '#!/bin/bash\n%s\n' "$construct" > "$work/candidate.sh"
        violations="$(bash32_violations "$work/candidate.sh" || true)"
        [[ -n "$violations" ]] || fail "guard missed a post-3.2 construct: $construct"
    done
}

test_bash32_guard_accepts_the_shipped_shell_sources() {
    local violations

    violations="$(bash32_violations "$DOTFILES_DIR/install.sh" "$TEST_DIR"/*.test.sh "$TEST_DIR"/lib/*.sh || true)"
    [[ -z "$violations" ]] || fail "shipped shell sources use post-3.2 constructs:
$violations"
}

run_tests "harness"

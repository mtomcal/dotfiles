#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

# Tree snapshots are compared line by line, so ordering must not depend on
# the host's collation.
export LC_ALL=C

# The managed sources the deployment is allowed to own, named once so the
# tests assert against canonical repository paths instead of restating them.
MANAGED_SETTINGS="$DOTFILES_DIR/vscode/settings.json"
MANAGED_KEYBINDINGS="$DOTFILES_DIR/vscode/keybindings.json"
MANAGED_SNIPPETS="$DOTFILES_DIR/vscode/snippets"

# Run the public deployment helper against a caller-selected User directory.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   exit status of deploy_vscode_managed_layer
#   OBSERVED_OUTPUT   combined stdout/stderr of the call
run_deploy() {
    local user_dir="$1"
    local out

    source_install

    out="$(tmp_artifact "deploy.out")"
    OBSERVED_STATUS=0
    deploy_vscode_managed_layer "$user_dir" > "$out" 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_OUTPUT="$(cat "$out")"
}

# One stable line per entry under a directory tree, recording entry type,
# symlink target, and file content. Comparing two snapshots is the evidence
# that a tree was — or was not — touched.
tree_snapshot() {
    local root="$1"
    local entry

    (
        cd "$root" || exit 1
        find . | sort | while IFS= read -r entry; do
            if [ -L "$entry" ]; then
                printf 'link %s -> %s\n' "$entry" "$(readlink "$entry")"
            elif [ -d "$entry" ]; then
                printf 'dir  %s\n' "$entry"
            else
                printf 'file %s :: %s\n' "$entry" "$(cat "$entry")"
            fi
        done
    )
}

# Run the helper with one deployment step forced to fail, recording the
# ordered dependency calls it made.
#
# $2 selects the failing step: mkdir, settings, keybindings, snippets, or
# none. Every call is logged before the injected failure, so the log shows
# both what ran and what never started.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   exit status of deploy_vscode_managed_layer
#   OBSERVED_CALLS    ordered dependency calls, one per line
run_deploy_injecting_failure() {
    local user_dir="$1"
    local failing="$2"
    local log

    source_install

    SUITE_TMP_SEQUENCE=$((SUITE_TMP_SEQUENCE + 1))
    log="$(tmp_artifact "calls-$SUITE_TMP_SEQUENCE.log")"
    : > "$log"

    OBSERVED_STATUS=0
    (
        mkdir() {
            printf 'mkdir %s\n' "$*" >> "$log"
            [ "$failing" != "mkdir" ] || return 1
            command mkdir "$@"
        }

        replace_symlink() {
            printf 'replace_symlink %s -> %s\n' "$1" "$2" >> "$log"
            case "$failing" in
                settings) [ "${2##*/}" != "settings.json" ] || return 1 ;;
                keybindings) [ "${2##*/}" != "keybindings.json" ] || return 1 ;;
                snippets) [ "${2##*/}" != "snippets" ] || return 1 ;;
            esac
            return 0
        }

        deploy_vscode_managed_layer "$user_dir"
    ) > /dev/null 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_CALLS="$(cat "$log")"
}

# Run the helper again with the destructive filesystem commands recorded.
# An idempotent rerun must not unlink, relink, or back up anything, so the
# absence of these calls — not just an unchanged final tree — is the
# evidence.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   exit status of deploy_vscode_managed_layer
#   OBSERVED_CALLS    recorded rm/ln/mv calls, empty when none happened
rerun_deployment_recording_mutations() {
    local user_dir="$1"
    local log

    source_install

    SUITE_TMP_SEQUENCE=$((SUITE_TMP_SEQUENCE + 1))
    log="$(tmp_artifact "mutations-$SUITE_TMP_SEQUENCE.log")"
    : > "$log"

    OBSERVED_STATUS=0
    (
        rm() {
            printf 'rm %s\n' "$*" >> "$log"
            command rm "$@"
        }

        ln() {
            printf 'ln %s\n' "$*" >> "$log"
            command ln "$@"
        }

        mv() {
            printf 'mv %s\n' "$*" >> "$log"
            command mv "$@"
        }

        deploy_vscode_managed_layer "$user_dir"
    ) > /dev/null 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_CALLS="$(cat "$log")"
}

assert_regular_directory() {
    local path="$1"
    local label="$2"

    [[ ! -L "$path" ]] || fail "$label is a symlink: $path -> $(readlink "$path")"
    [[ -d "$path" ]] || fail "$label is not a directory: $path"
}

# ---------------------------------------------------------------------------
# Cycle A — whole-directory guard and regular container
# ---------------------------------------------------------------------------

test_symlinked_user_directory_is_rejected_before_any_child_mutation() {
    local work
    local before
    local after

    new_tmp_var work
    mkdir -p "$work/elsewhere"
    printf '{"editor.fontSize": 15}\n' > "$work/elsewhere/settings.json"
    ln -s "$work/elsewhere" "$work/User"

    before="$(tree_snapshot "$work/elsewhere")"
    run_deploy "$work/User"
    after="$(tree_snapshot "$work/elsewhere")"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected rejection of a symlinked User directory, got status 0"
    [[ -L "$work/User" ]] || fail "expected the User symlink to be left in place"
    [[ "$(readlink "$work/User")" == "$work/elsewhere" ]] || fail "User symlink was retargeted"
    [[ "$before" == "$after" ]] || fail "linked User directory was mutated:
$(diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") || true)"
}

test_absent_user_directory_is_created_as_a_regular_directory() {
    local work

    new_tmp_var work

    run_deploy "$work/Application Support/Code/User"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected deployment to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_regular_directory "$work/Application Support/Code/User" "created User directory"
}

# ---------------------------------------------------------------------------
# Cycle B — exactly three managed mappings to canonical sources
# ---------------------------------------------------------------------------

test_managed_children_link_to_the_canonical_repository_sources() {
    local work

    new_tmp_var work

    run_deploy "$work/User"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected deployment to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_symlink_to "$work/User/settings.json" "$MANAGED_SETTINGS"
    assert_symlink_to "$work/User/keybindings.json" "$MANAGED_KEYBINDINGS"
    assert_symlink_to "$work/User/snippets" "$MANAGED_SNIPPETS"
    [[ -f "$work/User/settings.json" ]] || fail "settings link does not resolve to a file"
    [[ -f "$work/User/keybindings.json" ]] || fail "keybindings link does not resolve to a file"
    [[ -d "$work/User/snippets" ]] || fail "snippets link does not resolve to a directory"
}

test_deployment_owns_no_user_child_beyond_the_three_managed_mappings() {
    local work
    local before
    local after

    new_tmp_var work
    mkdir -p "$work/User/globalStorage" "$work/User/workspaceStorage/abc" "$work/User/History"
    printf 'sqlite\n' > "$work/User/globalStorage/state.vscdb"
    printf 'workspace\n' > "$work/User/workspaceStorage/abc/workspace.json"
    printf 'edit\n' > "$work/User/History/entry"
    printf 'sync\n' > "$work/User/syncMachines.json"

    before="$(tree_snapshot "$work/User")"
    run_deploy "$work/User"
    after="$(tree_snapshot "$work/User")"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected deployment to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_regular_directory "$work/User" "User directory"

    local expected_added="link ./keybindings.json -> $MANAGED_KEYBINDINGS
link ./settings.json -> $MANAGED_SETTINGS
link ./snippets -> $MANAGED_SNIPPETS"
    local actual_added
    actual_added="$(comm -13 <(printf "%s\n" "$before" | sort) <(printf "%s\n" "$after" | sort))"

    [[ "$actual_added" == "$expected_added" ]] || fail "deployment changed more than the three managed children:
$actual_added"
    [[ -z "$(comm -23 <(printf "%s\n" "$before" | sort) <(printf "%s\n" "$after" | sort))" ]] || fail "deployment removed unrelated User state:
$(comm -23 <(printf "%s\n" "$before" | sort) <(printf "%s\n" "$after" | sort))"
}

test_deployment_performs_the_ordered_steps_exactly_once_each() {
    local work

    new_tmp_var work

    run_deploy_injecting_failure "$work/User" none

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected deployment to succeed, got status $OBSERVED_STATUS"
    [[ "$OBSERVED_CALLS" == "mkdir -p $work/User
replace_symlink $MANAGED_SETTINGS -> $work/User/settings.json
replace_symlink $MANAGED_KEYBINDINGS -> $work/User/keybindings.json
replace_symlink $MANAGED_SNIPPETS -> $work/User/snippets" ]] || fail "unexpected deployment steps:
$OBSERVED_CALLS"
}

test_a_failing_step_stops_the_deployment_before_any_later_mapping() {
    local work
    local mkdir_call
    local settings_call
    local keybindings_call

    new_tmp_var work
    mkdir_call="mkdir -p $work/User"
    settings_call="replace_symlink $MANAGED_SETTINGS -> $work/User/settings.json"
    keybindings_call="replace_symlink $MANAGED_KEYBINDINGS -> $work/User/keybindings.json"

    run_deploy_injecting_failure "$work/User" mkdir
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected failure when the User directory cannot be created"
    [[ "$OBSERVED_CALLS" == "$mkdir_call" ]] || fail "mapping ran after directory creation failed:
$OBSERVED_CALLS"
    [[ ! -e "$work/User" ]] || fail "User directory exists after its creation failed"

    new_tmp_var work
    run_deploy_injecting_failure "$work/User" settings
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected failure when the settings mapping fails"
    [[ "$OBSERVED_CALLS" == "mkdir -p $work/User
replace_symlink $MANAGED_SETTINGS -> $work/User/settings.json" ]] || fail "deployment continued past a failed settings mapping:
$OBSERVED_CALLS"

    new_tmp_var work
    run_deploy_injecting_failure "$work/User" keybindings
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected failure when the keybindings mapping fails"
    [[ "$OBSERVED_CALLS" == "mkdir -p $work/User
replace_symlink $MANAGED_SETTINGS -> $work/User/settings.json
replace_symlink $MANAGED_KEYBINDINGS -> $work/User/keybindings.json" ]] || fail "deployment continued past a failed keybindings mapping:
$OBSERVED_CALLS"

    new_tmp_var work
    run_deploy_injecting_failure "$work/User" snippets
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected failure when the snippets mapping fails"
    [[ "$OBSERVED_CALLS" == "mkdir -p $work/User
replace_symlink $MANAGED_SETTINGS -> $work/User/settings.json
replace_symlink $MANAGED_KEYBINDINGS -> $work/User/keybindings.json
replace_symlink $MANAGED_SNIPPETS -> $work/User/snippets" ]] || fail "a failed snippets mapping was retried or followed by more work:
$OBSERVED_CALLS"
}

test_managed_mappings_hold_under_spaces_and_shell_metacharacters() {
    local work
    local user_dir
    local before
    local after
    local added

    new_tmp_var work
    user_dir="$work/Application Support/Code - [beta] & a*b/User 'one'"

    before="$(tree_snapshot "$work")"
    run_deploy "$user_dir"
    after="$(tree_snapshot "$work")"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected deployment to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_regular_directory "$user_dir" "User directory"
    assert_symlink_to "$user_dir/settings.json" "$MANAGED_SETTINGS"
    assert_symlink_to "$user_dir/keybindings.json" "$MANAGED_KEYBINDINGS"
    assert_symlink_to "$user_dir/snippets" "$MANAGED_SNIPPETS"

    added="$(comm -13 <(printf "%s\n" "$before" | sort) <(printf "%s\n" "$after" | sort))"
    [[ "$added" == "dir  ./Application Support
dir  ./Application Support/Code - [beta] & a*b
dir  ./Application Support/Code - [beta] & a*b/User 'one'
link ./Application Support/Code - [beta] & a*b/User 'one'/keybindings.json -> $MANAGED_KEYBINDINGS
link ./Application Support/Code - [beta] & a*b/User 'one'/settings.json -> $MANAGED_SETTINGS
link ./Application Support/Code - [beta] & a*b/User 'one'/snippets -> $MANAGED_SNIPPETS" ]] || fail "deployment created stray paths outside the requested User directory:
$added"
}

# ---------------------------------------------------------------------------
# Cycle C — backups of pre-existing state and idempotent rerun
# ---------------------------------------------------------------------------

# Entries under a User directory matching the timestamped backup convention.
backup_entries() {
    local user_dir="$1"

    find "$user_dir" -maxdepth 1 -name '*.backup.*' | sed "s|^$user_dir/||" | sort
}

test_existing_managed_paths_are_backed_up_with_a_timestamp() {
    local work
    local backups

    new_tmp_var work
    mkdir -p "$work/User/snippets"
    printf '{"editor.fontSize": 15}\n' > "$work/User/settings.json"
    printf '[{"key": "cmd+k", "command": "mine"}]\n' > "$work/User/keybindings.json"
    printf 'user snippet\n' > "$work/User/snippets/mine.code-snippets"

    run_deploy "$work/User"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected deployment to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_symlink_to "$work/User/settings.json" "$MANAGED_SETTINGS"
    assert_symlink_to "$work/User/keybindings.json" "$MANAGED_KEYBINDINGS"
    assert_symlink_to "$work/User/snippets" "$MANAGED_SNIPPETS"

    backups="$(backup_entries "$work/User")"
    local pattern='^(keybindings\.json|settings\.json|snippets)\.backup\.[0-9]{8}_[0-9]{6}$'
    local entry
    local names=""

    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        [[ "$entry" =~ $pattern ]] || fail "backup name is not timestamped: $entry"
        names="$names${entry%%.backup.*}
"
    done <<< "$backups"

    [[ "$(printf '%s' "$names" | sort)" == "keybindings.json
settings.json
snippets" ]] || fail "expected one backup per displaced path, got:
$backups"

    [[ "$(cat "$work/User/settings.json.backup."*)" == '{"editor.fontSize": 15}' ]] || fail "settings backup lost the user's content"
    [[ "$(cat "$work/User/keybindings.json.backup."*)" == '[{"key": "cmd+k", "command": "mine"}]' ]] || fail "keybindings backup lost the user's content"
    [[ "$(cat "$work/User/snippets.backup."*/mine.code-snippets)" == 'user snippet' ]] || fail "snippets backup lost the user's snippet"
}

test_immediate_rerun_changes_nothing() {
    local work
    local before
    local after

    new_tmp_var work
    mkdir -p "$work/User"
    printf 'sync\n' > "$work/User/syncMachines.json"

    run_deploy "$work/User"
    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected first deployment to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"

    before="$(tree_snapshot "$work/User")"
    rerun_deployment_recording_mutations "$work/User"
    after="$(tree_snapshot "$work/User")"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected rerun to succeed, got status $OBSERVED_STATUS"
    [[ -z "$OBSERVED_CALLS" ]] || fail "rerun rewrote already-correct managed links:
$OBSERVED_CALLS"
    [[ "$before" == "$after" ]] || fail "rerun changed the User directory:
$(diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") || true)"
    [[ -z "$(backup_entries "$work/User")" ]] || fail "rerun created backups:
$(backup_entries "$work/User")"
}

# ---------------------------------------------------------------------------
# Extension reconciliation
# ---------------------------------------------------------------------------

# Install the editor CLI seam used by every reconciliation test. Each
# invocation is logged verbatim, so the log is the evidence of what was asked
# of the editor — including anything the reconciler must never ask. Any verb
# other than the two supported ones exits 9, so a prune or a bare listing is
# a loud failure rather than a silent success.
#
# Outcomes are controlled through the environment by cli_outcomes:
#   STUB_FAIL       whitespace-separated identities whose install fails
#   STUB_INSTALLED  "id@version" lines reported by --list-extensions
#   STUB_LIST_FAIL  non-empty when the listing fails after printing its lines
install_cli_stub() {
    local path="$1"

    cat > "$path" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG"

case "$1" in
    --install-extension)
        for failing in ${STUB_FAIL:-}; do
            [ "$2" != "$failing" ] || exit 1
        done
        exit 0
        ;;
    --list-extensions)
        [ "$2" = "--show-versions" ] || exit 9
        [ -z "${STUB_INSTALLED:-}" ] || printf '%s\n' "$STUB_INSTALLED"
        # A listing that fails still emits what it managed to produce, so a
        # reader that ignores the status can be fooled by its own output.
        [ -z "${STUB_LIST_FAIL:-}" ] || exit 1
        exit 0
        ;;
esac

exit 9
STUB
    chmod +x "$path"
}

# Declare the editor's outcomes for the next run. All three are always set so
# no test inherits another test's stub state.
cli_outcomes() {
    export STUB_FAIL="$1"
    export STUB_INSTALLED="$2"
    export STUB_LIST_FAIL="${3:-}"
}

# Write a manifest whose lines are given as arguments, so fixtures show their
# comments, blanks, and entries literally at the call site.
write_manifest() {
    local path="$1"
    shift

    printf '%s\n' "$@" > "$path"
}

# The same fixture, but with no newline after the final entry — the shape a
# hand-edited catalog often has.
write_manifest_without_final_newline() {
    local path="$1"
    shift

    : > "$path"
    while [ "$#" -gt 1 ]; do
        printf '%s\n' "$1" >> "$path"
        shift
    done
    printf '%s' "$1" >> "$path"
}

# Run the public reconciler against a stub CLI and caller-ordered manifests.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   exit status of reconcile_vscode_extensions
#   OBSERVED_OUTPUT   combined stdout/stderr of the call
#   OBSERVED_CALLS    ordered editor CLI invocations, one per line
run_reconcile() {
    local cli="$1"
    local out
    shift

    source_install

    SUITE_TMP_SEQUENCE=$((SUITE_TMP_SEQUENCE + 1))
    out="$(tmp_artifact "reconcile-$SUITE_TMP_SEQUENCE.out")"
    STUB_LOG="$(tmp_artifact "cli-$SUITE_TMP_SEQUENCE.log")"
    export STUB_LOG
    : > "$STUB_LOG"

    OBSERVED_STATUS=0
    reconcile_vscode_extensions "$cli" "$@" > "$out" 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_OUTPUT="$(cat "$out")"
    OBSERVED_CALLS="$(cat "$STUB_LOG")"
}

# The identities listed in the aggregate report, in report order, stripped of
# the report's own decoration. Comparing whole identities keeps two entries
# that share a prefix from being counted as one.
reported_failures() {
    printf '%s\n' "$OBSERVED_OUTPUT" |
        sed -e 's/'$'\033''\[[0-9;]*m//g' -e 's/^\[ERROR\] //' |
        sed -n 's/^  //p'
}

# How many report lines are exactly the given identity.
report_lines_naming() {
    local identity="$1"

    reported_failures | grep -c -x -F -- "$identity" || true
}

# ---------------------------------------------------------------------------
# Cycle A — ordered manifest parsing and unpinned installs
# ---------------------------------------------------------------------------

test_manifests_reconcile_in_argument_then_file_order() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" ""
    write_manifest "$work/shared.txt" \
        '# Extensions reconciled on every editor target.' \
        '' \
        'EditorConfig.EditorConfig' \
        '   ' \
        '# Python linting and formatting' \
        'charliermarsh.ruff'
    write_manifest "$work/target.txt" \
        '# Target-specific entries.' \
        'ms-python.python' \
        'ms-python.debugpy'

    run_reconcile "$work/code" "$work/shared.txt" "$work/target.txt"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected reconciliation to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_CALLS" == "--install-extension EditorConfig.EditorConfig --force
--install-extension charliermarsh.ruff --force
--install-extension ms-python.python --force
--install-extension ms-python.debugpy --force" ]] || fail "unexpected editor calls:
$OBSERVED_CALLS"
}

test_malformed_entries_are_reported_and_never_executed() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" ""
    write_manifest "$work/shared.txt" \
        'EditorConfig.EditorConfig' \
        'nopublisher' \
        'two words' \
        'trailing.comment # note' \
        'charliermarsh.ruff'

    run_reconcile "$work/code" "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected malformed entries to fail reconciliation"
    [[ "$OBSERVED_CALLS" == "--install-extension EditorConfig.EditorConfig --force
--install-extension charliermarsh.ruff --force" ]] || fail "a malformed entry reached the editor:
$OBSERVED_CALLS"
    [[ "$(report_lines_naming 'nopublisher')" -eq 1 ]] || fail "malformed entry 'nopublisher' not reported exactly once:
$OBSERVED_OUTPUT"
    [[ "$(report_lines_naming 'two words')" -eq 1 ]] || fail "malformed entry 'two words' not reported exactly once:
$OBSERVED_OUTPUT"
    [[ "$(report_lines_naming 'trailing.comment # note')" -eq 1 ]] || fail "malformed entry with a trailing comment not reported exactly once:
$OBSERVED_OUTPUT"
}

# ---------------------------------------------------------------------------
# Cycle B — optional exact pins
# ---------------------------------------------------------------------------

test_a_pinned_entry_is_requested_exactly_and_verified_as_active() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" "vscodevim.vim@1.27.2
charliermarsh.ruff@2025.22.0"
    write_manifest "$work/shared.txt" \
        'vscodevim.vim@1.27.2' \
        'charliermarsh.ruff'

    run_reconcile "$work/code" "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected an active pin to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_CALLS" == "--install-extension vscodevim.vim@1.27.2 --force
--list-extensions --show-versions
--install-extension charliermarsh.ruff --force" ]] || fail "pin was not requested exactly or not verified:
$OBSERVED_CALLS"
}

test_an_inactive_pin_fails_the_entry_and_the_catalog_continues() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" "vscodevim.vim@1.20.0"
    write_manifest "$work/shared.txt" \
        'vscodevim.vim@1.27.2' \
        'esbenp.prettier-vscode@11.0.0' \
        'charliermarsh.ruff'

    run_reconcile "$work/code" "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected an unsatisfied pin to fail reconciliation"
    [[ "$OBSERVED_CALLS" == "--install-extension vscodevim.vim@1.27.2 --force
--list-extensions --show-versions
--install-extension esbenp.prettier-vscode@11.0.0 --force
--list-extensions --show-versions
--install-extension charliermarsh.ruff --force" ]] || fail "the catalog did not continue past unsatisfied pins:
$OBSERVED_CALLS"
    [[ "$(report_lines_naming 'vscodevim.vim@1.27.2')" -eq 1 ]] || fail "mismatched pin not reported exactly once:
$OBSERVED_OUTPUT"
    [[ "$(report_lines_naming 'esbenp.prettier-vscode@11.0.0')" -eq 1 ]] || fail "missing pin not reported exactly once:
$OBSERVED_OUTPUT"
    [[ "$(report_lines_naming 'charliermarsh.ruff')" -eq 0 ]] || fail "a succeeding entry was reported as failed:
$OBSERVED_OUTPUT"
}

# ---------------------------------------------------------------------------
# Cycle C — aggregate failures and no pruning
# ---------------------------------------------------------------------------

test_every_failed_identity_is_reported_once_after_the_whole_catalog_ran() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "ms-python.python" "vscodevim.vim@1.20.0"
    write_manifest "$work/shared.txt" \
        'ms-python.python' \
        'not an identity' \
        'vscodevim.vim@1.27.2' \
        'charliermarsh.ruff'
    write_manifest "$work/target.txt" \
        'ms-python.python' \
        'ms-python.debugpy'

    run_reconcile "$work/code" "$work/shared.txt" "$work/target.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected aggregated failures to fail reconciliation"
    [[ "$OBSERVED_CALLS" == "--install-extension ms-python.python --force
--install-extension vscodevim.vim@1.27.2 --force
--list-extensions --show-versions
--install-extension charliermarsh.ruff --force
--install-extension ms-python.python --force
--install-extension ms-python.debugpy --force" ]] || fail "the catalog was not attempted to completion:
$OBSERVED_CALLS"
    [[ "$(report_lines_naming 'ms-python.python')" -eq 1 ]] || fail "an identity failing in two manifests was not reported once:
$OBSERVED_OUTPUT"
    [[ "$(report_lines_naming 'not an identity')" -eq 1 ]] || fail "malformed entry not reported exactly once:
$OBSERVED_OUTPUT"
    [[ "$(report_lines_naming 'vscodevim.vim@1.27.2')" -eq 1 ]] || fail "unsatisfied pin not reported exactly once:
$OBSERVED_OUTPUT"
    [[ "$(report_lines_naming 'ms-python.debugpy')" -eq 0 ]] || fail "a succeeding entry was reported as failed:
$OBSERVED_OUTPUT"
}

test_a_missing_manifest_is_reported_and_the_remaining_manifests_run() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" ""
    write_manifest "$work/target.txt" 'ms-python.debugpy'

    run_reconcile "$work/code" "$work/absent.txt" "$work/target.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected a missing manifest to fail reconciliation"
    [[ "$OBSERVED_CALLS" == "--install-extension ms-python.debugpy --force" ]] || fail "a missing manifest stopped the remaining ones:
$OBSERVED_CALLS"
    [[ "$(report_lines_naming "$work/absent.txt")" -eq 1 ]] || fail "missing manifest not reported exactly once:
$OBSERVED_OUTPUT"
}

test_the_repository_catalogs_only_ever_ask_the_editor_to_install() {
    local work
    local last_shared
    local first_target_only

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" ""

    run_reconcile "$work/code" \
        "$DOTFILES_DIR/vscode/extensions/shared.txt" \
        "$DOTFILES_DIR/vscode/extensions/desktop.txt"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected the repository catalogs to reconcile, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ -z "$(printf '%s\n' "$OBSERVED_CALLS" | grep -v '^--install-extension .* --force$' || true)" ]] || fail "the reconciler asked the editor for something other than an install:
$OBSERVED_CALLS"

    last_shared="$(printf '%s\n' "$OBSERVED_CALLS" | grep -n -- '--install-extension vscodevim.vim ' | tail -1 | cut -d: -f1)"
    first_target_only="$(printf '%s\n' "$OBSERVED_CALLS" | grep -n -- '--install-extension ms-python.vscode-pylance ' | head -1 | cut -d: -f1)"
    [[ -n "$last_shared" && -n "$first_target_only" ]] || fail "expected both catalogs to be reconciled:
$OBSERVED_CALLS"
    [[ "$last_shared" -lt "$first_target_only" ]] || fail "the target catalog was reconciled before the shared catalog:
$OBSERVED_CALLS"
}

# The identities the reconciler asked the editor to install, in order.
requested_installs() {
    printf '%s\n' "$OBSERVED_CALLS" | sed -n 's/^--install-extension \(.*\) --force$/\1/p'
}

test_the_identity_grammar_accepts_publisher_name_with_an_optional_version() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" "vscodevim.vim@1.27.2
esbenp.prettier-vscode@11.0.0-rc.1
ms-toolsai.jupyter@2025.1.0+build.5
ms-python.python@1"
    write_manifest "$work/accepted.txt" \
        'EditorConfig.EditorConfig' \
        '4ops.terraform' \
        'pub-lisher.na-me' \
        'a.b' \
        'vscodevim.vim@1.27.2' \
        'esbenp.prettier-vscode@11.0.0-rc.1' \
        'ms-toolsai.jupyter@2025.1.0+build.5' \
        'ms-python.python@1'

    run_reconcile "$work/code" "$work/accepted.txt"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "a valid identity was rejected: $OBSERVED_OUTPUT"
    [[ "$(requested_installs)" == "EditorConfig.EditorConfig
4ops.terraform
pub-lisher.na-me
a.b
vscodevim.vim@1.27.2
esbenp.prettier-vscode@11.0.0-rc.1
ms-toolsai.jupyter@2025.1.0+build.5
ms-python.python@1" ]] || fail "not every accepted identity was requested:
$OBSERVED_CALLS"
}

test_the_identity_grammar_rejects_everything_outside_publisher_name_at_version() {
    local work
    local rejected

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" ""
    write_manifest "$work/rejected.txt" \
        'nopublisher' \
        'pub_lisher.name' \
        'publisher.na_me' \
        'a.b.c' \
        '.name' \
        'publisher.' \
        '-pub.name' \
        'pub.name@' \
        'pub.name@.1' \
        'pub.name@-1' \
        'pub.name@+1' \
        'pub.name@1@2' \
        'pub.name 1'
    # Every line of the fixture is malformed, so the file is also the report
    # the reconciler owes back.
    rejected="$(cat "$work/rejected.txt")"

    run_reconcile "$work/code" "$work/rejected.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "malformed identities were accepted"
    [[ -z "$OBSERVED_CALLS" ]] || fail "a malformed identity reached the editor:
$OBSERVED_CALLS"
    [[ "$(reported_failures)" == "$rejected" ]] || fail "the rejected identities were not reported verbatim:
$(reported_failures)"
}

test_a_final_entry_without_a_trailing_newline_is_still_reconciled() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" ""
    write_manifest_without_final_newline "$work/shared.txt" \
        'EditorConfig.EditorConfig' \
        'charliermarsh.ruff'

    run_reconcile "$work/code" "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected reconciliation to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$(requested_installs)" == "EditorConfig.EditorConfig
charliermarsh.ruff" ]] || fail "the entry without a trailing newline was dropped:
$OBSERVED_CALLS"
}

test_a_failed_pinned_install_is_never_verified_against_the_editor() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "vscodevim.vim@1.27.2" "vscodevim.vim@1.27.2"
    write_manifest "$work/shared.txt" \
        'vscodevim.vim@1.27.2' \
        'charliermarsh.ruff'

    run_reconcile "$work/code" "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a failed install was treated as success"
    [[ "$OBSERVED_CALLS" == "--install-extension vscodevim.vim@1.27.2 --force
--install-extension charliermarsh.ruff --force" ]] || fail "a failed install was verified as if it had run:
$OBSERVED_CALLS"
    [[ "$(reported_failures)" == "vscodevim.vim@1.27.2" ]] || fail "the failed install was not reported alone:
$OBSERVED_OUTPUT"
}

test_a_failing_listing_fails_the_pinned_entry_and_the_catalog_continues() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" "vscodevim.vim@1.27.2" fail
    write_manifest "$work/shared.txt" \
        'vscodevim.vim@1.27.2' \
        'charliermarsh.ruff'

    run_reconcile "$work/code" "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "an unusable listing was treated as a satisfied pin"
    [[ "$OBSERVED_CALLS" == "--install-extension vscodevim.vim@1.27.2 --force
--list-extensions --show-versions
--install-extension charliermarsh.ruff --force" ]] || fail "the catalog did not continue past a failed listing:
$OBSERVED_CALLS"
    [[ "$(reported_failures)" == "vscodevim.vim@1.27.2" ]] || fail "the unverifiable pin was not reported alone:
$OBSERVED_OUTPUT"
}

test_a_pin_matches_an_installed_identity_by_case_but_not_by_prefix() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" "VscodeVim.Vim@1.27.2"
    write_manifest "$work/shared.txt" 'vscodevim.vim@1.27.2'

    run_reconcile "$work/code" "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "a pin the editor reports with other casing was rejected: $OBSERVED_OUTPUT"

    # The identity is the editor's to spell; the version is the marketplace's
    # own release label, so casing inside it distinguishes two releases.
    cli_outcomes "" "VscodeVim.Vim@1.0.0-rc.1"
    write_manifest "$work/identity-case.txt" 'vscodevim.vim@1.0.0-rc.1'

    run_reconcile "$work/code" "$work/identity-case.txt"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "a pin differing only in identity casing was rejected: $OBSERVED_OUTPUT"

    cli_outcomes "" "vscodevim.vim@1.0.0-RC.1"
    write_manifest "$work/version-case.txt" 'vscodevim.vim@1.0.0-rc.1'

    run_reconcile "$work/code" "$work/version-case.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a version the editor never installed was accepted on a difference of casing alone"
    [[ "$(reported_failures)" == "vscodevim.vim@1.0.0-rc.1" ]] || fail "the unsatisfied pin was not reported alone:
$OBSERVED_OUTPUT"

    cli_outcomes "" "vscodevim.vim@1.27.2"
    write_manifest "$work/prefix.txt" 'vscodevim.vim@1.27'

    run_reconcile "$work/code" "$work/prefix.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a version the editor never installed was accepted as a prefix of one it did"
    [[ "$(reported_failures)" == "vscodevim.vim@1.27" ]] || fail "the unsatisfied pin was not reported alone:
$OBSERVED_OUTPUT"
}

test_identities_sharing_a_prefix_are_each_reported_in_full() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "ms-python.python ms-python.python-envs" ""
    write_manifest "$work/shared.txt" \
        'ms-python.python' \
        'ms-python.python-envs' \
        'ms-python.debugpy'

    run_reconcile "$work/code" "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected the failed installs to fail reconciliation"
    [[ "$(reported_failures)" == "ms-python.python
ms-python.python-envs" ]] || fail "identities sharing a prefix were collapsed in the report:
$(reported_failures)"
}

test_an_unreadable_manifest_is_reported_and_the_remaining_manifests_run() {
    local work

    new_tmp_var work
    install_cli_stub "$work/code"
    cli_outcomes "" ""
    write_manifest "$work/shared.txt" 'EditorConfig.EditorConfig'
    chmod 000 "$work/shared.txt"
    write_manifest "$work/target.txt" 'ms-python.debugpy'

    run_reconcile "$work/code" "$work/shared.txt" "$work/target.txt"
    chmod 644 "$work/shared.txt"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "an unreadable manifest was treated as reconciled"
    [[ "$OBSERVED_CALLS" == "--install-extension ms-python.debugpy --force" ]] || fail "an unreadable manifest stopped the manifests behind it:
$OBSERVED_CALLS"
    [[ "$(reported_failures)" == "$work/shared.txt" ]] || fail "the unreadable manifest was not reported:
$OBSERVED_OUTPUT"
}

# ---------------------------------------------------------------------------
# Desktop provisioning — official Cask install/upgrade
# ---------------------------------------------------------------------------

# Install the Homebrew seam used by the desktop provisioning tests. Every
# invocation is logged verbatim, so the log is the evidence of which official
# identity was asked for — and that no substitute distribution was.
#
# Outcomes are controlled through the environment:
#   STUB_CASK_PRESENT  non-empty when the Cask is already installed
#   STUB_BREW_FAIL     "install" or "upgrade": that verb fails
#   STUB_BREW_MESSAGE  what the failing verb reports
install_brew_stub() {
    local path="$1"

    cat > "$path" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG"

case "$1 $2" in
    "list --cask")
        [ -n "${STUB_CASK_PRESENT:-}" ] || exit 1
        exit 0
        ;;
    "install --cask")
        [ "${STUB_BREW_FAIL:-}" != "install" ] || {
            printf '%s\n' "${STUB_BREW_MESSAGE:-Error: Download failed}" >&2
            exit 1
        }
        exit 0
        ;;
    "upgrade --cask")
        [ "${STUB_BREW_FAIL:-}" != "upgrade" ] || {
            printf '%s\n' "${STUB_BREW_MESSAGE:-Error: Download failed}"
            exit 1
        }
        exit 0
        ;;
esac

exit 9
STUB
    chmod +x "$path"
}

# A stub for a command that only has to exist and succeed.
install_present_command() {
    printf '#!/usr/bin/env bash\nexit 0\n' > "$1"
    chmod +x "$1"
}

# Declare Homebrew's outcomes for the next run. All three are always set so
# no test inherits another test's stub state.
brew_outcomes() {
    export STUB_CASK_PRESENT="$1"
    export STUB_BREW_FAIL="${2:-}"
    export STUB_BREW_MESSAGE="${3:-}"
}

# Run the desktop installer with a caller-built PATH holding the only
# commands it is allowed to find.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   exit status of install_vscode
#   OBSERVED_OUTPUT   combined stdout/stderr of the call
#   OBSERVED_CALLS    ordered Homebrew invocations, one per line
run_install_vscode() {
    local platform="$1"
    local bin="$2"
    local out

    source_install

    SUITE_TMP_SEQUENCE=$((SUITE_TMP_SEQUENCE + 1))
    out="$(tmp_artifact "install-vscode-$SUITE_TMP_SEQUENCE.out")"
    STUB_LOG="$(tmp_artifact "brew-$SUITE_TMP_SEQUENCE.log")"
    export STUB_LOG
    : > "$STUB_LOG"

    OS="$platform"
    OBSERVED_STATUS=0
    (
        export PATH="$bin"
        install_vscode
    ) > "$out" 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_OUTPUT="$(cat "$out")"
    OBSERVED_CALLS="$(cat "$STUB_LOG")"
}

# A desktop host whose PATH holds Homebrew and, unless told otherwise, the
# editor command a successful installation leaves behind.
desktop_bin() {
    local bin="$1"
    local with_code="${2:-code}"

    mkdir -p "$bin"
    # The PATH is replaced rather than prefixed, so an absent editor command
    # is genuinely absent; the stubs' own interpreter has to be reachable too.
    ln -sf "$(command -v bash)" "$bin/bash"
    install_brew_stub "$bin/brew"
    [ "$with_code" != "code" ] || install_present_command "$bin/code"
}

test_desktop_installation_is_refused_outside_macos() {
    local work

    new_tmp_var work
    desktop_bin "$work/bin"
    brew_outcomes ""

    run_install_vscode ubuntu "$work/bin"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected desktop installation to fail off macOS"
    [[ -z "$OBSERVED_CALLS" ]] || fail "an unsupported platform still asked Homebrew for the editor:
$OBSERVED_CALLS"
    [[ "$OBSERVED_OUTPUT" == *"macOS"* ]] || fail "the unsupported-platform message does not name the supported platform:
$OBSERVED_OUTPUT"
}

test_an_absent_official_cask_is_installed_and_the_command_verified() {
    local work

    new_tmp_var work
    desktop_bin "$work/bin"
    brew_outcomes ""

    run_install_vscode macos "$work/bin"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected the absent Cask to install, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_CALLS" == "list --cask visual-studio-code
install --cask visual-studio-code" ]] || fail "the official Cask was not installed exactly:
$OBSERVED_CALLS"
}

test_a_present_official_cask_is_asked_to_upgrade_instead_of_reinstall() {
    local work

    new_tmp_var work
    desktop_bin "$work/bin"
    brew_outcomes present

    run_install_vscode macos "$work/bin"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected the present Cask to upgrade, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_CALLS" == "list --cask visual-studio-code
upgrade --cask visual-studio-code" ]] || fail "the present Cask was not offered an upgrade exactly:
$OBSERVED_CALLS"
}

test_no_substitute_distribution_or_application_bundle_is_touched() {
    local work
    local platform

    new_tmp_var work
    desktop_bin "$work/bin"

    for platform in "" present; do
        brew_outcomes "$platform"
        run_install_vscode macos "$work/bin"

        [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected provisioning to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
        [[ "$OBSERVED_CALLS" != *codium* && "$OBSERVED_CALLS" != *oss* ]] || fail "a substitute distribution was requested:
$OBSERVED_CALLS"
        [[ "$OBSERVED_CALLS" != *"/Applications"* && "$OBSERVED_CALLS" != *codesign* ]] || fail "the application bundle was touched:
$OBSERVED_CALLS"
    done
}

test_a_missing_editor_command_after_provisioning_fails() {
    local work

    new_tmp_var work
    desktop_bin "$work/bin" without-code
    brew_outcomes ""

    run_install_vscode macos "$work/bin"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a provisioning run that left no editor command reported success"
    [[ "$OBSERVED_CALLS" == "list --cask visual-studio-code
install --cask visual-studio-code" ]] || fail "unexpected Homebrew calls before verification:
$OBSERVED_CALLS"
    [[ "$OBSERVED_OUTPUT" == *"code"* ]] || fail "the failure does not name the missing command interface:
$OBSERVED_OUTPUT"
}

test_a_failed_cask_installation_fails_the_module_with_its_diagnostics() {
    local work

    new_tmp_var work
    desktop_bin "$work/bin"
    brew_outcomes "" install "Error: Download failed on Cask visual-studio-code"

    run_install_vscode macos "$work/bin"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a failed Cask installation was treated as success"
    [[ "$OBSERVED_OUTPUT" == *"Download failed on Cask visual-studio-code"* ]] || fail "the Homebrew diagnostics were swallowed:
$OBSERVED_OUTPUT"
}

test_a_failed_cask_upgrade_fails_the_module_with_its_diagnostics() {
    local work

    new_tmp_var work
    desktop_bin "$work/bin"
    brew_outcomes present upgrade "Error: Failed to download resource visual-studio-code"

    run_install_vscode macos "$work/bin"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a failed Cask upgrade was treated as success"
    [[ "$OBSERVED_OUTPUT" == *"Failed to download resource visual-studio-code"* ]] || fail "the Homebrew diagnostics were swallowed:
$OBSERVED_OUTPUT"
}

test_an_already_current_cask_is_not_a_failure() {
    local work
    local message

    new_tmp_var work
    desktop_bin "$work/bin"

    for message in \
        "Warning: visual-studio-code 1.99.0 already installed" \
        "Warning: visual-studio-code is up-to-date"
    do
        brew_outcomes present upgrade "$message"
        run_install_vscode macos "$work/bin"

        [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "an already-current Cask was reported as a failure: $OBSERVED_OUTPUT"
    done
}

# ---------------------------------------------------------------------------
# Desktop configuration — Default Profile composition
# ---------------------------------------------------------------------------

# The managed catalogs the desktop target composes, named once so the tests
# assert against canonical repository paths instead of restating them.
SHARED_MANIFEST="$DOTFILES_DIR/vscode/extensions/shared.txt"
DESKTOP_MANIFEST="$DOTFILES_DIR/vscode/extensions/desktop.txt"

# A macOS host whose PATH holds only the commands the configuration is
# allowed to find. Extra names ("code", "python3", "node") are present only
# when listed, so absence is genuine.
configure_bin() {
    local bin="$1"
    local name
    shift

    mkdir -p "$bin"
    ln -sf "$(command -v bash)" "$bin/bash"
    printf '#!/usr/bin/env bash\nprintf '"'"'%%s\\n'"'"' "defaults $*" >> "$STUB_LOG"\nexit "${STUB_DEFAULTS_STATUS:-0}"\n' > "$bin/defaults"
    chmod +x "$bin/defaults"

    for name in "$@"; do
        install_present_command "$bin/$name"
    done
}

# Replace the integrated helpers the desktop target owns the composition of
# with recorders, optionally failing the named one. Every call is logged
# before the injected failure, so the log shows both what ran and what never
# started.
stub_owned_operations() {
    local failing="$1"

    deploy_vscode_managed_layer() {
        printf 'deploy_vscode_managed_layer %s\n' "$1" >> "$STUB_LOG"
        [ "$failing" != "deploy" ] || return 1
        return 0
    }

    reconcile_vscode_extensions() {
        printf 'reconcile_vscode_extensions %s\n' "$*" >> "$STUB_LOG"
        [ "$failing" != "reconcile" ] || return 1
        return 0
    }
}

# Run the desktop configuration with its owned dependencies recorded and one
# of them optionally forced to fail.
#
# $4 selects the failing step: deploy, reconcile, defaults, or none.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   exit status of configure_vscode
#   OBSERVED_OUTPUT   combined stdout/stderr of the call
#   OBSERVED_CALLS    ordered owned operations, one per line
run_configure_vscode() {
    local platform="$1"
    local bin="$2"
    local home="$3"
    local failing="${4:-none}"
    local out

    source_install

    SUITE_TMP_SEQUENCE=$((SUITE_TMP_SEQUENCE + 1))
    out="$(tmp_artifact "configure-vscode-$SUITE_TMP_SEQUENCE.out")"
    STUB_LOG="$(tmp_artifact "configure-calls-$SUITE_TMP_SEQUENCE.log")"
    export STUB_LOG
    : > "$STUB_LOG"

    OS="$platform"
    OBSERVED_STATUS=0
    (
        export PATH="$bin"
        export HOME="$home"
        export STUB_DEFAULTS_STATUS=0
        [ "$failing" != "defaults" ] || export STUB_DEFAULTS_STATUS=1

        stub_owned_operations "$failing"

        configure_vscode
    ) > "$out" 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_OUTPUT="$(cat "$out")"
    OBSERVED_CALLS="$(cat "$STUB_LOG")"
}

test_desktop_configuration_is_refused_outside_macos() {
    local work

    new_tmp_var work
    configure_bin "$work/bin" code python3 node

    run_configure_vscode ubuntu "$work/bin" "$work/home"

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected desktop configuration to fail off macOS"
    [[ -z "$OBSERVED_CALLS" ]] || fail "an unsupported platform still configured the editor:
$OBSERVED_CALLS"
    [[ "$OBSERVED_OUTPUT" == *"macOS"* ]] || fail "the unsupported-platform message does not name the supported platform:
$OBSERVED_OUTPUT"
}

test_configuration_deploys_the_managed_layer_then_reconciles_shared_before_desktop() {
    local work

    new_tmp_var work
    configure_bin "$work/bin" code python3 node

    run_configure_vscode macos "$work/bin" "$work/home"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected desktop configuration to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_CALLS" == "deploy_vscode_managed_layer $work/home/Library/Application Support/Code/User
reconcile_vscode_extensions code $SHARED_MANIFEST $DESKTOP_MANIFEST
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false" ]] || fail "unexpected desktop configuration steps:
$OBSERVED_CALLS"
}

test_a_failing_owned_operation_stops_the_configuration_and_propagates() {
    local work
    local deploy_call
    local reconcile_call

    new_tmp_var work
    configure_bin "$work/bin" code python3 node
    deploy_call="deploy_vscode_managed_layer $work/home/Library/Application Support/Code/User"
    reconcile_call="reconcile_vscode_extensions code $SHARED_MANIFEST $DESKTOP_MANIFEST"

    run_configure_vscode macos "$work/bin" "$work/home" deploy
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a failed managed deployment was reported as success"
    [[ "$OBSERVED_CALLS" == "$deploy_call" ]] || fail "configuration continued past a failed deployment:
$OBSERVED_CALLS"

    run_configure_vscode macos "$work/bin" "$work/home" reconcile
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a failed reconciliation was reported as success"
    [[ "$OBSERVED_CALLS" == "$deploy_call
$reconcile_call" ]] || fail "configuration continued past a failed reconciliation:
$OBSERVED_CALLS"

    run_configure_vscode macos "$work/bin" "$work/home" defaults
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a failed key-repeat preference was reported as success"
    [[ "$OBSERVED_CALLS" == "$deploy_call
$reconcile_call
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false" ]] || fail "unexpected steps around the failed preference:
$OBSERVED_CALLS"
}

# ---------------------------------------------------------------------------
# Desktop configuration — nonblocking runtime warnings
# ---------------------------------------------------------------------------

# The configuration's own report, stripped of colour so lines can be matched
# and ordered.
configuration_report() {
    printf '%s\n' "$OBSERVED_OUTPUT" | sed -e 's/'$'\033''\[[0-9;]*m//g'
}

# Warning lines naming a runtime, as reported to the operator.
warnings_naming() {
    configuration_report | grep '^\[WARNING\]' | grep -c -i -- "$1" || true
}

# 1-based line of the first report line matching a pattern, or 0.
report_line_of() {
    configuration_report | grep -n -i -- "$1" | head -1 | cut -d: -f1
}

test_present_runtimes_produce_no_warning() {
    local work

    new_tmp_var work
    configure_bin "$work/bin" code python3 node

    run_configure_vscode macos "$work/bin" "$work/home"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected configuration to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$(configuration_report | grep -c '^\[WARNING\]' || true)" -eq 0 ]] || fail "present runtimes still produced a warning:
$(configuration_report)"
}

test_a_missing_runtime_warns_without_failing_the_configuration() {
    local work

    new_tmp_var work

    configure_bin "$work/bin-no-python" code node
    run_configure_vscode macos "$work/bin-no-python" "$work/home"
    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "a missing Python runtime failed the configuration: $OBSERVED_OUTPUT"
    [[ "$(warnings_naming python)" -eq 1 ]] || fail "expected exactly one Python runtime warning:
$(configuration_report)"
    [[ "$(warnings_naming node)" -eq 0 ]] || fail "a present Node.js runtime was reported as missing:
$(configuration_report)"

    configure_bin "$work/bin-no-node" code python3
    run_configure_vscode macos "$work/bin-no-node" "$work/home"
    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "a missing Node.js runtime failed the configuration: $OBSERVED_OUTPUT"
    [[ "$(warnings_naming node)" -eq 1 ]] || fail "expected exactly one Node.js runtime warning:
$(configuration_report)"
    [[ "$(warnings_naming python)" -eq 0 ]] || fail "a present Python runtime was reported as missing:
$(configuration_report)"
}

test_both_missing_runtimes_warn_before_the_configuration_reports_success() {
    local work
    local warning_line
    local success_line

    new_tmp_var work
    configure_bin "$work/bin" code

    run_configure_vscode macos "$work/bin" "$work/home"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "missing runtimes failed the configuration: $OBSERVED_OUTPUT"
    [[ "$(warnings_naming python)" -eq 1 ]] || fail "expected a Python runtime warning:
$(configuration_report)"
    [[ "$(warnings_naming node)" -eq 1 ]] || fail "expected a Node.js runtime warning:
$(configuration_report)"
    [[ "$OBSERVED_CALLS" == *"defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false"* ]] || fail "missing runtimes skipped owned configuration work:
$OBSERVED_CALLS"

    warning_line="$(report_line_of '^\[WARNING\]')"
    success_line="$(report_line_of 'Default Profile')"
    [[ -n "$success_line" && "$warning_line" -lt "$success_line" ]] || fail "runtime warnings did not precede the success report:
$(configuration_report)"
}

# ---------------------------------------------------------------------------
# Desktop completion — honest Settings Sync guidance
# ---------------------------------------------------------------------------

# Run the desktop configuration the way the installer does — as a module
# whose outcome decides the completion report — and capture everything the
# operator sees.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   0 only when the module completed
#   OBSERVED_OUTPUT   combined module and completion-report output
run_desktop_module() {
    local bin="$1"
    local home="$2"
    local failing="${3:-none}"
    local out

    source_install

    SUITE_TMP_SEQUENCE=$((SUITE_TMP_SEQUENCE + 1))
    out="$(tmp_artifact "desktop-module-$SUITE_TMP_SEQUENCE.out")"
    STUB_LOG="$(tmp_artifact "desktop-module-calls-$SUITE_TMP_SEQUENCE.log")"
    export STUB_LOG
    : > "$STUB_LOG"

    OS="macos"
    OBSERVED_STATUS=0
    (
        export PATH="$bin"
        export HOME="$home"
        export STUB_DEFAULTS_STATUS=0
        [ "$failing" != "defaults" ] || export STUB_DEFAULTS_STATUS=1
        COMPLETED_MODULES=()
        FAILED_MODULES=()

        stub_owned_operations "$failing"

        run_module vscode_config configure_vscode
        show_editor_completion_notices
        [ "${#FAILED_MODULES[@]}" -eq 0 ]
    ) > "$out" 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_OUTPUT="$(cat "$out")"
}

# Everything the operator was told about Settings Sync, in report order.
settings_sync_guidance() {
    configuration_report | grep -i 'settings sync' || true
}

test_successful_desktop_configuration_reports_the_manual_settings_sync_action() {
    local work

    new_tmp_var work
    configure_bin "$work/bin" code python3 node

    run_desktop_module "$work/bin" "$work/home"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected the desktop module to complete, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$(settings_sync_guidance | wc -l)" -eq 1 ]] || fail "expected exactly one Settings Sync action line:
$(settings_sync_guidance)"
    [[ "$(settings_sync_guidance)" == *manual* ]] || fail "the Settings Sync action is not stated as manual:
$(settings_sync_guidance)"
    [[ "$(configuration_report)" == *"cannot detect or enforce"* ]] || fail "the report does not disclaim detection and enforcement:
$(configuration_report)"
    [[ "$(configuration_report | grep -i -c 'automatically\|disabled Settings Sync\|enforced Settings Sync' || true)" -eq 0 ]] || fail "the report claims Settings Sync automation:
$(configuration_report)"
}

test_a_failed_desktop_configuration_reports_no_settings_sync_success_guidance() {
    local work
    local failing

    new_tmp_var work
    configure_bin "$work/bin" code python3 node

    for failing in deploy reconcile defaults; do
        run_desktop_module "$work/bin" "$work/home" "$failing"

        [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "a failed '$failing' step still completed the module"
        [[ -z "$(settings_sync_guidance)" ]] || fail "a failed '$failing' step still printed success guidance:
$(settings_sync_guidance)"
    done
}

run_tests "install vscode managed layer and extension reconciliation"

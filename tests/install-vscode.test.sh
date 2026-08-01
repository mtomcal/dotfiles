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

run_tests "install vscode managed layer deployment"

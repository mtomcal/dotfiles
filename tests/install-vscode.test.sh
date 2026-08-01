#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

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
    printf '[]\n' > "$work/User/keybindings.json"
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
    run_deploy "$work/User"
    after="$(tree_snapshot "$work/User")"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected rerun to succeed, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$before" == "$after" ]] || fail "rerun changed the User directory:
$(diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") || true)"
    [[ -z "$(backup_entries "$work/User")" ]] || fail "rerun created backups:
$(backup_entries "$work/User")"
}

run_tests "install vscode managed layer deployment"

#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

# Bootstrap is an explicit operation, never an install side effect. These
# tests cover its argument contract and the machine-local config it writes;
# clone/init/push need a real private remote and stay a manual gate.

# --- argument validation -----------------------------------------------------

test_bootstrap_requires_absolute_local_path() {
    source_install

    ! beads_bootstrap_arguments_valid "relative/path" "git+ssh://git@github.com/o/r.git" \
        || fail "relative local path must be rejected"
}

test_bootstrap_requires_a_remote_url() {
    source_install

    ! beads_bootstrap_arguments_valid "/abs/path" "" \
        || fail "empty remote must be rejected"
}

test_bootstrap_accepts_git_ssh_and_https_remotes() {
    source_install

    beads_bootstrap_arguments_valid "/abs/path" "git+ssh://git@github.com/o/r.git" \
        || fail "git+ssh remote must be accepted"
    beads_bootstrap_arguments_valid "/abs/path" "git+https://github.com/o/r.git" \
        || fail "git+https remote must be accepted"
}

# A bare git URL is a common mistake: Dolt needs the git+ prefix to use its
# git transport, and without it push fails well after bootstrap "succeeds".
test_bootstrap_rejects_remote_without_dolt_scheme() {
    source_install

    ! beads_bootstrap_arguments_valid "/abs/path" "git@github.com:o/r.git" \
        || fail "bare SSH remote must be rejected"
    ! beads_bootstrap_arguments_valid "/abs/path" "https://github.com/o/r.git" \
        || fail "bare HTTPS remote must be rejected"
}

# git+ssh:// is a URL scheme, so the host is delimited by '/'. Pasting the
# scp-style form GitHub displays keeps the ':' separator, which SSH then reads
# as a port and resolves "github.com:owner" as a hostname. That surfaces deep
# inside git clone, so reject it at the boundary instead.
test_bootstrap_rejects_scp_style_host_separator() {
    source_install

    ! beads_bootstrap_arguments_valid "/abs/path" "git+ssh://git@github.com:owner/repo.git" \
        || fail "scp-style ':' separator must be rejected"
    ! beads_bootstrap_arguments_valid "/abs/path" "git+https://github.com:owner/repo.git" \
        || fail "scp-style ':' separator must be rejected for https"
}

# An explicit port is legitimate URL syntax and must survive the check above.
test_bootstrap_accepts_explicit_port() {
    source_install

    beads_bootstrap_arguments_valid "/abs/path" "git+ssh://git@example.com:2222/owner/repo.git" \
        || fail "explicit numeric port must be accepted"
}

# --- runtime config ----------------------------------------------------------

test_bootstrap_writes_machine_local_runtime_config() {
    local home
    new_tmp_var home
    mkdir -p "$home/command/.beads"

    source_install

    HOME="$home" write_beads_command_config "$home/command/.beads" \
        >"$(tmp_artifact beads-bootstrap-config.out)"

    local config="$home/.config/beads-command/env"
    [[ -f "$config" ]] || fail "expected runtime config at $config"
    grep -qx "BEADS_DIR=$home/command/.beads" "$config" \
        || fail "runtime config missing the resolved .beads path: $(cat "$config")"
}

test_runtime_config_is_rewritten_not_appended_on_rerun() {
    local home
    new_tmp_var home
    mkdir -p "$home/command/.beads" "$home/other/.beads"

    source_install

    HOME="$home" write_beads_command_config "$home/other/.beads" >/dev/null
    HOME="$home" write_beads_command_config "$home/command/.beads" >/dev/null

    local config="$home/.config/beads-command/env"
    local lines
    lines="$(grep -c '^BEADS_DIR=' "$config")"
    [[ "$lines" -eq 1 ]] || fail "expected exactly one BEADS_DIR line, found $lines"
    grep -qx "BEADS_DIR=$home/command/.beads" "$config" \
        || fail "rerun must record the newest path"
}

# The remote URL can carry credentials; only the resolved path belongs on disk.
test_runtime_config_records_no_remote_or_credentials() {
    local home
    new_tmp_var home
    mkdir -p "$home/command/.beads"

    source_install

    HOME="$home" write_beads_command_config "$home/command/.beads" >/dev/null

    local config="$home/.config/beads-command/env"
    ! grep -qi 'github.com\|password\|token\|git+ssh' "$config" \
        || fail "runtime config must not record remote or credential material"
}

# --- sync configuration reaches the remote -----------------------------------
#
# bd commits .beads/config.yaml itself when it records sync.remote. An
# implementation that only pushes when it made its own commit leaves that
# commit stranded locally, and other machines cannot bootstrap from it.

new_command_repo_with_remote() {
    local root="$1"
    local remote="$root/remote.git"
    local work="$root/work"

    git init -q --bare "$remote"
    git clone -q "$remote" "$work" 2>/dev/null
    git -C "$work" config user.email test@example.com
    git -C "$work" config user.name "Test"
    git -C "$work" commit -q --allow-empty -m "init"
    git -C "$work" push -q -u origin HEAD 2>/dev/null

    mkdir -p "$work/.beads"
    printf 'sync.remote: "git+ssh://git@github.com/o/r.git"\n' >"$work/.beads/config.yaml"
}

remote_head_has_config() {
    git -C "$1/remote.git" show "HEAD:.beads/config.yaml" >/dev/null 2>&1
}

test_config_committed_by_bd_is_still_pushed() {
    local root
    new_tmp_var root

    source_install
    new_command_repo_with_remote "$root"

    # Simulate bd's own commit: the file is already committed locally, so
    # nothing is staged when bootstrap runs.
    git -C "$root/work" add .beads/config.yaml
    git -C "$root/work" commit -q -m "bd: update sync.remote"

    beads_commit_command_config "$root/work" >/dev/null \
        || fail "commit helper reported failure"

    remote_head_has_config "$root" \
        || fail "sync configuration never reached the remote"
}

test_uncommitted_config_is_committed_and_pushed() {
    local root
    new_tmp_var root

    source_install
    new_command_repo_with_remote "$root"

    beads_commit_command_config "$root/work" >/dev/null \
        || fail "commit helper reported failure"

    remote_head_has_config "$root" \
        || fail "sync configuration never reached the remote"
}

test_commit_helper_is_idempotent() {
    local root
    new_tmp_var root

    source_install
    new_command_repo_with_remote "$root"

    beads_commit_command_config "$root/work" >/dev/null || fail "first call failed"
    beads_commit_command_config "$root/work" >/dev/null || fail "rerun failed"

    remote_head_has_config "$root" || fail "sync configuration missing after rerun"
}

# --- empty remote ------------------------------------------------------------
#
# A freshly created GitHub repo has no branches. Dolt refuses to push to it
# ("git remote has no branches"), so the repo needs an initial commit before
# any Beads work happens.

test_empty_clone_gets_an_initial_commit() {
    local root
    new_tmp_var root

    source_install

    git init -q --bare "$root/remote.git"
    git clone -q "$root/remote.git" "$root/work" 2>/dev/null
    git -C "$root/work" config user.email test@example.com
    git -C "$root/work" config user.name "Test"

    beads_ensure_remote_has_branch "$root/work" >/dev/null \
        || fail "seeding an empty clone failed"

    git -C "$root/remote.git" rev-parse HEAD >/dev/null 2>&1 \
        || fail "remote still has no branch after seeding"
}

test_existing_history_is_not_disturbed() {
    local root
    new_tmp_var root

    source_install

    git init -q --bare "$root/remote.git"
    git clone -q "$root/remote.git" "$root/work" 2>/dev/null
    git -C "$root/work" config user.email test@example.com
    git -C "$root/work" config user.name "Test"
    git -C "$root/work" commit -q --allow-empty -m "existing work"
    git -C "$root/work" push -q -u origin HEAD 2>/dev/null

    local before
    before="$(git -C "$root/work" rev-parse HEAD)"

    beads_ensure_remote_has_branch "$root/work" >/dev/null \
        || fail "seeding reported failure on a populated repo"

    [[ "$(git -C "$root/work" rev-parse HEAD)" == "$before" ]] \
        || fail "existing history must not be rewritten"
}

# --- reconciling an existing database ----------------------------------------
#
# `bd bootstrap` plans a clone from the remote, which fails when a local
# database already exists. A re-run must reconcile with pull semantics
# instead of attempting to recreate what is already there.

test_rerun_does_not_attempt_a_clone_over_an_existing_database() {
    local root
    local log
    new_tmp_var root
    log="$(tmp_artifact bd-calls.log)"
    : >"$log"

    source_install

    mkdir -p "$root/work/.beads/embeddeddolt" "$root/bin"
    cat >"$root/bin/bd" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$log"
STUB
    chmod +x "$root/bin/bd"

    PATH="$root/bin:$PATH" beads_reconcile_existing_database \
        "$root/work" "$root/work/.beads" >/dev/null \
        || fail "reconcile reported failure"

    ! grep -q '^bootstrap' "$log" \
        || fail "must not run 'bd bootstrap' over an existing database: $(cat "$log")"
    grep -q 'dolt pull' "$log" \
        || fail "expected a dolt pull to reconcile; got: $(cat "$log")"
}

# --- detecting a database vs. a bare config ----------------------------------
#
# Cloning an already bootstrapped command repo brings down .beads/config.yaml
# while the issue data stays on the Dolt remote. The directory is therefore
# present with no database behind it, and the two states must not be confused.

test_database_presence_is_probed_not_inferred_from_the_directory() {
    local root
    new_tmp_var root

    source_install

    mkdir -p "$root/work/.beads" "$root/bin"
    cat >"$root/bin/bd" <<'STUB'
#!/usr/bin/env bash
[ "$1" = where ] && exit 1
exit 0
STUB
    chmod +x "$root/bin/bd"

    ! PATH="$root/bin:$PATH" beads_database_exists "$root/work" "$root/work/.beads" \
        || fail "a .beads directory without a database must not count as one"
}

test_database_presence_is_reported_when_bd_resolves_a_workspace() {
    local root
    new_tmp_var root

    source_install

    mkdir -p "$root/work/.beads" "$root/bin"
    cat >"$root/bin/bd" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
    chmod +x "$root/bin/bd"

    PATH="$root/bin:$PATH" beads_database_exists "$root/work" "$root/work/.beads" \
        || fail "a resolvable workspace must count as an existing database"
}

# A second machine has config but no database. Pulling there fails outright
# with 'no beads database found'; the repo must be cloned from the remote.

test_config_without_a_database_clones_from_the_remote() {
    local root
    local log
    new_tmp_var root
    log="$(tmp_artifact bd-clone-calls.log)"
    : >"$log"

    source_install

    mkdir -p "$root/work/.beads" "$root/bin"
    : >"$root/work/.beads/config.yaml"
    cat >"$root/bin/bd" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$log"
[ "\$1" = where ] && exit 1
exit 0
STUB
    chmod +x "$root/bin/bd"

    # A second machine arrives by clone, so the repo always has history;
    # without it the branchless-remote guard fires before the branch here.
    git -C "$root/work" init -q
    git -C "$root/work" commit -q --allow-empty -m "seed"

    PATH="$root/bin:$PATH" beads_bootstrap \
        "$root/work" "git+https://example.com/repo.git" >/dev/null 2>&1 || true

    grep -q '^bootstrap' "$log" \
        || fail "expected 'bd bootstrap' to clone the database; got: $(cat "$log")"
    ! grep -q 'dolt pull' "$log" \
        || fail "must not pull into a nonexistent database: $(cat "$log")"
}

# --- install boundary --------------------------------------------------------

test_bootstrap_is_not_a_module() {
    source_install

    ! module_catalog | grep -q '^beads_bootstrap:' \
        || fail "bootstrap must not be selectable as an install module"
}

run_tests "beads-bootstrap"

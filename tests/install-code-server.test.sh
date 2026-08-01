#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

export LC_ALL=C

# The protected values these tests seed. They exist only inside the temporary
# HOME and inside assertions; every observation of reconciler output is
# searched for them, so a leak fails the suite instead of being printed.
SEEDED_PASSWORD="seeded-secret-do-not-log-8f2a"
SEEDED_CERT="/etc/ssl/private/code-server.crt"
SEEDED_CERT_KEY="/etc/ssl/private/code-server.key"

# Deterministic stand-in for /dev/urandom so generated-secret assertions are
# reproducible. The reconciler still reads it through the same local-entropy
# path it uses in production.
FAKE_ENTROPY_BYTES="0123456789abcdef0123456789abcdef0123456789abcdef"

config_path_for() {
    printf '%s/.config/code-server/config.yaml' "$1"
}

# Read one top-level key's raw value out of a flat code-server config without
# printing it. Callers hash or compare the result; they never echo it.
config_value() {
    local path="$1"
    local key="$2"
    local line

    line="$(grep "^$key:" "$path" || true)"
    [ -n "$line" ] || return 1
    line="${line#$key:}"
    # Strip the single separating space; the rest of the value stays verbatim.
    printf '%s' "${line# }"
}

# Stable fingerprint of a protected value, safe to print in a failure message.
fingerprint() {
    printf '%s' "$1" | cksum | awk '{ print $1 }'
}

file_mode() {
    local path="$1"

    if stat -c '%a' "$path" 2>/dev/null; then
        return 0
    fi
    stat -f '%Lp' "$path"
}

# One line per entry in the code-server config directory, used to prove no
# temporary or backup artifact leaked.
config_dir_listing() {
    local dir="$1"

    (cd "$dir" && find . | sort)
}

# Seed a flat code-server config file with caller-supplied lines.
seed_config() {
    local home="$1"
    shift
    local path

    path="$(config_path_for "$home")"
    mkdir -p "$(dirname "$path")"
    printf '%s\n' "$@" > "$path"
    chmod 600 "$path"
}

# Run the public reconciler against a temporary HOME with a controlled bind
# override and a controlled local-entropy source.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   exit status of reconcile_code_server_config
#   OBSERVED_OUTPUT   combined stdout/stderr of the call
run_reconcile() {
    local home="$1"
    local bind_override="${2-}"
    local out

    source_install

    out="$(tmp_artifact "reconcile.out")"
    OBSERVED_STATUS=0
    (
        HOME="$home"
        CODE_SERVER_BIND="$bind_override"
        CODE_SERVER_ENTROPY_SOURCE="$ENTROPY_FILE"
        reconcile_code_server_config
    ) > "$out" 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_OUTPUT="$(cat "$out")"
}

# Fail unless the observed output kept every protected value out of sight.
assert_output_redacted() {
    local context="$1"

    case "$OBSERVED_OUTPUT" in
        *"$SEEDED_PASSWORD"*) fail "$context: output disclosed the seeded password" ;;
        *"$FAKE_ENTROPY_BYTES"*) fail "$context: output disclosed raw entropy" ;;
    esac
    case "$OBSERVED_OUTPUT" in
        *"$SEEDED_CERT_KEY"*) fail "$context: output disclosed the certificate key path" ;;
    esac
}

# Every test shares one deterministic entropy file.
new_tmp_var ENTROPY_HOME
ENTROPY_FILE="$ENTROPY_HOME/entropy"
printf '%s' "$FAKE_ENTROPY_BYTES" > "$ENTROPY_FILE"

test_first_install_writes_secure_default_config() {
    local home
    local config
    local password

    new_tmp_var home
    run_reconcile "$home"

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "first install failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    [ -f "$config" ] || fail "expected a config file at the local path"
    [ -L "$config" ] && fail "config must be a regular file, not a symlink"

    [ "$(file_mode "$config")" == "600" ] ||
        fail "expected mode 600, got $(file_mode "$config")"

    [ "$(config_value "$config" bind-addr)" == "0.0.0.0:8080" ] ||
        fail "expected the first-install default bind"
    [ "$(config_value "$config" auth)" == "password" ] ||
        fail "expected password authentication to be enforced"
    [ "$(config_value "$config" cert)" == "true" ] ||
        fail "expected a generated HTTPS certificate to be enabled"

    password="$(config_value "$config" password)" ||
        fail "expected a generated password entry"
    [ -n "$password" ] || fail "expected a nonempty generated password"
    [ "${#password}" -ge 24 ] ||
        fail "expected a strong generated password, got ${#password} characters"

    assert_output_redacted "first install"
    case "$OBSERVED_OUTPUT" in
        *"$password"*) fail "first install: output disclosed the generated password" ;;
    esac
}

test_rerun_without_override_preserves_existing_bind() {
    local home
    local config

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 10.1.2.3:9443" \
        "auth: password" \
        "password: $SEEDED_PASSWORD" \
        "cert: true"

    run_reconcile "$home"

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "rerun failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    [ "$(config_value "$config" bind-addr)" == "10.1.2.3:9443" ] ||
        fail "a rerun without an override must preserve the existing bind"

    assert_output_redacted "bind preservation"
}

test_explicit_override_replaces_existing_bind() {
    local home
    local config

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 10.1.2.3:9443" \
        "auth: password" \
        "password: $SEEDED_PASSWORD" \
        "cert: true"

    run_reconcile "$home" "127.0.0.1:8443"

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "override run failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    [ "$(config_value "$config" bind-addr)" == "127.0.0.1:8443" ] ||
        fail "an explicit override must replace the existing bind"

    assert_output_redacted "bind override"
}

test_bracketed_ipv6_bind_survives_verbatim() {
    local home
    local config

    new_tmp_var home
    run_reconcile "$home" "[fe80::1%eth0]:8080"

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "IPv6 override failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    [ "$(config_value "$config" bind-addr)" == "[fe80::1%eth0]:8080" ] ||
        fail "a bracketed IPv6 bind must be written verbatim"

    # A preserved IPv6 value must also survive an unflagged rerun.
    run_reconcile "$home"
    [ "$(config_value "$config" bind-addr)" == "[fe80::1%eth0]:8080" ] ||
        fail "a bracketed IPv6 bind must survive a rerun without an override"
}

test_existing_password_is_preserved_not_rotated() {
    local home
    local config
    local before
    local after

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 0.0.0.0:8080" \
        "auth: password" \
        "password: $SEEDED_PASSWORD" \
        "cert: true"

    config="$(config_path_for "$home")"
    before="$(fingerprint "$(config_value "$config" password)")"

    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "reconcile failed: $OBSERVED_OUTPUT"

    after="$(fingerprint "$(config_value "$config" password)")"
    [ "$before" == "$after" ] ||
        fail "the existing password was rotated (fingerprint $before -> $after)"

    assert_output_redacted "password preservation"
}

test_explicit_certificate_material_is_preserved() {
    local home
    local config

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 0.0.0.0:8080" \
        "auth: password" \
        "password: $SEEDED_PASSWORD" \
        "cert: $SEEDED_CERT" \
        "cert-key: $SEEDED_CERT_KEY"

    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "reconcile failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    [ "$(fingerprint "$(config_value "$config" cert)")" == "$(fingerprint "$SEEDED_CERT")" ] ||
        fail "an explicit certificate path must be preserved"
    [ "$(fingerprint "$(config_value "$config" cert-key)")" == "$(fingerprint "$SEEDED_CERT_KEY")" ] ||
        fail "an explicit certificate key path must be preserved"

    assert_output_redacted "certificate preservation"
}

test_disabled_auth_and_transport_are_re_enforced() {
    local home
    local config

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 0.0.0.0:8080" \
        "auth: none" \
        "password: $SEEDED_PASSWORD" \
        "cert: false"

    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "reconcile failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    [ "$(config_value "$config" auth)" == "password" ] ||
        fail "password authentication must be re-enforced"
    [ "$(config_value "$config" cert)" == "true" ] ||
        fail "HTTPS must be re-enforced when no certificate material exists"
    [ "$(fingerprint "$(config_value "$config" password)")" == "$(fingerprint "$SEEDED_PASSWORD")" ] ||
        fail "re-enforcing auth must not rotate the existing password"
}

test_unknown_top_level_settings_survive() {
    local home
    local config

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 0.0.0.0:8080" \
        "auth: password" \
        "password: $SEEDED_PASSWORD" \
        "cert: true" \
        "disable-telemetry: true" \
        "user-data-dir: /srv/code-server/data" \
        "app-name: Local Editor"

    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "reconcile failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    [ "$(config_value "$config" disable-telemetry)" == "true" ] ||
        fail "unrelated setting disable-telemetry was lost"
    [ "$(config_value "$config" user-data-dir)" == "/srv/code-server/data" ] ||
        fail "unrelated setting user-data-dir was lost"
    [ "$(config_value "$config" app-name)" == "Local Editor" ] ||
        fail "unrelated setting app-name was lost"
}

test_absent_password_alone_is_generated() {
    local home
    local config
    local password

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 10.1.2.3:9443" \
        "cert: $SEEDED_CERT" \
        "cert-key: $SEEDED_CERT_KEY" \
        "disable-telemetry: true"

    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "reconcile failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    password="$(config_value "$config" password)" || fail "expected a generated password"
    [ "${#password}" -ge 24 ] || fail "expected a strong generated password"

    [ "$(config_value "$config" bind-addr)" == "10.1.2.3:9443" ] ||
        fail "generating a password must not disturb the bind value"
    [ "$(fingerprint "$(config_value "$config" cert)")" == "$(fingerprint "$SEEDED_CERT")" ] ||
        fail "generating a password must not disturb certificate material"
    [ "$(config_value "$config" disable-telemetry)" == "true" ] ||
        fail "generating a password must not disturb unrelated settings"

    assert_output_redacted "password generation"
}

# Inode, modification time, and mode: identical values on both sides of a run
# are the evidence that a no-change rerun did not touch the original.
file_identity() {
    stat -c '%i %Y %a' "$1" 2>/dev/null || stat -f '%i %m %Lp' "$1"
}

content_hash() {
    cksum < "$1" | awk '{ print $1, $2 }'
}

backup_paths() {
    local dir="$1"

    find "$dir" -maxdepth 1 -name 'config.yaml.backup.*' | sort
}

temp_paths() {
    local dir="$1"

    find "$dir" -maxdepth 1 -name 'config.yaml.tmp.*' | sort
}

# Run the reconciler with one publish step forced to fail.
#
# $3 selects the failing step: write or publish.
run_reconcile_injecting_failure() {
    local home="$1"
    local bind_override="$2"
    local failing="$3"
    local out

    source_install

    out="$(tmp_artifact "reconcile-fail.out")"
    OBSERVED_STATUS=0
    (
        HOME="$home"
        CODE_SERVER_BIND="$bind_override"
        CODE_SERVER_ENTROPY_SOURCE="$ENTROPY_FILE"

        cat() {
            [ "$failing" != "write" ] || return 1
            command cat "$@"
        }
        mv() {
            [ "$failing" != "publish" ] || return 1
            command mv "$@"
        }

        reconcile_code_server_config
    ) > "$out" 2>&1 || OBSERVED_STATUS=$?
    OBSERVED_OUTPUT="$(cat "$out")"
}

test_changed_config_is_backed_up_once_then_replaced() {
    local home
    local config
    local dir
    local original_hash
    local backups

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 0.0.0.0:8080" \
        "auth: none" \
        "password: $SEEDED_PASSWORD" \
        "cert: false"

    config="$(config_path_for "$home")"
    dir="$(dirname "$config")"
    original_hash="$(content_hash "$config")"
    # A permissive original must not hand its mode to the backup: the backup
    # carries the same password.
    chmod 644 "$config"

    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "reconcile failed: $OBSERVED_OUTPUT"

    backups="$(backup_paths "$dir")"
    [ "$(printf '%s\n' "$backups" | grep -c .)" -eq 1 ] ||
        fail "expected exactly one timestamped backup, got: $(printf '%s\n' "$backups" | grep -c .)"
    [ "$(content_hash "$backups")" == "$original_hash" ] ||
        fail "the backup must hold the original content"
    [ "$(file_mode "$backups")" == "600" ] ||
        fail "the backup must be mode 600, got $(file_mode "$backups")"

    [ "$(config_value "$config" auth)" == "password" ] ||
        fail "the replacement must carry the enforced values"
    [ "$(file_mode "$config")" == "600" ] ||
        fail "the replacement must be mode 600, got $(file_mode "$config")"
    [ -z "$(temp_paths "$dir")" ] || fail "a temporary file leaked: $(temp_paths "$dir")"

    assert_output_redacted "change replacement"
}

test_no_change_rerun_leaves_the_original_untouched() {
    local home
    local config
    local dir
    local before

    new_tmp_var home
    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "first run failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    dir="$(dirname "$config")"
    before="$(file_identity "$config")"

    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "rerun failed: $OBSERVED_OUTPUT"

    [ "$(file_identity "$config")" == "$before" ] ||
        fail "an unchanged rerun must not touch the original file"
    [ -z "$(backup_paths "$dir")" ] ||
        fail "an unchanged rerun must not create a backup: $(backup_paths "$dir")"
    [ -z "$(temp_paths "$dir")" ] || fail "a temporary file leaked: $(temp_paths "$dir")"
}

test_permissive_mode_is_tightened_without_a_backup() {
    local home
    local config
    local dir

    new_tmp_var home
    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "first run failed: $OBSERVED_OUTPUT"

    config="$(config_path_for "$home")"
    dir="$(dirname "$config")"
    chmod 644 "$config"

    run_reconcile "$home"
    [ "$OBSERVED_STATUS" -eq 0 ] || fail "rerun failed: $OBSERVED_OUTPUT"

    [ "$(file_mode "$config")" == "600" ] ||
        fail "a permissive config must be tightened to 600, got $(file_mode "$config")"
    [ -z "$(backup_paths "$dir")" ] ||
        fail "tightening the mode must not create a content backup"
}

test_symlinked_config_is_rejected() {
    local home
    local config
    local dir
    local elsewhere

    new_tmp_var home
    new_tmp_var elsewhere
    printf 'bind-addr: 0.0.0.0:8080\npassword: %s\n' "$SEEDED_PASSWORD" > "$elsewhere/planted.yaml"

    config="$(config_path_for "$home")"
    dir="$(dirname "$config")"
    mkdir -p "$dir"
    ln -s "$elsewhere/planted.yaml" "$config"

    run_reconcile "$home"

    [ "$OBSERVED_STATUS" -ne 0 ] || fail "a symlinked config must be rejected"
    [ -L "$config" ] || fail "the rejected symlink must be left in place"
    [ "$(content_hash "$elsewhere/planted.yaml")" == "$(cksum < "$elsewhere/planted.yaml" | awk '{ print $1, $2 }')" ] ||
        fail "the symlink target must not be rewritten"
    [ "$(config_value "$elsewhere/planted.yaml" bind-addr)" == "0.0.0.0:8080" ] ||
        fail "the symlink target must not be rewritten"
    [ -z "$(temp_paths "$dir")" ] || fail "a temporary file leaked: $(temp_paths "$dir")"

    case "$OBSERVED_OUTPUT" in
        *"regular file"*) ;;
        *) fail "rejection must explain the regular-file requirement: $OBSERVED_OUTPUT" ;;
    esac
    assert_output_redacted "symlink rejection"
}

test_injected_failure_preserves_the_original_and_cleans_up() {
    local home
    local config
    local dir
    local before
    local failing

    for failing in write publish; do
        new_tmp_var home
        seed_config "$home" \
            "bind-addr: 10.1.2.3:9443" \
            "auth: none" \
            "password: $SEEDED_PASSWORD" \
            "cert: true"

        config="$(config_path_for "$home")"
        dir="$(dirname "$config")"
        before="$(content_hash "$config")"

        run_reconcile_injecting_failure "$home" "" "$failing"

        [ "$OBSERVED_STATUS" -ne 0 ] ||
            fail "an injected $failing failure must fail the reconciler"
        [ "$(content_hash "$config")" == "$before" ] ||
            fail "an injected $failing failure corrupted the original config"
        [ -z "$(temp_paths "$dir")" ] ||
            fail "an injected $failing failure leaked: $(temp_paths "$dir")"
        [ -z "$(backup_paths "$dir")" ] ||
            fail "an injected $failing failure must not leave a backup"

        assert_output_redacted "injected $failing failure"
    done
}

test_protected_values_never_reach_an_execution_trace() {
    local home
    local config
    local trace
    local password

    new_tmp_var home
    seed_config "$home" \
        "bind-addr: 0.0.0.0:8080" \
        "auth: none" \
        "password: $SEEDED_PASSWORD" \
        "cert: $SEEDED_CERT" \
        "cert-key: $SEEDED_CERT_KEY"

    source_install

    trace="$(tmp_artifact "reconcile.trace")"
    (
        HOME="$home"
        CODE_SERVER_BIND=""
        CODE_SERVER_ENTROPY_SOURCE="$ENTROPY_FILE"
        set -x
        reconcile_code_server_config
    ) > "$trace" 2>&1 || fail "traced reconcile failed"

    config="$(config_path_for "$home")"
    password="$(config_value "$config" password)"

    grep -qF "$SEEDED_PASSWORD" "$trace" && fail "the trace disclosed the password"
    grep -qF "$SEEDED_CERT_KEY" "$trace" && fail "the trace disclosed the certificate key path"
    grep -qF "$password" "$trace" && fail "the trace disclosed the configured password"

    return 0
}

run_tests "code-server configuration"

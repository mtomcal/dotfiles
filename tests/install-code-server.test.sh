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

# ===========================================================================
# Service transition safety
# ===========================================================================

# A private host identity. It is used as a bind host so every operator-visible
# message can be searched for it; the endpoint's private name is not the
# operator's business in a diagnostic.
PRIVATE_BIND_HOST="editor.internal.example.net"

# The exact per-user unit the official installer provides. Tests assert against
# this literal rather than against whatever the implementation happens to build.
expected_unit() {
    printf 'code-server@%s.service' "${USER:-$(id -un)}"
}

# Drive the public service transition against a simulated systemd user manager
# and a simulated listener table.
#
# Caller-set inputs, all optional and reset by this function:
#   SERVICE_STATE_BEFORE    active | inactive              (default inactive)
#   PORT_OWNED_BY_OTHER     1 places an unrelated listener on the selected port
#   FAIL_VERBS              space-separated systemctl verbs forced to fail
#   START_LEAVES_INACTIVE   1 when start/restart returns 0 without activating
#   NO_LISTENER_UTILITY     1 when the host offers neither ss nor lsof
#   PREVIOUS_CONFIG         path restored on rollback (default none)
#
# Sets in the caller's shell:
#   OBSERVED_STATUS   exit status of transition_code_server_service
#   OBSERVED_OUTPUT   combined stdout/stderr
#   OBSERVED_CALLS    newline-separated log of external service/listener calls
#   SERVICE_STATE_AFTER   active | inactive, as the simulator finally recorded
run_transition() {
    local home="$1"
    local bind="$2"
    local restart_required="$3"
    local out
    local calls
    local state
    local port

    source_install

    out="$(tmp_artifact "transition.out")"
    calls="$(tmp_artifact "transition.calls")"
    state="$(tmp_artifact "transition.state")"
    : > "$calls"
    printf '%s' "${SERVICE_STATE_BEFORE:-inactive}" > "$state"

    # The port the simulated listener table answers about.
    port="${bind##*:}"

    OBSERVED_STATUS=0
    (
        HOME="$home"
        local fail_verbs="${FAIL_VERBS:-}"
        local owned_by_other="${PORT_OWNED_BY_OTHER:-0}"
        local start_leaves_inactive="${START_LEAVES_INACTIVE:-0}"
        local no_listener_utility="${NO_LISTENER_UTILITY:-0}"

        systemctl() {
            local verb=""
            local argument

            printf 'systemctl %s\n' "$*" >> "$calls"

            for argument in "$@"; do
                case "$argument" in
                    --*) ;;
                    *) verb="$argument"; break ;;
                esac
            done

            case " $fail_verbs " in
                *" $verb "*) return 1 ;;
            esac

            case "$verb" in
                stop)
                    printf 'inactive' > "$state"
                    ;;
                start|restart)
                    if [ "$start_leaves_inactive" != "1" ]; then
                        printf 'active' > "$state"
                    fi
                    ;;
                is-active)
                    [ "$(command cat "$state")" == "active" ]
                    return $?
                    ;;
            esac

            return 0
        }

        # The listener table: our own service listens whenever it is running,
        # and an unrelated process listens when the test placed one there.
        ss() {
            printf 'ss %s\n' "$*" >> "$calls"

            [ "$no_listener_utility" != "1" ] || return 127

            if [ "$(command cat "$state")" == "active" ]; then
                printf 'LISTEN 0 511 *:%s *:* users:(("code-server",pid=4242,fd=6))\n' "$port"
            fi
            if [ "$owned_by_other" == "1" ]; then
                printf 'LISTEN 0 128 *:%s *:* users:(("unrelated-daemon",pid=909,fd=3))\n' "$port"
            fi
            return 0
        }

        if [ "$no_listener_utility" == "1" ]; then
            # Neither standard utility resolves on this host.
            command() {
                if [ "$1" == "-v" ]; then
                    case "$2" in
                        ss|lsof) return 1 ;;
                    esac
                fi
                builtin command "$@"
            }
        fi

        transition_code_server_service "$bind" "$restart_required" "${PREVIOUS_CONFIG:-}"
    ) > "$out" 2>&1 || OBSERVED_STATUS=$?

    OBSERVED_OUTPUT="$(cat "$out")"
    OBSERVED_CALLS="$(cat "$calls")"
    SERVICE_STATE_AFTER="$(cat "$state")"

    unset SERVICE_STATE_BEFORE PORT_OWNED_BY_OTHER FAIL_VERBS
    unset START_LEAVES_INACTIVE NO_LISTENER_UTILITY PREVIOUS_CONFIG
}

# The observed output with terminal colour escapes removed, so a scan for
# numbers or identifiers sees only what the operator reads.
plain_output() {
    printf '%s' "$OBSERVED_OUTPUT" | sed 's/'$'\033''\[[0-9;]*m//g'
}

# Index of the first logged call matching $1, or the empty string.
call_index() {
    printf '%s\n' "$OBSERVED_CALLS" | grep -n -- "$1" | head -n 1 | cut -d: -f1
}

assert_call_ordered_before() {
    local earlier="$1"
    local later="$2"
    local earlier_index
    local later_index

    earlier_index="$(call_index "$earlier")"
    later_index="$(call_index "$later")"

    [ -n "$earlier_index" ] || fail "expected a call matching '$earlier' in: $OBSERVED_CALLS"
    [ -n "$later_index" ] || fail "expected a call matching '$later' in: $OBSERVED_CALLS"
    [ "$earlier_index" -lt "$later_index" ] ||
        fail "expected '$earlier' before '$later', got: $OBSERVED_CALLS"
}

assert_no_call() {
    case "$OBSERVED_CALLS" in
        *"$1"*) fail "unexpected call matching '$1' in: $OBSERVED_CALLS" ;;
    esac
}

test_free_selected_port_allows_the_transition() {
    local home

    new_tmp_var home
    SERVICE_STATE_BEFORE=inactive
    run_transition "$home" "0.0.0.0:8080" no

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "a free port must allow the transition: $OBSERVED_OUTPUT"
    [ "$SERVICE_STATE_AFTER" == "active" ] || fail "the service must be left running"
}

test_unrelated_listener_fails_without_choosing_another_port() {
    local home

    new_tmp_var home
    SERVICE_STATE_BEFORE=inactive
    PORT_OWNED_BY_OTHER=1
    run_transition "$home" "0.0.0.0:8080" no

    [ "$OBSERVED_STATUS" -ne 0 ] || fail "an unrelated listener must fail the transition"
    assert_no_call "start"
    assert_no_call "restart"
    [ "$SERVICE_STATE_AFTER" == "inactive" ] || fail "a rejected transition must not start the service"

    case "$OBSERVED_OUTPUT" in
        *8080*) ;;
        *) fail "the conflict must name the selected port: $OBSERVED_OUTPUT" ;;
    esac
    # No second port may be offered or silently substituted.
    printf '%s' "$(plain_output)" | grep -oE '[0-9]{2,5}' | grep -vx '8080' |
        grep -q . && fail "a rejected port must not be traded for another: $OBSERVED_OUTPUT"

    return 0
}

test_restart_stops_the_known_service_before_inspecting_its_own_port() {
    local home

    new_tmp_var home
    # The service is running and therefore owns the selected port. Nothing else
    # does. A transition that inspects the port first would call this a
    # conflict.
    SERVICE_STATE_BEFORE=active
    run_transition "$home" "0.0.0.0:8080" yes

    [ "$OBSERVED_STATUS" -eq 0 ] ||
        fail "the service's own listener must not be treated as a conflict: $OBSERVED_OUTPUT"
    assert_call_ordered_before "systemctl.*stop $(expected_unit)" "ss "
    assert_call_ordered_before "ss " "restart $(expected_unit)"
    [ "$SERVICE_STATE_AFTER" == "active" ] || fail "the service must be left running"
}

test_unchanged_running_service_is_never_asked_about_its_own_port() {
    local home

    new_tmp_var home
    SERVICE_STATE_BEFORE=active
    run_transition "$home" "0.0.0.0:8080" no

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "an unchanged running service must succeed: $OBSERVED_OUTPUT"
    assert_no_call "systemctl --user stop"
    assert_no_call "ss "
    [ "$SERVICE_STATE_AFTER" == "active" ] || fail "the service must stay running"
}

test_missing_listener_utility_fails_the_transition() {
    local home

    new_tmp_var home
    SERVICE_STATE_BEFORE=inactive
    NO_LISTENER_UTILITY=1
    run_transition "$home" "0.0.0.0:8080" no

    [ "$OBSERVED_STATUS" -ne 0 ] ||
        fail "an uninspectable port must fail rather than be assumed free"
    assert_no_call "start"
    [ "$SERVICE_STATE_AFTER" == "inactive" ] || fail "the service must not be started blindly"
}

# The systemctl verbs the transition issued, in order, as one line.
systemctl_verb_sequence() {
    printf '%s\n' "$OBSERVED_CALLS" |
        sed -n 's/^systemctl --user \([a-z-]*\) .*/\1/p' |
        tr '\n' ' ' |
        sed 's/ $//'
}

# Every systemctl call must address the per-user manager and the exact unit.
assert_every_service_call_targets_the_exact_unit() {
    local unit
    local line

    unit="$(expected_unit)"
    while IFS= read -r line; do
        case "$line" in
            systemctl\ *) ;;
            *) continue ;;
        esac
        case "$line" in
            "systemctl --user "*" $unit") ;;
            *) fail "a service call did not target --user $unit: $line" ;;
        esac
    done <<< "$OBSERVED_CALLS"
}

test_stopped_service_is_enabled_then_started_on_the_exact_unit() {
    local home

    new_tmp_var home
    SERVICE_STATE_BEFORE=inactive
    run_transition "$home" "0.0.0.0:8080" no

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "an unchanged stopped service must start: $OBSERVED_OUTPUT"
    [ "$(systemctl_verb_sequence)" == "is-active enable start is-active" ] ||
        fail "unexpected lifecycle: $(systemctl_verb_sequence)"
    assert_every_service_call_targets_the_exact_unit
}

test_changed_running_service_is_stopped_then_restarted_on_the_exact_unit() {
    local home

    new_tmp_var home
    SERVICE_STATE_BEFORE=active
    run_transition "$home" "0.0.0.0:8080" yes

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "a changed running service must restart: $OBSERVED_OUTPUT"
    [ "$(systemctl_verb_sequence)" == "is-active stop enable restart is-active" ] ||
        fail "unexpected lifecycle: $(systemctl_verb_sequence)"
    assert_every_service_call_targets_the_exact_unit
}

test_every_lifecycle_failure_fails_the_transition() {
    local home
    local case_name
    local before
    local restart

    # Each row: a lifecycle step that must not be allowed to fail quietly.
    for case_name in "enable:inactive:no" "start:inactive:no" "restart:active:yes"; do
        before="${case_name#*:}"
        restart="${before#*:}"
        before="${before%%:*}"

        new_tmp_var home
        SERVICE_STATE_BEFORE="$before"
        FAIL_VERBS="${case_name%%:*}"
        run_transition "$home" "0.0.0.0:8080" "$restart"

        [ "$OBSERVED_STATUS" -ne 0 ] ||
            fail "a failed ${case_name%%:*} must fail the transition"
        case "$(plain_output)" in
            *"code-server@"*) ;;
            *) fail "a failed ${case_name%%:*} must name the unit: $OBSERVED_OUTPUT" ;;
        esac
    done
}

test_a_started_service_that_is_not_active_fails_the_transition() {
    local home

    new_tmp_var home
    SERVICE_STATE_BEFORE=inactive
    START_LEAVES_INACTIVE=1
    run_transition "$home" "0.0.0.0:8080" no

    [ "$OBSERVED_STATUS" -ne 0 ] ||
        fail "a service that never became active must fail the transition"
    case "$(systemctl_verb_sequence)" in
        *"start is-active"*) ;;
        *) fail "active status must be required after start: $(systemctl_verb_sequence)" ;;
    esac
}

test_a_failing_is_active_check_fails_the_transition() {
    local home

    new_tmp_var home
    SERVICE_STATE_BEFORE=inactive
    FAIL_VERBS="is-active"
    run_transition "$home" "0.0.0.0:8080" no

    [ "$OBSERVED_STATUS" -ne 0 ] ||
        fail "an unavailable status check must fail the transition"
}

# Seed a home whose live configuration has already been migrated, plus the
# preserved previous configuration a failed transition must put back.
#
# Sets in the caller's shell: PREVIOUS_CONFIG, PRIOR_HASH
seed_migrated_config() {
    local home="$1"
    local config

    seed_config "$home" \
        "bind-addr: 0.0.0.0:8080" \
        "auth: password" \
        "password: $SEEDED_PASSWORD" \
        "cert: true"

    config="$(config_path_for "$home")"
    PREVIOUS_CONFIG="$config.backup.20260801_000000"
    cp -p "$config" "$PREVIOUS_CONFIG"
    PRIOR_HASH="$(content_hash "$PREVIOUS_CONFIG")"

    # The migrated configuration now differs from the preserved one.
    seed_config "$home" \
        "bind-addr: 0.0.0.0:9443" \
        "auth: password" \
        "password: $SEEDED_PASSWORD" \
        "cert: true"
}

test_failed_restart_restores_prior_config_and_running_service() {
    local home
    local config

    new_tmp_var home
    seed_migrated_config "$home"
    config="$(config_path_for "$home")"

    SERVICE_STATE_BEFORE=active
    FAIL_VERBS="restart"
    run_transition "$home" "0.0.0.0:8080" yes

    [ "$OBSERVED_STATUS" -ne 0 ] || fail "a failed restart must fail the transition"
    [ "$(content_hash "$config")" == "$PRIOR_HASH" ] ||
        fail "a failed restart must restore the previous local configuration"
    [ "$(file_mode "$config")" == "600" ] ||
        fail "the restored configuration must stay mode 600, got $(file_mode "$config")"
    [ "$SERVICE_STATE_AFTER" == "active" ] ||
        fail "a failed restart must bring the previously running service back"
    case "$(systemctl_verb_sequence)" in
        *"restart start") ;;
        *) fail "rollback must restart the prior service last: $(systemctl_verb_sequence)" ;;
    esac

    assert_output_redacted "failed restart rollback"
}

test_port_conflict_after_stop_rolls_back_the_prior_running_service() {
    local home
    local config

    new_tmp_var home
    seed_migrated_config "$home"
    config="$(config_path_for "$home")"

    # Once our own service is stopped, an unrelated process still holds the
    # port, so the endpoint cannot come back on the new configuration.
    SERVICE_STATE_BEFORE=active
    PORT_OWNED_BY_OTHER=1
    run_transition "$home" "0.0.0.0:8080" yes

    [ "$OBSERVED_STATUS" -ne 0 ] || fail "a port conflict must fail the transition"
    [ "$(content_hash "$config")" == "$PRIOR_HASH" ] ||
        fail "a port conflict must restore the previous local configuration"
    [ "$SERVICE_STATE_AFTER" == "active" ] ||
        fail "a port conflict must not leave the previously running endpoint down"

    assert_output_redacted "port conflict rollback"
}

test_originally_stopped_service_stays_stopped_after_a_failed_transition() {
    local home
    local config

    new_tmp_var home
    seed_migrated_config "$home"
    config="$(config_path_for "$home")"

    SERVICE_STATE_BEFORE=inactive
    FAIL_VERBS="start"
    run_transition "$home" "0.0.0.0:8080" no

    [ "$OBSERVED_STATUS" -ne 0 ] || fail "a failed start must fail the transition"
    [ "$(content_hash "$config")" == "$PRIOR_HASH" ] ||
        fail "a failed start must restore the previous local configuration"
    [ "$SERVICE_STATE_AFTER" == "inactive" ] ||
        fail "a service that was not running must stay stopped"
    [ "$(systemctl_verb_sequence)" == "is-active enable start" ] ||
        fail "rollback must not try to run a service that was stopped: $(systemctl_verb_sequence)"
}

# Probe the endpoint with a stubbed HTTP client.
#
# Sets: OBSERVED_STATUS, OBSERVED_OUTPUT, OBSERVED_CURL (the exact argument list)
run_verify_https() {
    local bind="$1"
    local curl_fails="${2:-0}"
    local out
    local args

    source_install

    out="$(tmp_artifact "https.out")"
    args="$(tmp_artifact "https.args")"
    : > "$args"

    OBSERVED_STATUS=0
    (
        curl() {
            printf '%s\n' "$*" >> "$args"
            [ "$curl_fails" != "1" ] || return 22
            return 0
        }

        verify_code_server_https "$bind"
    ) > "$out" 2>&1 || OBSERVED_STATUS=$?

    OBSERVED_OUTPUT="$(cat "$out")"
    OBSERVED_CURL="$(cat "$args")"
}

test_https_probe_uses_the_exact_configured_address() {
    run_verify_https "10.1.2.3:9443"

    [ "$OBSERVED_STATUS" -eq 0 ] || fail "a responding endpoint must pass: $OBSERVED_OUTPUT"
    [ "$OBSERVED_CURL" == "-kfsS https://10.1.2.3:9443/" ] ||
        fail "unexpected probe invocation: $OBSERVED_CURL"
}

test_wildcard_binds_probe_loopback() {
    run_verify_https "0.0.0.0:8080"
    [ "$OBSERVED_CURL" == "-kfsS https://127.0.0.1:8080/" ] ||
        fail "an IPv4 wildcard bind must be probed on loopback: $OBSERVED_CURL"

    run_verify_https "[::]:8443"
    [ "$OBSERVED_CURL" == "-kfsS https://[::1]:8443/" ] ||
        fail "an IPv6 wildcard bind must be probed on loopback: $OBSERVED_CURL"

    # A non-wildcard IPv6 bind is probed exactly as configured.
    run_verify_https "[fe80::1%eth0]:8443"
    [ "$OBSERVED_CURL" == "-kfsS https://[fe80::1%eth0]:8443/" ] ||
        fail "an explicit IPv6 bind must be probed verbatim: $OBSERVED_CURL"
}

test_failed_https_probe_fails_with_secret_safe_diagnostics() {
    run_verify_https "$PRIVATE_BIND_HOST:8443" 1

    [ "$OBSERVED_STATUS" -ne 0 ] || fail "an unresponsive endpoint must fail verification"

    case "$OBSERVED_CURL" in
        *"http://"*) fail "the probe must never fall back to plain HTTP: $OBSERVED_CURL" ;;
    esac
    case "$(plain_output)" in
        *"$PRIVATE_BIND_HOST"*) fail "diagnostics disclosed a private host identity: $OBSERVED_OUTPUT" ;;
        *"$SEEDED_PASSWORD"*) fail "diagnostics disclosed a password" ;;
        *"$SEEDED_CERT_KEY"*) fail "diagnostics disclosed certificate material" ;;
        *http://*) fail "diagnostics offered a plain-HTTP endpoint: $OBSERVED_OUTPUT" ;;
        *ufw*|*iptables*|*firewall*) fail "diagnostics proposed a firewall change: $OBSERVED_OUTPUT" ;;
    esac
    case "$(plain_output)" in
        *8443*) ;;
        *) fail "diagnostics must identify the endpoint port: $OBSERVED_OUTPUT" ;;
    esac

    return 0
}

run_tests "code-server configuration"

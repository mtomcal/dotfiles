#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

COMMON_MINIMAL="base_tools neovim nvim_config tmux_config herdr herdr_config herdr_integrations"
COMMON_WORK="base_tools neovim nvim_config tmux_config herdr herdr_config python tui_tools copilot herdr_integrations"
COMMON_FULL="base_tools neovim nvim_config tmux_config herdr herdr_config zsh_ohmyzsh zsh_config python golang_full nodejs tui_tools codex codex_sandbox claude playwright pi pi_sandbox copilot herdr_integrations"
MACOS_EDITOR_ADDITIONS="vscode vscode_config"

expanded_modules() {
    local profile="$1"
    local modules=()

    modules=($(expand_profile "$profile"))
    printf '%s' "${modules[*]}"
}

assert_expansion() {
    local os="$1"
    local profile="$2"
    local expected="$3"
    local actual

    OS="$os"
    actual="$(expanded_modules "$profile")"
    [[ "$actual" == "$expected" ]] || fail "$os $profile expanded to: $actual (expected: $expected)"
}

# ---------------------------------------------------------------------------
# Cycle A — one post-detection profile expansion path
# ---------------------------------------------------------------------------

test_macos_profiles_expand_to_python_and_desktop_editor() {
    source_install

    assert_expansion macos full "$COMMON_FULL $MACOS_EDITOR_ADDITIONS"
    assert_expansion macos work "$COMMON_WORK $MACOS_EDITOR_ADDITIONS"
    assert_expansion macos minimal "$COMMON_MINIMAL"
}

test_ubuntu_profiles_expand_to_python_without_desktop_editor() {
    source_install

    assert_expansion ubuntu full "$COMMON_FULL"
    assert_expansion ubuntu work "$COMMON_WORK"
    assert_expansion ubuntu minimal "$COMMON_MINIMAL"
}

test_no_standard_profile_expands_to_code_server() {
    local os
    local profile
    local modules

    source_install

    for os in macos ubuntu; do
        for profile in full minimal work; do
            OS="$os"
            modules=" $(expanded_modules "$profile") "
            [[ "$modules" != *" code_server "* ]] || fail "$os $profile profile selected code_server"
        done
    done
}

test_expand_profile_rejects_unknown_profile() {
    local status=0

    source_install

    OS="ubuntu"
    expand_profile bogus >/dev/null 2>&1 || status=$?
    [[ "$status" -ne 0 ]] || fail "expected unknown profile to fail expansion"
}

test_cli_profile_defers_expansion_until_after_detection() {
    source_install

    OS=""
    parse_arguments --profile full

    [[ "${#SELECTED_MODULES[@]}" -eq 0 ]] || fail "expected profile expansion to be deferred past detection, got: ${SELECTED_MODULES[*]}"
}

test_interactive_profile_menu_uses_shared_expansion() {
    local tmp
    local choice
    local profile

    source_install
    tmp="$(new_tmp)"

    for choice in 1:full 2:minimal 3:work; do
        profile="${choice#*:}"
        OS="macos"
        SELECTED_MODULES=()
        show_profile_menu <<< "${choice%%:*}" > "$tmp/menu-$profile.out"
        [[ "${SELECTED_MODULES[*]}" == "$(expanded_modules "$profile")" ]] ||
            fail "menu choice ${choice%%:*} selected: ${SELECTED_MODULES[*]}"
    done
}

# ---------------------------------------------------------------------------
# Cycle B — conditional dependency ordering
# ---------------------------------------------------------------------------

# Stub `command -v` lookups: every name listed in $1 (space separated) is
# reported present, everything else absent.
stub_present_commands() {
    PRESENT_COMMANDS=" $1 "

    command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$PRESENT_COMMANDS" == *" $2 "* ]]; then
                return 0
            fi
            return 1
        fi
        builtin command "$@"
    }
}

resolved_modules() {
    local resolved=()

    resolved=($(resolve_dependencies "$@" 2>/dev/null))
    printf '%s' "${resolved[*]}"
}

test_macos_vscode_config_inserts_desktop_editor_only_when_code_is_absent() {
    source_install
    OS="macos"

    stub_present_commands ""
    [[ "$(resolved_modules vscode_config)" == "vscode vscode_config" ]] ||
        fail "expected vscode before vscode_config when code is absent, got: $(resolved_modules vscode_config)"

    stub_present_commands "code"
    [[ "$(resolved_modules vscode_config)" == "vscode_config" ]] ||
        fail "expected no desktop dependency when code is present, got: $(resolved_modules vscode_config)"

    unset -f command
}

test_linux_vscode_config_does_not_insert_desktop_editor() {
    source_install
    OS="ubuntu"

    stub_present_commands ""
    [[ "$(resolved_modules vscode_config)" == "vscode_config" ]] ||
        fail "expected no desktop dependency outside macOS, got: $(resolved_modules vscode_config)"

    unset -f command
}

test_code_server_inserts_base_tools_only_when_curl_is_absent() {
    source_install
    OS="ubuntu"

    stub_present_commands ""
    [[ "$(resolved_modules code_server)" == "base_tools code_server" ]] ||
        fail "expected base_tools before code_server when curl is absent, got: $(resolved_modules code_server)"

    stub_present_commands "curl"
    [[ "$(resolved_modules code_server)" == "code_server" ]] ||
        fail "expected no curl dependency when curl is present, got: $(resolved_modules code_server)"

    unset -f command
}

test_python_module_resolves_without_dependencies() {
    source_install
    OS="ubuntu"

    stub_present_commands ""
    [[ "$(resolved_modules python)" == "python" ]] ||
        fail "expected python to resolve alone, got: $(resolved_modules python)"

    unset -f command
}

test_dependency_resolution_deduplicates_editor_modules_preserving_order() {
    local actual

    source_install
    OS="macos"
    stub_present_commands ""

    actual="$(resolved_modules vscode_config vscode python vscode_config)"
    [[ "$actual" == "vscode vscode_config python" ]] ||
        fail "expected deduplicated order 'vscode vscode_config python', got: $actual"

    unset -f command
}

test_macos_full_profile_resolves_desktop_editor_before_configuration() {
    local actual

    source_install
    OS="macos"
    stub_present_commands "git nvim zsh tmux curl jq herdr npm docker"

    actual=" $(resolved_modules $(expand_profile full)) "
    [[ "$actual" == *" vscode vscode_config "* ]] ||
        fail "expected vscode immediately before vscode_config in resolved full profile, got:$actual"
    [[ "$actual" != *" code_server "* ]] || fail "resolved full profile selected code_server"

    unset -f command
}

# ---------------------------------------------------------------------------
# Cycle C — code-server bind input boundary
# ---------------------------------------------------------------------------

snapshot_tree() {
    local root="$1"
    local path

    (
        cd "$root" || exit 1
        find . -mindepth 1 | LC_ALL=C sort | while IFS= read -r path; do
            if [ -f "$path" ] && [ ! -L "$path" ]; then
                printf '%s %s\n' "$path" "$(cksum < "$path")"
            else
                printf '%s non-file\n' "$path"
            fi
        done
    )
}

# Parse arguments in a subshell so a rejected value cannot leak state, and
# report the exit status plus any filesystem change under HOME.
parse_bind_argument() {
    local home="$1"
    shift
    local status=0

    (
        HOME="$home" parse_arguments "$@"
    ) >/dev/null 2>&1 || status=$?

    printf '%s' "$status"
}

test_code_server_bind_accepts_valid_addresses_and_ports() {
    local value

    source_install

    for value in "0.0.0.0:8080" "127.0.0.1:1" "localhost:65535" "code.internal.example:443" "[::1]:8080" "[fe80::1]:8443"; do
        CODE_SERVER_BIND=""
        parse_arguments --code-server-bind "$value"
        [[ "$CODE_SERVER_BIND" == "$value" ]] ||
            fail "expected bind '$value' to be retained exactly, got: '$CODE_SERVER_BIND'"
    done
}

test_code_server_bind_splits_host_and_port() {
    source_install

    [[ "$(split_code_server_bind "0.0.0.0:8080")" == "0.0.0.0 8080" ]] ||
        fail "expected IPv4 bind split, got: $(split_code_server_bind "0.0.0.0:8080")"
    [[ "$(split_code_server_bind "[::1]:8443")" == "::1 8443" ]] ||
        fail "expected bracketed IPv6 bind split without brackets, got: $(split_code_server_bind "[::1]:8443")"
}

test_code_server_bind_rejects_malformed_values() {
    local home
    local value
    local status

    source_install
    home="$(new_tmp)"

    for value in "" ":8080" "localhost" "localhost:" "localhost:https" "localhost:0" "localhost:65536" "localhost:080808" "::1:8080" "[::1:8080" "::1]:8080" "localhost:80:80" "localhost: 80" "[]:8080"; do
        status="$(parse_bind_argument "$home" --code-server-bind "$value")"
        [[ "$status" -ne 0 ]] || fail "expected bind '$value' to be rejected"
    done

    status="$(parse_bind_argument "$home" --code-server-bind)"
    [[ "$status" -ne 0 ]] || fail "expected missing bind argument to be rejected"
}

test_valid_code_server_bind_writes_nothing_to_disk() {
    local home
    local before
    local after

    source_install
    home="$(new_tmp)"
    mkdir -p "$home/.config"
    before="$(snapshot_tree "$home")"

    HOME="$home" parse_arguments --code-server-bind "10.0.0.5:8443"
    after="$(snapshot_tree "$home")"

    [[ "$CODE_SERVER_BIND" == "10.0.0.5:8443" ]] || fail "expected runtime bind state to be retained"
    [[ "$before" == "$after" ]] || fail "expected bind parsing to persist nothing; HOME changed"
}

# Run main with every side-effecting seam replaced by sentinels that record
# that they ran, so a bind value that escapes validation is observable.
run_main_with_dispatch_sentinels() {
    local sentinel_dir="$1"
    shift
    local status=0

    (
        SENTINEL_DIR="$sentinel_dir"
        HOME="$sentinel_dir/home"

        detect_os() {
            OS="ubuntu"
            PACKAGE_MANAGER="apt"
            printf 'detect_os\n' >> "$SENTINEL_DIR/calls"
        }
        setup_package_manager() { :; }
        update_package_manager() { printf 'update_package_manager\n' >> "$SENTINEL_DIR/calls"; }
        show_installation_summary() { printf 'show_installation_summary\n' >> "$SENTINEL_DIR/calls"; return 0; }
        install_code_server() { printf 'install_code_server\n' >> "$SENTINEL_DIR/calls"; return 0; }
        install_base_tools() { printf 'install_base_tools\n' >> "$SENTINEL_DIR/calls"; return 0; }

        main "$@"
    ) >"$sentinel_dir/main.out" 2>&1 || status=$?

    printf '%s' "$status"
}

test_invalid_bind_never_reaches_code_server_dispatch() {
    local tmp
    local status
    local before
    local after

    source_install
    tmp="$(new_tmp)"
    mkdir -p "$tmp/home"
    : > "$tmp/calls"
    before="$(snapshot_tree "$tmp/home")"

    status="$(run_main_with_dispatch_sentinels "$tmp" --modules code_server --code-server-bind "localhost:0")"
    after="$(snapshot_tree "$tmp/home")"

    [[ "$status" -ne 0 ]] || fail "expected invalid bind to fail the run"
    [[ ! -s "$tmp/calls" ]] || fail "expected no orchestration after invalid bind, got: $(cat "$tmp/calls" | tr '\n' ' ')"
    [[ "$before" == "$after" ]] || fail "expected no filesystem changes after invalid bind"
}

# ---------------------------------------------------------------------------
# Cycle D — dispatch, continuation, and completion notices
# ---------------------------------------------------------------------------

EDITOR_MODULES="python vscode vscode_config code_server"

test_custom_menu_offers_every_module_including_editor_modules() {
    local tmp
    local line
    local keys=()
    local labels=()
    local count
    local module
    local index

    source_install
    tmp="$(new_tmp)"

    while IFS= read -r line; do
        keys+=("${line%%:*}")
        labels+=("${line#*:}")
    done < <(custom_menu_options)
    count=${#keys[@]}

    for module in $EDITOR_MODULES; do
        [[ " ${keys[*]} " == *" $module "* ]] || fail "custom menu is missing module: $module"
    done

    clear() { :; }
    SELECTED_MODULES=()
    show_custom_menu > "$tmp/menu.out" <<EOF
$((count + 1))
$((count + 2))
EOF
    unset -f clear

    [[ "${SELECTED_MODULES[*]}" == "${keys[*]}" ]] ||
        fail "custom menu selected: ${SELECTED_MODULES[*]} (expected: ${keys[*]})"

    index=0
    while [ "$index" -lt "$count" ]; do
        grep -Fq "${labels[$index]}" "$tmp/menu.out" ||
            fail "custom menu output is missing label: ${labels[$index]}"
        index=$((index + 1))
    done
}

test_help_documents_editor_modules_and_bind_flag() {
    local tmp
    local module

    source_install
    tmp="$(new_tmp)"
    show_help > "$tmp/help.out"

    for module in $EDITOR_MODULES; do
        grep -Eq "^  $module +[A-Za-z]" "$tmp/help.out" ||
            fail "help output is missing a module line for: $module"
    done

    grep -Eq -- "^  --code-server-bind +[A-Za-z]" "$tmp/help.out" ||
        fail "help output is missing the --code-server-bind flag"
}

test_installation_summary_labels_every_editor_module() {
    local tmp
    local bullets
    local distinct

    source_install
    tmp="$(new_tmp)"

    SELECTED_MODULES=($EDITOR_MODULES)
    show_installation_summary < /dev/null > "$tmp/summary.out"

    bullets="$(grep -c '•' "$tmp/summary.out" || true)"
    distinct="$(grep '•' "$tmp/summary.out" | LC_ALL=C sort -u | wc -l | tr -d ' ')"

    [[ "$bullets" -eq 4 ]] || fail "expected one summary label per editor module, got $bullets"
    [[ "$distinct" -eq 4 ]] || fail "expected distinct summary labels, got $distinct"
}

test_execute_modules_dispatches_every_editor_module() {
    local tmp
    local log

    source_install
    tmp="$(new_tmp)"
    log="$tmp/dispatch.log"

    install_python() { printf 'install_python\n' >> "$log"; }
    install_vscode() { printf 'install_vscode\n' >> "$log"; }
    configure_vscode() { printf 'configure_vscode\n' >> "$log"; }
    install_code_server() { printf 'install_code_server\n' >> "$log"; }

    FAILED_MODULES=()
    COMPLETED_MODULES=()
    execute_modules $EDITOR_MODULES > "$tmp/execute.out"

    [[ "$(tr '\n' ' ' < "$log")" == "install_python install_vscode configure_vscode install_code_server " ]] ||
        fail "unexpected dispatch order: $(tr '\n' ' ' < "$log")"
    [[ "${COMPLETED_MODULES[*]}" == "$EDITOR_MODULES" ]] ||
        fail "expected all editor modules completed, got: ${COMPLETED_MODULES[*]}"
    [[ "${#FAILED_MODULES[@]}" -eq 0 ]] || fail "unexpected failures: ${FAILED_MODULES[*]}"
}

test_unknown_module_fails_loudly_instead_of_being_skipped() {
    local tmp
    local log

    source_install
    tmp="$(new_tmp)"
    log="$tmp/unrelated.log"

    configure_tmux() { printf 'configure_tmux\n' >> "$log"; }

    FAILED_MODULES=()
    COMPLETED_MODULES=()
    execute_modules not_a_module tmux_config > "$tmp/execute.out" 2>&1

    [[ "${FAILED_MODULES[*]}" == "not_a_module" ]] ||
        fail "expected an unknown module to be reported failed, got: ${FAILED_MODULES[*]}"
    grep -qi "unknown module" "$tmp/execute.out" || fail "expected an unknown-module diagnostic"
    [[ "${COMPLETED_MODULES[*]}" == "tmux_config" ]] ||
        fail "expected known modules to continue, got: ${COMPLETED_MODULES[*]}"
}

test_unsupported_desktop_modules_fail_only_themselves_on_linux() {
    local tmp
    local log

    source_install
    tmp="$(new_tmp)"
    log="$tmp/unrelated.log"
    OS="ubuntu"

    configure_tmux() { printf 'configure_tmux\n' >> "$log"; }
    install_package() { printf 'install_package %s\n' "$*" >> "$log"; }

    FAILED_MODULES=()
    COMPLETED_MODULES=()
    execute_modules vscode vscode_config tmux_config > "$tmp/execute.out" 2>&1

    [[ "${FAILED_MODULES[*]}" == "vscode vscode_config" ]] ||
        fail "expected only desktop modules to fail, got: ${FAILED_MODULES[*]}"
    [[ "$(grep -ci 'supported on macOS only' "$tmp/execute.out")" -eq 2 ]] ||
        fail "expected both desktop modules to report supported-platform guidance"
    [[ "${COMPLETED_MODULES[*]}" == "tmux_config" ]] ||
        fail "expected unrelated module to continue, got: ${COMPLETED_MODULES[*]}"
    [[ "$(tr '\n' ' ' < "$log")" == "configure_tmux " ]] ||
        fail "expected no substitute editor install, log: $(tr '\n' ' ' < "$log")"
}

test_unsupported_code_server_fails_only_itself_on_macos() {
    local tmp
    local log

    source_install
    tmp="$(new_tmp)"
    log="$tmp/unrelated.log"
    OS="macos"

    configure_tmux() { printf 'configure_tmux\n' >> "$log"; }
    install_package() { printf 'install_package %s\n' "$*" >> "$log"; }

    FAILED_MODULES=()
    COMPLETED_MODULES=()
    execute_modules code_server tmux_config > "$tmp/execute.out" 2>&1

    [[ "${FAILED_MODULES[*]}" == "code_server" ]] ||
        fail "expected only code_server to fail, got: ${FAILED_MODULES[*]}"
    grep -qi 'supported on Ubuntu/Debian only' "$tmp/execute.out" ||
        fail "expected code_server to report supported-platform guidance"
    [[ "${COMPLETED_MODULES[*]}" == "tmux_config" ]] ||
        fail "expected unrelated module to continue, got: ${COMPLETED_MODULES[*]}"
    [[ "$(tr '\n' ' ' < "$log")" == "configure_tmux " ]] ||
        fail "expected no code-server service work, log: $(tr '\n' ' ' < "$log")"
}

notices_output() {
    local out="$1"
    shift

    COMPLETED_MODULES=()
    if [ "$#" -gt 0 ]; then
        COMPLETED_MODULES=("$@")
    fi
    show_editor_completion_notices > "$out" 2>&1
}

test_settings_sync_notice_requires_successful_desktop_configuration() {
    local tmp

    source_install
    tmp="$(new_tmp)"
    OS="macos"

    notices_output "$tmp/success.out" vscode_config
    grep -qi "settings sync" "$tmp/success.out" || fail "expected Settings Sync notice after successful vscode_config"
    grep -qi "manual" "$tmp/success.out" || fail "expected the Settings Sync action to be described as manual"
    grep -qiE "(automatically|already|has been|was) disabled|installer (disables|disabled|enforces)" "$tmp/success.out" &&
        fail "Settings Sync notice must not claim enforcement"

    SELECTED_MODULES=(vscode vscode_config)
    FAILED_MODULES=(vscode_config)
    notices_output "$tmp/failed.out" vscode
    grep -qi "settings sync" "$tmp/failed.out" && fail "no Settings Sync notice after a failed vscode_config"

    FAILED_MODULES=()
    notices_output "$tmp/unrun.out"
    grep -qi "settings sync" "$tmp/unrun.out" && fail "no Settings Sync notice when vscode_config never ran"

    return 0
}

test_code_server_notice_requires_successful_service_and_hides_secrets() {
    local tmp
    local home

    source_install
    tmp="$(new_tmp)"
    home="$tmp/home"
    mkdir -p "$home/.config/code-server"
    printf 'bind-addr: 0.0.0.0:8080\npassword: sentinel-not-for-logs\ncert: true\n' \
        > "$home/.config/code-server/config.yaml"

    OS="ubuntu"
    CODE_SERVER_BIND="10.0.0.5:8443"
    SELECTED_MODULES=(code_server)
    FAILED_MODULES=()

    HOME="$home" notices_output "$tmp/success.out" code_server
    grep -Fq '~/.config/code-server/config.yaml' "$tmp/success.out" ||
        fail "expected the local code-server config path in the notice"
    grep -qi "https" "$tmp/success.out" || fail "expected HTTPS guidance"
    grep -qi "password authentication" "$tmp/success.out" || fail "expected password authentication guidance"
    grep -qi "certificate" "$tmp/success.out" || fail "expected generated certificate guidance"
    grep -qi "trusted" "$tmp/success.out" || fail "expected trusted-network guidance"
    grep -Fq "sentinel-not-for-logs" "$tmp/success.out" && fail "notice exposed the local code-server password"
    grep -qE 'password: *[^ ]' "$tmp/success.out" && fail "notice printed a password value"

    FAILED_MODULES=(code_server)
    notices_output "$tmp/failed.out"
    grep -Fq 'code-server' "$tmp/failed.out" && fail "no code-server notice after a failed module"

    return 0
}

test_main_binds_orchestration_phases_in_required_order() {
    local tmp
    local log
    local status=0
    local expected

    source_install
    tmp="$(new_tmp)"
    log="$tmp/calls"

    (
        LOG="$log"

        parse_arguments() {
            printf 'parse_arguments:%s\n' "$*" >> "$LOG"
            REQUESTED_PROFILE="work"
        }
        detect_os() {
            printf 'detect_os\n' >> "$LOG"
            OS="macos"
            PACKAGE_MANAGER="brew"
        }
        expand_profile() {
            printf 'expand_profile:os=%s:%s\n' "$OS" "$1" >> "$LOG"
            printf '%s\n' vscode vscode_config
        }
        setup_package_manager() { :; }
        modules_require_package_manager_update() { return 1; }
        resolve_dependencies() {
            printf 'resolve_dependencies:%s\n' "$*" >> "$LOG"
            printf '%s\n' "$@"
        }
        show_installation_summary() {
            printf 'show_installation_summary:%s\n' "${SELECTED_MODULES[*]}" >> "$LOG"
            return 0
        }
        execute_modules() {
            printf 'execute_modules:%s\n' "$*" >> "$LOG"
            COMPLETED_MODULES=("$@")
        }
        show_editor_completion_notices() {
            printf 'show_editor_completion_notices:%s\n' "${COMPLETED_MODULES[*]}" >> "$LOG"
        }

        main --profile work
    ) > "$tmp/main.out" 2>&1 || status=$?

    expected="parse_arguments:--profile work
detect_os
expand_profile:os=macos:work
resolve_dependencies:vscode vscode_config
show_installation_summary:vscode vscode_config
execute_modules:vscode vscode_config
show_editor_completion_notices:vscode vscode_config"

    [[ "$status" -eq 0 ]] || fail "expected main to succeed, got status $status: $(cat "$tmp/main.out")"
    [[ "$(cat "$log")" == "$expected" ]] || fail "unexpected orchestration order:
$(cat "$log")"
}

run_tests "install editor orchestration"

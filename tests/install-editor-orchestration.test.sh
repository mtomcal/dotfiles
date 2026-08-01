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
    new_tmp_var tmp

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

# Drive a public entry point (`main` or `parse_arguments`) with a disposable
# HOME, working directory, and TMPDIR, plus a code-server service stub that
# records the bind value it actually received.
#
# Sets in the caller's shell:
#   OBSERVED_STATUS     exit status of the entry point
#   OBSERVED_CALLS      path to the ordered orchestration call log
#   OBSERVED_BIND_FILE  path written only when the service stub ran
#   OBSERVED_PERSISTED  names of any root that changed ("" when nothing did)
run_under_observation() {
    local work="$1"
    local entry="$2"
    shift 2
    local before_home before_cwd before_tmp before_repo
    local after_home after_cwd after_tmp after_repo

    mkdir -p "$work/home" "$work/cwd" "$work/tmpdir" "$work/evidence"
    : > "$work/calls"

    OBSERVED_CALLS="$work/calls"
    OBSERVED_BIND_FILE="$work/evidence/bind"
    OBSERVED_STATUS=0
    OBSERVED_PERSISTED=""

    before_home="$(snapshot_tree "$work/home")"
    before_cwd="$(snapshot_tree "$work/cwd")"
    before_tmp="$(snapshot_tree "$work/tmpdir")"
    before_repo="$(git -C "$DOTFILES_DIR" status --porcelain)"

    (
        OBSERVED="$work"
        cd "$work/cwd" || exit 99
        HOME="$work/home"
        TMPDIR="$work/tmpdir"
        export HOME TMPDIR

        detect_os() {
            printf 'detect_os\n' >> "$OBSERVED/calls"
            OS="ubuntu"
            PACKAGE_MANAGER="apt"
        }
        setup_package_manager() { printf 'setup_package_manager\n' >> "$OBSERVED/calls"; }
        update_package_manager() { printf 'update_package_manager\n' >> "$OBSERVED/calls"; }
        show_installation_summary() {
            printf 'show_installation_summary:%s\n' "${SELECTED_MODULES[*]}" >> "$OBSERVED/calls"
            return 0
        }
        install_base_tools() { printf 'install_base_tools\n' >> "$OBSERVED/calls"; }
        install_code_server() {
            printf 'install_code_server\n' >> "$OBSERVED/calls"
            printf '%s' "$CODE_SERVER_BIND" > "$OBSERVED/evidence/bind"
        }
        show_editor_completion_notices() {
            printf 'show_editor_completion_notices\n' >> "$OBSERVED/calls"
        }

        if [ "$1" == "--parse-only" ]; then
            shift
            parse_arguments "$@"
            printf '%s' "$CODE_SERVER_BIND" > "$OBSERVED/evidence/bind"
        else
            main "$@"
        fi
    ) > "$work/entry.out" 2>&1 || OBSERVED_STATUS=$?

    after_home="$(snapshot_tree "$work/home")"
    after_cwd="$(snapshot_tree "$work/cwd")"
    after_tmp="$(snapshot_tree "$work/tmpdir")"
    after_repo="$(git -C "$DOTFILES_DIR" status --porcelain)"

    [[ "$before_home" == "$after_home" ]] || OBSERVED_PERSISTED="$OBSERVED_PERSISTED HOME"
    [[ "$before_cwd" == "$after_cwd" ]] || OBSERVED_PERSISTED="$OBSERVED_PERSISTED CWD"
    [[ "$before_tmp" == "$after_tmp" ]] || OBSERVED_PERSISTED="$OBSERVED_PERSISTED TMPDIR"
    [[ "$before_repo" == "$after_repo" ]] || OBSERVED_PERSISTED="$OBSERVED_PERSISTED WORKTREE"

    if [ "$entry" == "parse" ]; then
        return 0
    fi

    return 0
}

run_main_observed() {
    local work="$1"
    shift

    run_under_observation "$work" main "$@"
}

run_parse_observed() {
    local work="$1"
    shift

    run_under_observation "$work" parse --parse-only "$@"
}

VALID_BINDS="0.0.0.0:8080
127.0.0.1:1
255.255.255.255:8080
10.0.0.5:8443
localhost:65535
code.internal.example:443
a-b.example.com:80
1.example.com:80
[::1]:8080
[::]:8080
[fe80::1]:8443
[fe80::1%eth0]:8443
[fe80::1%eth0.100]:8443
[fe80::1%en0]:8443
[fe80::1%wlan-1]:8443
[fe80::1%2]:8443
[2001:db8:85a3:0:0:8a2e:370:7334]:443
[::ffff:192.168.1.1]:8080"

# Every one of these must be rejected. The bracketed entries are the shapes
# that a shape-only pattern accepts but that are not addresses at all.
MALFORMED_BINDS="
:8080
localhost
localhost:
localhost:https
localhost:0
localhost:65536
localhost:080808
localhost:80:80
localhost: 80
::1:8080
[::1:8080
::1]:8080
[]:8080
[:::]:8080
[.]:8080
[%]:8080
[192.168.1.1]:8080
[localhost]:8080
[gg::1]:8080
[1:2:3:4:5:6:7:8:9]:8080
[1::2::3]:8080
[fe80::1%]:8443
[::1]:0
-:8080
..:8080
.localhost:8080
localhost-:8080
-localhost:8080
256.1.1.1:8080
01.2.3.4:8080
999.999.999.999:8080
1.2.3:8080
1.2.3.4.5:8080
[fe80::1%bad zone]:8443
[fe80::1%../../escape]:8443
[fe80::1%\$()]:8443
[fe80::1%;reboot]:8443
[fe80::1%.]:8443"

test_code_server_bind_accepts_valid_addresses_and_ports() {
    local value

    source_install

    while IFS= read -r value; do
        [ -n "$value" ] || continue
        CODE_SERVER_BIND=""
        parse_arguments --code-server-bind "$value"
        [[ "$CODE_SERVER_BIND" == "$value" ]] ||
            fail "expected bind '$value' to be retained exactly, got: '$CODE_SERVER_BIND'"
    done <<< "$VALID_BINDS"
}

test_code_server_bind_splits_host_and_port() {
    source_install

    [[ "$(split_code_server_bind "0.0.0.0:8080")" == "0.0.0.0 8080" ]] ||
        fail "expected IPv4 bind split, got: $(split_code_server_bind "0.0.0.0:8080")"
    [[ "$(split_code_server_bind "[::1]:8443")" == "::1 8443" ]] ||
        fail "expected bracketed IPv6 bind split without brackets, got: $(split_code_server_bind "[::1]:8443")"
    [[ "$(split_code_server_bind "[fe80::1%eth0]:8443")" == "fe80::1%eth0 8443" ]] ||
        fail "expected zone identifier to be retained, got: $(split_code_server_bind "[fe80::1%eth0]:8443")"
}

test_malformed_bind_values_are_rejected_before_any_orchestration() {
    local root
    local value
    local index=0
    local work

    source_install
    new_tmp_var root

    while IFS= read -r value; do
        index=$((index + 1))
        work="$root/case-$index"
        mkdir -p "$work"

        run_main_observed "$work" --modules code_server --code-server-bind "$value"

        [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected bind '$value' to be rejected"
        [[ ! -s "$OBSERVED_CALLS" ]] ||
            fail "bind '$value' reached orchestration: $(tr '\n' ' ' < "$OBSERVED_CALLS")"
        [[ ! -e "$OBSERVED_BIND_FILE" ]] || fail "bind '$value' reached the code-server service"
        [[ -z "$OBSERVED_PERSISTED" ]] || fail "bind '$value' persisted state to:$OBSERVED_PERSISTED"
    done <<< "$MALFORMED_BINDS"

    work="$root/missing-argument"
    mkdir -p "$work"
    run_main_observed "$work" --modules code_server --code-server-bind
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected a missing bind argument to be rejected"
    [[ ! -s "$OBSERVED_CALLS" ]] || fail "missing bind argument reached orchestration"
    [[ -z "$OBSERVED_PERSISTED" ]] || fail "missing bind argument persisted state to:$OBSERVED_PERSISTED"
}

test_valid_bind_reaches_the_code_server_service_unchanged() {
    local work
    local value="[2001:db8::1]:9443"

    source_install
    new_tmp_var work

    run_main_observed "$work" --modules code_server --code-server-bind "$value"

    [[ "$OBSERVED_STATUS" -eq 0 ]] ||
        fail "expected a valid bind run to succeed: $(cat "$work/entry.out")"
    [[ -e "$OBSERVED_BIND_FILE" ]] || fail "the code-server service was never dispatched"
    [[ "$(cat "$OBSERVED_BIND_FILE")" == "$value" ]] ||
        fail "service received bind '$(cat "$OBSERVED_BIND_FILE")' instead of '$value'"
    [[ "$(tr '\n' ' ' < "$OBSERVED_CALLS")" == *"install_code_server show_editor_completion_notices "* ]] ||
        fail "unexpected orchestration: $(tr '\n' ' ' < "$OBSERVED_CALLS")"
    [[ -z "$OBSERVED_PERSISTED" ]] || fail "a valid bind persisted state to:$OBSERVED_PERSISTED"
}

test_default_run_leaves_the_bind_unset_for_local_configuration() {
    local work

    source_install
    new_tmp_var work

    run_main_observed "$work" --modules code_server

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected a bindless run to succeed"
    [[ -e "$OBSERVED_BIND_FILE" ]] || fail "the code-server service was never dispatched"
    [[ -z "$(cat "$OBSERVED_BIND_FILE")" ]] ||
        fail "expected no bind override, got: $(cat "$OBSERVED_BIND_FILE")"
    [[ -z "$OBSERVED_PERSISTED" ]] || fail "a bindless run persisted state to:$OBSERVED_PERSISTED"
}

test_bind_parsing_persists_nothing_anywhere() {
    local work

    source_install
    new_tmp_var work

    run_parse_observed "$work/valid" --code-server-bind "10.0.0.5:8443"
    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected a valid bind to parse"
    [[ "$(cat "$OBSERVED_BIND_FILE")" == "10.0.0.5:8443" ]] ||
        fail "expected the parsed bind to be retained in runtime state"
    [[ -z "$OBSERVED_PERSISTED" ]] || fail "valid bind parsing persisted state to:$OBSERVED_PERSISTED"

    run_parse_observed "$work/invalid" --code-server-bind "10.0.0.5:99999"
    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected an invalid bind to fail parsing"
    [[ ! -e "$OBSERVED_BIND_FILE" ]] || fail "invalid bind parsing stored runtime state"
    [[ -z "$OBSERVED_PERSISTED" ]] || fail "invalid bind parsing persisted state to:$OBSERVED_PERSISTED"
}

# ---------------------------------------------------------------------------
# Cycle D — dispatch, continuation, and completion notices
# ---------------------------------------------------------------------------

EDITOR_MODULES="python vscode vscode_config code_server"

# Independent expectations. These are declared by the test, not derived from
# the implementation, so a label or module-list change must be made here too.
EXPECTED_MENU_MODULES="base_tools neovim nvim_config tmux_config herdr herdr_config herdr_integrations zsh_ohmyzsh zsh_config python golang_full nodejs codex codex_sandbox claude pi pi_sandbox tui_tools playwright copilot vscode vscode_config code_server"

EXPECTED_MODULE_LABELS="base_tools=Base Tools (git, curl, tmux, zsh, etc.)
neovim=Neovim 0.12+
nvim_config=Neovim Configuration (kickstart + custom)
tmux_config=Tmux Configuration
herdr=Herdr Terminal Workspace Manager
herdr_config=Herdr Configuration
herdr_integrations=Herdr Agent Integrations
zsh_ohmyzsh=Zsh + Oh My Zsh
zsh_config=Zsh Custom Configuration
python=Python 3.10+ (native interpreter + venv)
golang=Go 1.24+ Toolchain (basic)
golang_full=Go Development (toolchain + LSP + tools + govulncheck)
nodejs=Node.js LTS (fnm)
codex=Codex CLI
codex_sandbox=Codex Sandbox (Docker)
claude=Claude Code CLI
pi=Pi Coding Agent
pi_sandbox=Pi Sandbox (Docker)
tui_tools=TUI Tools (lazygit, yazi, zoxide)
playwright=Playwright CLI (browser automation)
copilot=GitHub Copilot CLI
vscode=Visual Studio Code Desktop (macOS)
vscode_config=VS Code Managed Configuration (macOS)
code_server=code-server Browser Endpoint (Ubuntu/Debian)"

EXPECTED_HELP_LINES="  python              Python 3.10+ native interpreter and venv support
  vscode              Visual Studio Code Desktop (macOS only)
  vscode_config       VS Code managed configuration (macOS only)
  code_server         code-server browser endpoint (Ubuntu/Debian, explicit only)"

expected_label() {
    local module="$1"
    local line

    while IFS= read -r line; do
        if [ "${line%%=*}" == "$module" ]; then
            printf '%s' "${line#*=}"
            return 0
        fi
    done <<< "$EXPECTED_MODULE_LABELS"

    fail "no expected label declared for module: $module"
}

test_custom_menu_offers_every_module_with_its_expected_label() {
    local tmp
    local count
    local module

    source_install
    new_tmp_var tmp

    count=0
    for module in $EXPECTED_MENU_MODULES; do
        count=$((count + 1))
    done

    clear() { :; }
    SELECTED_MODULES=()
    show_custom_menu > "$tmp/menu.out" <<EOF
$((count + 1))
$((count + 2))
EOF
    unset -f clear

    [[ "${SELECTED_MODULES[*]}" == "$EXPECTED_MENU_MODULES" ]] ||
        fail "custom menu selected: ${SELECTED_MODULES[*]}
expected: $EXPECTED_MENU_MODULES"

    for module in $EXPECTED_MENU_MODULES; do
        grep -Fxq "  [X] $(expected_label "$module")" "$tmp/menu.out" ||
            fail "custom menu is missing the selected entry for $module: '  [X] $(expected_label "$module")'"
    done

    grep -Fxq "  $((count + 1))) Toggle All" "$tmp/menu.out" || fail "custom menu is missing Toggle All"
    grep -Fxq "  $((count + 2))) Done" "$tmp/menu.out" || fail "custom menu is missing Done"
}

test_help_documents_editor_modules_and_bind_flag() {
    local tmp
    local line

    source_install
    new_tmp_var tmp
    show_help > "$tmp/help.out"

    while IFS= read -r line; do
        grep -Fxq "$line" "$tmp/help.out" || fail "help output is missing the exact line: '$line'"
    done <<< "$EXPECTED_HELP_LINES"

    grep -Fxq "  --code-server-bind ADDRESS:PORT" "$tmp/help.out" ||
        fail "help output is missing the --code-server-bind flag line"
}

test_installation_summary_labels_every_module() {
    local tmp
    local module
    local bullets

    source_install
    new_tmp_var tmp

    SELECTED_MODULES=($EXPECTED_MENU_MODULES golang)
    show_installation_summary < /dev/null > "$tmp/summary.out"

    for module in $EXPECTED_MENU_MODULES golang; do
        grep -Fxq "  • $(expected_label "$module")" "$tmp/summary.out" ||
            fail "installation summary is missing the exact line for $module: '  • $(expected_label "$module")'"
    done

    bullets="$(grep -c '•' "$tmp/summary.out" || true)"
    [[ "$bullets" -eq "$((1 + $(printf '%s\n' $EXPECTED_MENU_MODULES | wc -l)))" ]] ||
        fail "expected exactly one summary label per selected module, got $bullets"
}

test_execute_modules_dispatches_every_editor_module() {
    local tmp
    local log

    source_install
    new_tmp_var tmp
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
    new_tmp_var tmp
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
    new_tmp_var tmp
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
    new_tmp_var tmp
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
    new_tmp_var tmp
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

# Distinct sentinels for every secret-shaped value a local code-server config
# can hold. None of them may ever appear in installer output.
SECRET_SENTINELS="sentinel-plain-password
sentinel-hashed-password
sentinel-certificate-key
sentinel-session-token"

# Any credential assignment, in either YAML (`key: value`) or environment
# (`KEY=value`) form, in any case, is a disclosure.
CREDENTIAL_ASSIGNMENT_PATTERN='(password|passwd|secret|token|api[_-]?key|cert-key|private[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]'

assert_no_credentials_in() {
    local out="$1"
    local sentinel

    while IFS= read -r sentinel; do
        [ -n "$sentinel" ] || continue
        if grep -Fq "$sentinel" "$out"; then
            fail "installer output disclosed the secret sentinel '$sentinel'"
        fi
    done <<< "$SECRET_SENTINELS"

    if grep -qiE "$CREDENTIAL_ASSIGNMENT_PATTERN" "$out"; then
        fail "installer output contains a credential assignment: $(grep -iE "$CREDENTIAL_ASSIGNMENT_PATTERN" "$out")"
    fi
}

seed_code_server_secrets() {
    local home="$1"

    mkdir -p "$home/.config/code-server"
    cat > "$home/.config/code-server/config.yaml" << 'EOF'
bind-addr: 0.0.0.0:8080
auth: password
password: sentinel-plain-password
hashed-password: sentinel-hashed-password
cert: true
cert-key: sentinel-certificate-key
SESSION_TOKEN=sentinel-session-token
EOF
}

test_code_server_notice_requires_successful_service_and_hides_secrets() {
    local tmp
    local home

    source_install
    new_tmp_var tmp
    home="$tmp/home"
    seed_code_server_secrets "$home"

    OS="ubuntu"
    CODE_SERVER_BIND="10.0.0.5:8443"
    SELECTED_MODULES=(code_server)
    FAILED_MODULES=()

    HOME="$home" notices_output "$tmp/success.out" code_server

    grep -Fq '~/.config/code-server/config.yaml' "$tmp/success.out" ||
        fail "expected the local code-server config path in the notice"
    grep -q 'HTTPS' "$tmp/success.out" || fail "expected HTTPS guidance"
    grep -Fq 'Password authentication stays enabled' "$tmp/success.out" ||
        fail "expected password authentication guidance"
    grep -Fq 'locally generated certificate' "$tmp/success.out" ||
        fail "expected generated certificate guidance"
    grep -Fq 'trusted' "$tmp/success.out" || fail "expected trusted-network guidance"
    assert_no_credentials_in "$tmp/success.out"

    FAILED_MODULES=(code_server)
    notices_output "$tmp/failed.out"
    grep -Fq 'code-server' "$tmp/failed.out" && fail "no code-server notice after a failed module"

    return 0
}

test_full_completion_report_never_prints_local_credentials() {
    local work

    source_install
    new_tmp_var work
    mkdir -p "$work/home"
    seed_code_server_secrets "$work/home"

    # The service stub succeeds, so the real notice runs inside the real
    # completion report rather than through a stub.
    (
        OBSERVED="$work"
        cd "$work" || exit 99
        HOME="$work/home"
        export HOME

        detect_os() { OS="ubuntu"; PACKAGE_MANAGER="apt"; }
        setup_package_manager() { :; }
        update_package_manager() { :; }
        show_installation_summary() { return 0; }
        install_code_server() { return 0; }

        main --modules code_server --code-server-bind 10.0.0.5:8443
    ) > "$work/main.out" 2>&1 || fail "expected the code-server run to succeed"

    grep -Fq '~/.config/code-server/config.yaml' "$work/main.out" ||
        fail "expected the completion report to include the code-server notice"
    assert_no_credentials_in "$work/main.out"
}

test_main_binds_orchestration_phases_in_required_order() {
    local tmp
    local log
    local status=0
    local expected

    source_install
    new_tmp_var tmp
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

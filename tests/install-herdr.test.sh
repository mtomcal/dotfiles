#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$TEST_DIR/.." && pwd)"
TMP_DIRS=()

cleanup() {
    if [[ ${#TMP_DIRS[@]} -gt 0 ]]; then
        rm -rf "${TMP_DIRS[@]}"
    fi
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

new_tmp() {
    local tmp
    tmp="$(mktemp -d)"
    TMP_DIRS+=("$tmp")
    printf '%s\n' "$tmp"
}

assert_symlink_to() {
    local path="$1"
    local target="$2"
    [[ -L "$path" ]] || fail "expected symlink: $path"
    [[ "$(readlink "$path")" == "$target" ]] || fail "expected $path -> $target, got $(readlink "$path")"
}

source_install() {
    INSTALL_SH_NO_MAIN=1 source "$DOTFILES_DIR/install.sh"
}

test_configure_herdr_links_config() {
    local home
    home="$(new_tmp)"
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" configure_herdr >/tmp/install-herdr.out

    assert_symlink_to "$home/.config/herdr/config.toml" "$DOTFILES_DIR/herdr/config.toml"
}

test_profiles_include_herdr_modules() {
    source_install

    parse_arguments --profile minimal
    [[ " ${SELECTED_MODULES[*]} " == *" herdr "* ]] || fail "minimal profile missing herdr"
    [[ " ${SELECTED_MODULES[*]} " == *" herdr_config "* ]] || fail "minimal profile missing herdr_config"
    [[ " ${SELECTED_MODULES[*]} " == *" herdr_integrations "* ]] || fail "minimal profile missing herdr_integrations"

    SELECTED_MODULES=()
    parse_arguments --profile work
    [[ " ${SELECTED_MODULES[*]} " == *" herdr "* ]] || fail "work profile missing herdr"
    [[ " ${SELECTED_MODULES[*]} " == *" herdr_config "* ]] || fail "work profile missing herdr_config"
    [[ " ${SELECTED_MODULES[*]} " == *" herdr_integrations "* ]] || fail "work profile missing herdr_integrations"

    SELECTED_MODULES=()
    parse_arguments --profile full
    [[ " ${SELECTED_MODULES[*]} " == *" herdr "* ]] || fail "full profile missing herdr"
    [[ " ${SELECTED_MODULES[*]} " == *" herdr_config "* ]] || fail "full profile missing herdr_config"
    [[ " ${SELECTED_MODULES[*]} " == *" herdr_integrations "* ]] || fail "full profile missing herdr_integrations"
}

test_dependency_resolution_keeps_warnings_out_of_modules() {
    local warning_log="/tmp/install-herdr-dependencies.err"
    source_install

    command() {
        if [[ "$1" == "-v" ]]; then
            case "$2" in
                herdr) return 1 ;;
                curl|jq) return 0 ;;
            esac
        fi
        builtin command "$@"
    }

    SELECTED_MODULES=($(resolve_dependencies herdr_config herdr_integrations 2>"$warning_log"))
    unset -f command

    [[ "${#SELECTED_MODULES[@]}" -eq 3 ]] || fail "expected 3 resolved modules, got: ${SELECTED_MODULES[*]}"
    [[ "${SELECTED_MODULES[0]}" == "herdr" ]] || fail "expected herdr first, got ${SELECTED_MODULES[0]}"
    [[ "${SELECTED_MODULES[1]}" == "herdr_config" ]] || fail "expected herdr_config second, got ${SELECTED_MODULES[1]}"
    [[ "${SELECTED_MODULES[2]}" == "herdr_integrations" ]] || fail "expected herdr_integrations third, got ${SELECTED_MODULES[2]}"
    [[ " ${SELECTED_MODULES[*]} " != *" [WARNING] "* ]] || fail "warning text leaked into resolved modules"
    [[ "$(cat "$warning_log")" == *"Adding Herdr (required by Herdr config)"* ]] || fail "expected dependency warning on stderr"
}

test_configure_herdr_links_config
test_profiles_include_herdr_modules
test_dependency_resolution_keeps_warnings_out_of_modules

echo "install-herdr tests passed"

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

module_index() {
    local wanted="$1"
    shift
    local idx=0
    local module

    for module in "$@"; do
        if [[ "$module" == "$wanted" ]]; then
            printf '%s\n' "$idx"
            return 0
        fi
        idx=$((idx + 1))
    done

    fail "module not found: $wanted"
}

assert_module_after() {
    local later="$1"
    local earlier="$2"
    shift 2
    local later_idx
    local earlier_idx

    later_idx="$(module_index "$later" "$@")"
    earlier_idx="$(module_index "$earlier" "$@")"
    [[ "$later_idx" -gt "$earlier_idx" ]] || fail "expected $later after $earlier, got: $*"
}

assert_claude_herdr_hook() {
    local settings_path="$1"
    local expected_command="$2"

    jq -e --arg command "$expected_command" '
        any(.hooks.SessionStart[]?; .matcher == "*" and any(.hooks[]?; .type == "command" and .command == $command))
    ' "$settings_path" >/dev/null || fail "expected Claude Herdr SessionStart hook in $settings_path"
}

test_agent_profiles_configure_herdr_integrations_after_agents() {
    source_install

    parse_arguments --profile work
    assert_module_after herdr_integrations copilot "${SELECTED_MODULES[@]}"

    SELECTED_MODULES=()
    parse_arguments --profile full
    assert_module_after herdr_integrations codex "${SELECTED_MODULES[@]}"
    assert_module_after herdr_integrations claude "${SELECTED_MODULES[@]}"
    assert_module_after herdr_integrations pi "${SELECTED_MODULES[@]}"
    assert_module_after herdr_integrations copilot "${SELECTED_MODULES[@]}"
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

test_configure_herdr_integrations_preserves_claude_settings_symlink() {
    local home
    local managed_settings
    local hook_path

    home="$(new_tmp)"
    managed_settings="$home/managed/claude-settings.json"
    hook_path="$home/.claude/hooks/herdr-agent-state.sh"
    mkdir -p "$home/.claude" "$home/managed"
    printf '{"env":{"KEEP_ME":"1"}}\n' > "$managed_settings"
    ln -s "$managed_settings" "$home/.claude/settings.json"

    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" configure_herdr_integrations >/tmp/install-herdr-integrations.out

    assert_symlink_to "$home/.claude/settings.json" "$managed_settings"
    assert_symlink_to "$hook_path" "$DOTFILES_DIR/herdr/integrations/claude/herdr-agent-state.sh"
    jq -e '.env.KEEP_ME == "1"' "$managed_settings" >/dev/null || fail "expected existing Claude settings to be preserved"
    assert_claude_herdr_hook "$managed_settings" "$(herdr_hook_command "$hook_path" session)"
}

test_configure_herdr_integrations_does_not_mutate_tracked_claude_settings() {
    local home
    local dotfiles
    local tracked_settings

    home="$(new_tmp)"
    dotfiles="$(new_tmp)"
    tracked_settings="$dotfiles/claude/settings.json"
    mkdir -p "$home/.claude" "$dotfiles/claude" "$dotfiles/herdr/integrations/claude"
    cp "$DOTFILES_DIR/claude/settings.json" "$tracked_settings"
    cp "$DOTFILES_DIR/herdr/integrations/claude/herdr-agent-state.sh" "$dotfiles/herdr/integrations/claude/herdr-agent-state.sh"
    git -C "$dotfiles" init -q
    git -C "$dotfiles" add claude/settings.json
    ln -s "$tracked_settings" "$home/.claude/settings.json"

    source_install

    HOME="$home" DOTFILES_DIR="$dotfiles" configure_herdr_integrations >/tmp/install-herdr-managed-settings.out

    assert_symlink_to "$home/.claude/settings.json" "$tracked_settings"
    git -C "$dotfiles" diff --exit-code -- claude/settings.json >/tmp/install-herdr-managed-settings.diff || {
        cat /tmp/install-herdr-managed-settings.diff >&2
        fail "configure_herdr_integrations changed tracked claude/settings.json"
    }
    ! grep -F "$home" "$tracked_settings" >/dev/null || fail "tracked Claude settings contain HOME-specific path"
    assert_claude_herdr_hook "$home/.claude/settings.json" "$(portable_claude_herdr_hook_command)"
}

test_install_claude_preserves_local_settings_backup_and_deploys_symlink() {
    local home
    local backup

    home="$(new_tmp)"
    mkdir -p "$home/.claude"
    printf '{"local":true}\n' > "$home/.claude/settings.json"

    source_install

    claude() {
        return 1
    }

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >/tmp/install-herdr-claude-install.out
    unset -f claude

    assert_symlink_to "$home/.claude/settings.json" "$DOTFILES_DIR/claude/settings.json"
    backup="$(find "$home/.claude" -maxdepth 1 -name 'settings.json.backup.*' -print -quit)"
    [[ -n "$backup" ]] || fail "expected local Claude settings backup"
    jq -e '.local == true' "$backup" >/dev/null || fail "expected local Claude settings backup contents to be preserved"
}

test_execute_modules_runs_herdr_integrations_after_agent_modules() {
    local log
    log="$(new_tmp)/execute.log"
    source_install

    install_claude() {
        printf 'claude\n' >> "$log"
    }

    configure_herdr_integrations() {
        printf 'herdr_integrations\n' >> "$log"
    }

    execute_modules herdr_integrations claude

    [[ "$(cat "$log")" == $'claude\nherdr_integrations' ]] || fail "expected herdr_integrations to run last, got: $(cat "$log")"
}

test_configure_herdr_links_config
test_profiles_include_herdr_modules
test_agent_profiles_configure_herdr_integrations_after_agents
test_dependency_resolution_keeps_warnings_out_of_modules
test_configure_herdr_integrations_preserves_claude_settings_symlink
test_configure_herdr_integrations_does_not_mutate_tracked_claude_settings
test_install_claude_preserves_local_settings_backup_and_deploys_symlink
test_execute_modules_runs_herdr_integrations_after_agent_modules

echo "install-herdr tests passed"

#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

test_configure_herdr_links_config() {
    local home
    new_tmp_var home
    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" configure_herdr >"$(tmp_artifact install-herdr.out)"

    assert_symlink_to "$home/.config/herdr/config.toml" "$DOTFILES_DIR/herdr/config.toml"
}

select_profile() {
    local profile="$1"

    parse_arguments --profile "$profile"
    SELECTED_MODULES=($(expand_profile "$profile"))
}

test_profiles_include_herdr_modules() {
    local os
    local profile

    source_install

    for os in ubuntu macos; do
        OS="$os"
        for profile in minimal work full; do
            SELECTED_MODULES=()
            select_profile "$profile"
            [[ " ${SELECTED_MODULES[*]} " == *" herdr "* ]] || fail "$os $profile profile missing herdr"
            [[ " ${SELECTED_MODULES[*]} " == *" herdr_config "* ]] || fail "$os $profile profile missing herdr_config"
            [[ " ${SELECTED_MODULES[*]} " == *" herdr_integrations "* ]] || fail "$os $profile profile missing herdr_integrations"
        done
    done
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

assert_copilot_herdr_hook() {
    local settings_path="$1"
    local expected_command="$2"

    jq -e --arg command "$expected_command" '
        any(.hooks.SessionStart[]?; .type == "command" and .bash == $command)
    ' "$settings_path" >/dev/null || fail "expected Copilot Herdr SessionStart hook in $settings_path"
}

test_agent_profiles_configure_herdr_integrations_after_agents() {
    source_install

    OS="ubuntu"
    select_profile work
    assert_module_after herdr_integrations copilot "${SELECTED_MODULES[@]}"

    SELECTED_MODULES=()
    select_profile full
    assert_module_after herdr_integrations codex "${SELECTED_MODULES[@]}"
    assert_module_after herdr_integrations claude "${SELECTED_MODULES[@]}"
    assert_module_after herdr_integrations pi "${SELECTED_MODULES[@]}"
    assert_module_after herdr_integrations copilot "${SELECTED_MODULES[@]}"
}

test_dependency_resolution_keeps_warnings_out_of_modules() {
    local warning_log="$(tmp_artifact install-herdr-dependencies.err)"
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

    new_tmp_var home
    managed_settings="$home/managed/claude-settings.json"
    hook_path="$home/.claude/hooks/herdr-agent-state.sh"
    mkdir -p "$home/.claude" "$home/managed"
    printf '{"env":{"KEEP_ME":"1"}}\n' > "$managed_settings"
    ln -s "$managed_settings" "$home/.claude/settings.json"

    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" configure_herdr_integrations >"$(tmp_artifact install-herdr-integrations.out)"

    assert_symlink_to "$home/.claude/settings.json" "$managed_settings"
    assert_symlink_to "$hook_path" "$DOTFILES_DIR/herdr/integrations/claude/herdr-agent-state.sh"
    jq -e '.env.KEEP_ME == "1"' "$managed_settings" >/dev/null || fail "expected existing Claude settings to be preserved"
    assert_claude_herdr_hook "$managed_settings" "$(herdr_hook_command "$hook_path" session)"
}

test_configure_herdr_integrations_uses_current_copilot_config_root() {
    local home
    local hook_path
    local legacy_hook
    local legacy_settings
    local legacy_command

    new_tmp_var home
    hook_path="$home/.copilot/hooks/herdr-agent-state.sh"
    mkdir -p "$home/.copilot"
    printf '{"keep":true}\n' > "$home/.copilot/settings.json"

    # Seed the legacy ~/.config/copilot integration: a dotfiles-managed hook
    # symlink and a matching SessionStart entry, alongside unrelated settings
    # and an unrelated hook entry that must survive migration.
    legacy_hook="$home/.config/copilot/hooks/herdr-agent-state.sh"
    legacy_settings="$home/.config/copilot/settings.json"
    mkdir -p "$(dirname "$legacy_hook")"
    ln -s "$DOTFILES_DIR/herdr/integrations/copilot/herdr-agent-state.sh" "$legacy_hook"
    legacy_command="$(herdr_hook_command "$legacy_hook")"
    jq -n --arg cmd "$legacy_command" '{
        unrelated: true,
        hooks: {
            SessionStart: [{ type: "command", bash: $cmd, timeoutSec: 10 }],
            Stop: [{ type: "command", bash: "echo unrelated-stop", timeoutSec: 5 }]
        }
    }' > "$legacy_settings"

    source_install

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" configure_herdr_integrations >"$(tmp_artifact install-herdr-copilot.out)"

    # Current ~/.copilot integration is deployed and unrelated settings survive.
    assert_symlink_to "$hook_path" "$DOTFILES_DIR/herdr/integrations/copilot/herdr-agent-state.sh"
    jq -e '.keep == true' "$home/.copilot/settings.json" >/dev/null || fail "expected existing Copilot settings to be preserved"
    assert_copilot_herdr_hook "$home/.copilot/settings.json" "$(herdr_hook_command "$hook_path")"

    # The dotfiles-managed legacy hook symlink is removed.
    [[ ! -e "$legacy_hook" ]] || fail "expected legacy Copilot hook symlink to be removed by migration"

    # Legacy settings file survives with unrelated data intact.
    [[ -f "$legacy_settings" ]] || fail "expected legacy Copilot settings file to be preserved"
    jq -e '.unrelated == true' "$legacy_settings" >/dev/null || fail "expected unrelated legacy setting to be preserved"
    jq -e --arg cmd "echo unrelated-stop" 'any(.hooks.Stop[]?; .bash == $cmd)' "$legacy_settings" >/dev/null \
        || fail "expected unrelated legacy hook entry to be preserved"
    jq -e 'has("hooks")' "$legacy_settings" >/dev/null || fail "expected legacy hooks container to remain for unrelated entries"

    # Only the matching legacy Herdr entry is removed and its emptied container pruned.
    jq -e --arg cmd "$legacy_command" 'any(.hooks.SessionStart[]?; .bash == $cmd) | not' "$legacy_settings" >/dev/null \
        || fail "expected legacy Herdr hook entry to be removed from legacy settings"
    jq -e 'has("SessionStart") | not' "$legacy_settings" >/dev/null \
        || fail "expected empty legacy SessionStart array to be pruned"
}

test_configure_herdr_integrations_migrates_managed_claude_settings() {
    local home
    local dotfiles
    local tracked_settings

    new_tmp_var home
    new_tmp_var dotfiles
    tracked_settings="$dotfiles/claude/settings.json"
    mkdir -p "$home/.claude" "$dotfiles/claude" "$dotfiles/herdr/integrations/claude"
    printf '{"env":{"KEEP_ME":"1"}}\n' > "$tracked_settings"
    cp "$DOTFILES_DIR/herdr/integrations/claude/herdr-agent-state.sh" "$dotfiles/herdr/integrations/claude/herdr-agent-state.sh"
    git -C "$dotfiles" init -q
    git -C "$dotfiles" add claude/settings.json
    ln -s "$tracked_settings" "$home/.claude/settings.json"

    source_install

    HOME="$home" DOTFILES_DIR="$dotfiles" configure_herdr_integrations >"$(tmp_artifact install-herdr-managed-settings.out)"

    [[ ! -L "$home/.claude/settings.json" ]] || fail "expected managed Claude settings to migrate to local state"
    git -C "$dotfiles" diff --exit-code -- claude/settings.json >"$(tmp_artifact install-herdr-managed-settings.diff)" || {
        cat "$(tmp_artifact install-herdr-managed-settings.diff)" >&2
        fail "configure_herdr_integrations changed legacy Claude settings source"
    }
    ! grep -F "$home" "$tracked_settings" >/dev/null || fail "legacy Claude settings source contains HOME-specific path"
    assert_claude_herdr_hook "$home/.claude/settings.json" "$(portable_claude_herdr_hook_command)"
}

test_install_claude_preserves_local_settings_file() {
    local home

    new_tmp_var home
    mkdir -p "$home/.claude"
    printf '{"local":true}\n' > "$home/.claude/settings.json"

    source_install

    claude() {
        return 1
    }

    curl() {
        printf '%s\n' 'mkdir -p "$HOME/.local/bin"'
        printf '%s\n' 'printf "#!/usr/bin/env bash\nprintf \"2.1.201 (Claude Code)\\n\"\n" > "$HOME/.local/bin/claude"'
        printf '%s\n' 'chmod +x "$HOME/.local/bin/claude"'
    }

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >"$(tmp_artifact install-herdr-claude-install.out)"
    unset -f claude curl

    [[ ! -L "$home/.claude/settings.json" ]] || fail "expected Claude settings to remain local state"
    jq -e '.local == true' "$home/.claude/settings.json" >/dev/null || fail "expected local Claude settings contents to be preserved"
}

test_execute_modules_runs_herdr_integrations_after_agent_modules() {
    local log
    local log_dir
    new_tmp_var log_dir
    log="$log_dir/execute.log"
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

run_tests "install-herdr tests"

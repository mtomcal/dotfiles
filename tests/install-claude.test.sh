#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

test_claude_module_resolves_jq_dependency() {
    source_install

    command() {
        if [[ "$1" == "-v" ]]; then
            case "$2" in
                curl) return 0 ;;
                jq) return 1 ;;
            esac
        fi
        builtin command "$@"
    }

    SELECTED_MODULES=($(resolve_dependencies claude 2>"$(tmp_artifact install-claude-dependencies.err)"))
    unset -f command

    [[ "${SELECTED_MODULES[*]}" == "base_tools claude" ]] || fail "expected Claude module to resolve jq via base_tools, got: ${SELECTED_MODULES[*]}"
}

test_install_claude_runs_latest_installer_when_claude_already_exists() {
    local home
    local installer_log

    new_tmp_var home
    installer_log="$home/installer.log"

    source_install

    claude() {
        return 1
    }

    curl() {
        printf '%s\n' 'printf "%s\n" "$1" > "$HOME/installer.log"'
        printf '%s\n' 'mkdir -p "$HOME/.local/bin"'
        printf '%s\n' 'printf "#!/usr/bin/env bash\nprintf \"2.1.201 (Claude Code)\\n\"\n" > "$HOME/.local/bin/claude"'
        printf '%s\n' 'chmod +x "$HOME/.local/bin/claude"'
    }

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >"$(tmp_artifact install-claude.out)"
    unset -f claude curl

    [[ "$(cat "$installer_log")" == "latest" ]] || fail "expected Claude installer target latest"
    [[ -x "$home/.local/bin/claude" ]] || fail "expected Claude binary at ~/.local/bin/claude"
    assert_symlink_to "$home/.claude/commands" "$DOTFILES_DIR/claude/commands"
    assert_symlink_to "$home/.claude/skills" "$DOTFILES_DIR/skills/claude"
}

test_install_claude_fails_when_latest_installer_does_not_create_binary() {
    local home

    new_tmp_var home

    source_install

    claude() {
        return 1
    }

    curl() {
        printf '%s\n' 'exit 0'
    }

    if HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >"$(tmp_artifact install-claude-missing-bin.out)" 2>&1; then
        unset -f claude curl
        fail "expected install_claude to fail when ~/.local/bin/claude is missing"
    fi
    unset -f claude curl
}

test_install_claude_migrates_managed_settings_to_preserved_local_state() {
    local home
    local dotfiles
    local tracked_settings

    new_tmp_var home
    new_tmp_var dotfiles
    tracked_settings="$dotfiles/claude/settings.json"
    mkdir -p "$home/.claude" "$dotfiles/claude"
    printf '{"managed":true}\n' > "$tracked_settings"
    ln -s "$tracked_settings" "$home/.claude/settings.json"

    source_install

    claude() {
        return 1
    }

    curl() {
        printf '%s\n' 'mkdir -p "$HOME/.claude" "$HOME/.local/bin"'
        printf '%s\n' 'printf "{\"generated\":true}\n" > "$HOME/.claude/settings.json"'
        printf '%s\n' 'printf "#!/usr/bin/env bash\nprintf \"2.1.201 (Claude Code)\\n\"\n" > "$HOME/.local/bin/claude"'
        printf '%s\n' 'chmod +x "$HOME/.local/bin/claude"'
    }

    HOME="$home" DOTFILES_DIR="$dotfiles" install_claude >"$(tmp_artifact install-claude-protect-settings.out)"
    unset -f claude curl

    [[ "$(cat "$tracked_settings")" == '{"managed":true}' ]] || fail "expected legacy settings source to remain unchanged"
    [[ ! -L "$home/.claude/settings.json" ]] || fail "expected Claude settings to become local state"
    [[ "$(cat "$home/.claude/settings.json")" == '{"managed":true}' ]] || fail "expected migrated Claude settings to be preserved"
}

test_install_claude_preserves_existing_local_settings() {
    local home

    new_tmp_var home
    mkdir -p "$home/.claude"
    printf '{"local":true}\n' > "$home/.claude/settings.json"

    source_install

    claude() {
        return 1
    }

    curl() {
        printf '%s\n' 'mkdir -p "$HOME/.claude" "$HOME/.local/bin"'
        printf '%s\n' 'printf "{\"generated\":true}\n" > "$HOME/.claude/settings.json"'
        printf '%s\n' 'printf "#!/usr/bin/env bash\nprintf \"2.1.201 (Claude Code)\\n\"\n" > "$HOME/.local/bin/claude"'
        printf '%s\n' 'chmod +x "$HOME/.local/bin/claude"'
    }

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >"$(tmp_artifact install-claude-local-settings.out)"
    unset -f claude curl

    [[ ! -L "$home/.claude/settings.json" ]] || fail "expected Claude settings to remain local state"
    jq -e '.local == true' "$home/.claude/settings.json" >/dev/null || fail "expected existing local Claude settings to be preserved"
    jq -e '.statusLine == {"type":"command","command":"~/.claude/statusline.sh"}' "$home/.claude/settings.json" >/dev/null || fail "expected versioned Claude status line to be configured"
}

test_install_claude_keeps_installer_generated_settings_as_local_state() {
    local home
    local backup

    new_tmp_var home

    source_install

    claude() {
        return 1
    }

    curl() {
        printf '%s\n' 'mkdir -p "$HOME/.claude" "$HOME/.local/bin"'
        printf '%s\n' 'printf "{\"generated\":true}\n" > "$HOME/.claude/settings.json"'
        printf '%s\n' 'printf "#!/usr/bin/env bash\nprintf \"2.1.201 (Claude Code)\\n\"\n" > "$HOME/.local/bin/claude"'
        printf '%s\n' 'chmod +x "$HOME/.local/bin/claude"'
    }

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >"$(tmp_artifact install-claude-fresh-settings.out)"
    unset -f claude curl

    [[ ! -L "$home/.claude/settings.json" ]] || fail "expected generated Claude settings to remain local state"
    jq -e '.generated == true' "$home/.claude/settings.json" >/dev/null || fail "expected generated Claude settings to be preserved"
    jq -e '.statusLine == {"type":"command","command":"~/.claude/statusline.sh"}' "$home/.claude/settings.json" >/dev/null || fail "expected versioned Claude status line to be configured"
    backup="$(find "$home/.claude" -maxdepth 1 -name 'settings.json.backup.*' -print -quit)"
    [[ -z "$backup" ]] || fail "did not expect a backup for installer-generated fresh settings"
}

run_tests "install-claude tests"

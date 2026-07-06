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

test_install_claude_runs_latest_installer_when_claude_already_exists() {
    local home
    local installer_log

    home="$(new_tmp)"
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

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >/tmp/install-claude.out
    unset -f claude curl

    [[ "$(cat "$installer_log")" == "latest" ]] || fail "expected Claude installer target latest"
    [[ -x "$home/.local/bin/claude" ]] || fail "expected Claude binary at ~/.local/bin/claude"
    assert_symlink_to "$home/.claude/commands" "$DOTFILES_DIR/claude/commands"
    assert_symlink_to "$home/.claude/agents" "$DOTFILES_DIR/claude/agents"
    assert_symlink_to "$home/.claude/skills" "$DOTFILES_DIR/shared/skills"
}

test_install_claude_fails_when_latest_installer_does_not_create_binary() {
    local home

    home="$(new_tmp)"

    source_install

    claude() {
        return 1
    }

    curl() {
        printf '%s\n' 'exit 0'
    }

    if HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >/tmp/install-claude-missing-bin.out 2>&1; then
        unset -f claude curl
        fail "expected install_claude to fail when ~/.local/bin/claude is missing"
    fi
    unset -f claude curl
}

test_install_claude_does_not_let_upstream_installer_mutate_tracked_settings() {
    local home
    local dotfiles
    local tracked_settings

    home="$(new_tmp)"
    dotfiles="$(new_tmp)"
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

    HOME="$home" DOTFILES_DIR="$dotfiles" install_claude >/tmp/install-claude-protect-settings.out
    unset -f claude curl

    [[ "$(cat "$tracked_settings")" == '{"managed":true}' ]] || fail "expected tracked Claude settings to remain unchanged"
    assert_symlink_to "$home/.claude/settings.json" "$tracked_settings"
}

test_install_claude_discards_installer_generated_settings_on_fresh_install() {
    local home
    local backup

    home="$(new_tmp)"

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

    HOME="$home" DOTFILES_DIR="$DOTFILES_DIR" install_claude >/tmp/install-claude-fresh-settings.out
    unset -f claude curl

    assert_symlink_to "$home/.claude/settings.json" "$DOTFILES_DIR/claude/settings.json"
    backup="$(find "$home/.claude" -maxdepth 1 -name 'settings.json.backup.*' -print -quit)"
    [[ -z "$backup" ]] || fail "did not expect a backup for installer-generated fresh settings"
}

test_install_claude_runs_latest_installer_when_claude_already_exists
test_install_claude_fails_when_latest_installer_does_not_create_binary
test_install_claude_does_not_let_upstream_installer_mutate_tracked_settings
test_install_claude_discards_installer_generated_settings_on_fresh_install

echo "install-claude tests passed"

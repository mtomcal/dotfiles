#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

test_codex_sync_preserves_system_skills_and_prunes_stale_managed_links() {
    local home
    local dotfiles

    new_tmp_var home
    new_tmp_var dotfiles
    mkdir -p "$home/.codex/skills/.system" "$dotfiles/codex" "$dotfiles/skills/codex/current"
    : > "$dotfiles/skills/codex/current/SKILL.md"
    cp "$DOTFILES_DIR/codex/sync-skills.sh" "$dotfiles/codex/sync-skills.sh"
    chmod +x "$dotfiles/codex/sync-skills.sh"
    ln -s "$dotfiles/skills/codex/missing" "$home/.codex/skills/stale"
    ln -s "$dotfiles/shared/skills/legacy" "$home/.codex/skills/legacy"

    HOME="$home" "$dotfiles/codex/sync-skills.sh" --quiet

    [[ -d "$home/.codex/skills/.system" ]] || fail "Codex built-in skills were removed"
    assert_symlink_to "$home/.codex/skills/current" "$dotfiles/skills/codex/current"
    [[ ! -e "$home/.codex/skills/stale" && ! -L "$home/.codex/skills/stale" ]] ||
        fail "stale Codex skill link was not removed"
    [[ ! -e "$home/.codex/skills/legacy" && ! -L "$home/.codex/skills/legacy" ]] ||
        fail "legacy shared skill link was not removed"
}

test_repository_has_only_harness_specific_skill_roots() {
    local harness

    for harness in claude codex copilot; do
        [[ -d "$DOTFILES_DIR/skills/$harness" ]] || fail "missing skills/$harness"
    done
    [[ ! -e "$DOTFILES_DIR/shared/skills" ]] || fail "legacy shared skill root still exists"
    [[ ! -e "$DOTFILES_DIR/skills/pi" ]] || fail "retired Pi skill root still exists"
}

run_tests "skills layout"

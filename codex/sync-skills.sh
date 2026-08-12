#!/usr/bin/env bash
# Keep Codex's per-skill symlink farm in sync with skills/codex.
#
# Codex owns ~/.codex/skills/.system, so ~/.codex/skills cannot be a direct
# symlink to the repository directory. This script preserves .system while
# exposing every Codex-specific skill as an immediate child of ~/.codex/skills.

set -euo pipefail

QUIET=false
if [[ "${1:-}" == "--quiet" ]]; then
    QUIET=true
fi

SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
    SOURCE_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="${SOURCE_DIR}/${SOURCE}"
done

SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEX_SKILLS_SOURCE="${DOTFILES_DIR}/skills/codex"
LEGACY_SHARED_SKILLS_SOURCE="${DOTFILES_DIR}/shared/skills"
CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

log() {
    if [[ "$QUIET" != true ]]; then
        printf '[codex-skills] %s\n' "$*" >&2
    fi
}

mkdir -p "$CODEX_SKILLS_DIR"

shopt -s nullglob

for skill_dir in "$CODEX_SKILLS_SOURCE"/*; do
    [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue

    skill_name="$(basename "$skill_dir")"
    target="${CODEX_SKILLS_DIR}/${skill_name}"

    if [[ -L "$target" ]]; then
        current_target="$(readlink "$target")"
        if [[ "$current_target" == "$skill_dir" ]]; then
            continue
        fi
        rm "$target"
    elif [[ -e "$target" ]]; then
        log "Skipping ${skill_name}: ${target} exists and is not a symlink"
        continue
    fi

    ln -s "$skill_dir" "$target"
    log "Linked ${skill_name}"
done

for target in "$CODEX_SKILLS_DIR"/*; do
    [[ -L "$target" ]] || continue

    link_target="$(readlink "$target")"
    case "$link_target" in
        "$LEGACY_SHARED_SKILLS_SOURCE"/*)
            rm "$target"
            log "Removed legacy shared skill $(basename "$target")"
            ;;
        "$CODEX_SKILLS_SOURCE"/*)
            if [[ ! -f "$link_target/SKILL.md" ]]; then
                rm "$target"
                log "Removed stale $(basename "$target")"
            fi
            ;;
    esac
done

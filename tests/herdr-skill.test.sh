#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

SKILL="$DOTFILES_DIR/shared/skills/herdr/SKILL.md"
CLAUDE_SKILL="$DOTFILES_DIR/shared/skills/herdr-claude-code/SKILL.md"

test_skill_uses_current_agent_facade() {
    grep -F 'herdr agent --help' "$SKILL" >/dev/null || fail "skill does not discover the Herdr 0.7 agent facade"
    grep -F 'herdr agent start' "$SKILL" >/dev/null || fail "skill does not start agents through the Herdr agent facade"
    grep -F 'herdr agent prompt' "$SKILL" >/dev/null || fail "skill does not submit prompts through the Herdr agent facade"
    grep -F 'herdr agent wait' "$SKILL" >/dev/null || fail "skill does not wait through the Herdr agent facade"
    grep -F 'herdr pane wait-output' "$SKILL" >/dev/null || fail "skill does not use the current pane output wait"
}

test_skill_omits_removed_wait_group() {
    if grep -E 'herdr wait( |$)' "$SKILL" >/dev/null; then
        fail "skill still documents the removed Herdr wait group"
    fi
}

test_claude_specialization_composes_current_agent_facade() {
    grep -F 'herdr agent start' "$CLAUDE_SKILL" >/dev/null || fail "Claude specialization does not use agent start"
    grep -F 'herdr agent prompt' "$CLAUDE_SKILL" >/dev/null || fail "Claude specialization does not use atomic agent prompt"
    if grep -i 'concurrent.*wait\|status race\|explicit.*Enter' "$CLAUDE_SKILL" >/dev/null; then
        fail "Claude specialization still owns superseded status-race or manual submission mechanics"
    fi
}

run_tests "herdr skill tests"

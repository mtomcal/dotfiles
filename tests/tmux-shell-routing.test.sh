#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

extract_auto_attach_block() {
    local output="$1"
    awk '/# TMUX-AUTO-ATTACH-START/,/# TMUX-AUTO-ATTACH-END/' \
        "$DOTFILES_DIR/zsh/.zshrc.custom" > "$output"
}

test_ssh_login_attaches_or_creates_main_session() {
    local block
    local log

    block="$(tmp_artifact tmux-auto-attach.sh)"
    log="$(tmp_artifact tmux-calls.log)"
    extract_auto_attach_block "$block"
    tmux() { printf '%s\n' "$*" >> "$log"; }

    SSH_CONNECTION=present TMUX= DOTFILES_TMUX_AUTO_ATTACH=1 source "$block"

    [[ "$(cat "$log")" == "new-session -A -s main" ]] ||
        fail "unexpected tmux auto-attach command: $(cat "$log")"
}

test_auto_attach_can_be_disabled() {
    local block
    local log

    block="$(tmp_artifact tmux-auto-attach-disabled.sh)"
    log="$(tmp_artifact tmux-disabled-calls.log)"
    extract_auto_attach_block "$block"
    tmux() { printf '%s\n' "$*" >> "$log"; }

    SSH_CONNECTION=present TMUX= DOTFILES_TMUX_AUTO_ATTACH=0 source "$block"

    [[ ! -e "$log" ]] || fail "disabled SSH auto-attach invoked tmux"
}

test_nested_tmux_does_not_auto_attach() {
    local block
    local log

    block="$(tmp_artifact tmux-auto-attach-nested.sh)"
    log="$(tmp_artifact tmux-nested-calls.log)"
    extract_auto_attach_block "$block"
    tmux() { printf '%s\n' "$*" >> "$log"; }

    SSH_CONNECTION=present TMUX=already-inside source "$block"

    [[ ! -e "$log" ]] || fail "nested tmux session invoked auto-attach"
}

run_tests "tmux shell routing"

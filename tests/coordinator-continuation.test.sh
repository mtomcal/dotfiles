#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

DRIVER="$DOTFILES_DIR/shared/skills/execute-engineering-molecule/coordinator-continuation.sh"
ROOT_ID=generic-root
DECISION_ID=generic-approved-decision

assert_contains() {
    local needle="$1"
    local path="$2"
    grep -F -- "$needle" "$path" >/dev/null || fail "expected '$needle' in $path"
}

write_fixtures() {
    local root_json="$1"
    local decision_json="$2"
    local context_enabled="${3:-false}"
    local mode='generic-polling-mode'
    local prohibitions='["beads","workers","panes"]'
    local root_context='"context_rotation":{"enabled":false}'
    local decision_context='"context_rotation":{"enabled":false}'
    local sidecar_layout='"sidecar_layout":{"target":"exact_coordinator_pane","direction":"down","duplicate_cleanup":"close_only_new_sidecar_pane"}'

    if [[ "$context_enabled" == true ]]; then
        mode='generic-context-mode'
        prohibitions='["beads","workers","pane except configured target"]'
        root_context='"context_rotation":{"enabled":true,"threshold_percent":77,"requires":["root contract","reported context","exact target"],"coordinator":{"provider":"configured-provider","model":"configured-model","thinking":"configured-thinking"}}'
        decision_context='"context_rotation":{"enabled":true,"threshold_percent":77,"requires":["root contract","reported context","exact target"]}'
    fi

    cat >"$root_json" <<JSON
[{"id":"$ROOT_ID","status":"in_progress","metadata":{"recovery":{"state":"executing","active_attempts":["attempt"]},"coordinator_continuity":{"enabled":true,"driver":"coordinator-continuation.sh","mode":"$mode","poll_ms":1000,"max_retries":2,"decision":"$DECISION_ID","waits_for":"working coordinator","requires":["root","coordinator","active"],"stops":["invalid","terminal","empty","transport","maximum"],"prohibits":$prohibitions,$sidecar_layout,$root_context}}}]
JSON
    cat >"$decision_json" <<JSON
[{"id":"$DECISION_ID","status":"closed","issue_type":"decision","metadata":{"decision":{"state":"approved","approved":true,"kind":"generic-approved-continuation","scope":"generic transport scope"},"driver":{"name":"coordinator-continuation.sh","mode":"$mode","max_retries":2,"poll_ms":1000,"waits_for":"working coordinator","requires":["root","coordinator","active"],"stops":["invalid","terminal","empty","transport","maximum"],"prohibits":$prohibitions,$sidecar_layout,$decision_context}}}]
JSON
}

make_mock_runtime() {
    local root_json="$1"
    local decision_json="$2"
    local bin="$3"

    mkdir -p "$bin"
    cat >"$bin/bd" <<'MOCK_BD'
#!/usr/bin/env bash
set -euo pipefail
printf 'bd %s\n' "$*" >>"$MOCK_LOG"
if [[ "$1" != show ]]; then
    exit 99
fi
case "$2" in
    "$MOCK_ROOT_ID") cat "$MOCK_ROOT_JSON" ;;
    "$MOCK_DECISION_ID") cat "$MOCK_DECISION_JSON" ;;
    *) exit 1 ;;
esac
MOCK_BD
    cat >"$bin/herdr" <<'MOCK_HERDR'
#!/usr/bin/env bash
set -euo pipefail
printf 'herdr %s\n' "$*" >>"$MOCK_LOG"
case "$1:$2" in
    pane:split)
        printf '{"result":{"pane":{"pane_id":"sidecar-pane"}}}\n'
        ;;
    pane:run)
        printf '%s\n' "${*:3}" >>"$MOCK_RUN_COMMANDS"
        if [[ "${MOCK_RUN_SIDECAR:-0}" == 1 ]]; then
            bash -c "$4"
        fi
        ;;
    pane:get)
        printf '{"result":{"pane":{"agent_status":"unknown"}}}\n'
        ;;
    pane:close)
        printf 'close %s\n' "$*" >>"$MOCK_ROTATIONS"
        ;;
    pane:release-agent)
        printf 'release-agent %s\n' "$*" >>"$MOCK_ROTATIONS"
        ;;
    agent:get)
        get_count=$(cat "$MOCK_AGENT_GET_COUNT_FILE")
        state=$(sed -n "${get_count}p" "$MOCK_AGENT_STATES")
        get_count=$((get_count + 1))
        printf '%s\n' "$get_count" >"$MOCK_AGENT_GET_COUNT_FILE"
        printf '{"result":{"agent":{"agent":"pi","agent_status":"%s","pane_id":"coordinator-pane","name":"coordinator-name","agent_session":{"source":"herdr:pi"},"state_change_seq":17}}}\n' "$state"
        ;;
    agent:read)
        get_count=$(cat "$MOCK_AGENT_GET_COUNT_FILE")
        output=$(sed -n "$((get_count - 1))p" "$MOCK_CONTEXT_LINES")
        printf '%s\n' "$output"
        ;;
    agent:send-keys)
        printf 'send-keys %s\n' "$*" >>"$MOCK_ROTATIONS"
        ;;
    agent:start)
        printf 'start %s\n' "$*" >>"$MOCK_ROTATIONS"
        printf '{"result":{"agent":{"agent_status":"idle"}}}\n'
        ;;
    agent:prompt)
        printf 'prompt %s\n' "$*" >>"$MOCK_PROMPTS"
        printf '{"result":{"agent":{"agent_status":"idle"}}}\n'
        ;;
    *) exit 98 ;;
esac
MOCK_HERDR
    cat >"$bin/sleep" <<'MOCK_SLEEP'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$MOCK_SLEEPS"
if [[ "${MOCK_SLEEP_BLOCK:-0}" == 1 ]]; then
    : >"$MOCK_SLEEP_STARTED"
    while [[ ! -f "$MOCK_SLEEP_RELEASE" ]]; do
        /bin/sleep 0.01
    done
fi
MOCK_SLEEP
    chmod +x "$bin/bd" "$bin/herdr" "$bin/sleep"
    export MOCK_ROOT_ID="$ROOT_ID"
    export MOCK_DECISION_ID="$DECISION_ID"
    export MOCK_ROOT_JSON="$root_json"
    export MOCK_DECISION_JSON="$decision_json"
    export MOCK_LOG="$bin/commands.log"
    export MOCK_RUN_COMMANDS="$bin/run-commands.log"
    export MOCK_PROMPTS="$bin/prompts.log"
    export MOCK_ROTATIONS="$bin/rotations.log"
    export MOCK_SLEEPS="$bin/sleeps.log"
    export MOCK_AGENT_STATES="$bin/agent-states"
    export MOCK_CONTEXT_LINES="$bin/context-lines"
    export MOCK_AGENT_GET_COUNT_FILE="$bin/agent-get-count"
    export MOCK_SLEEP_STARTED="$bin/sleep-started"
    export MOCK_SLEEP_RELEASE="$bin/sleep-release"
    export MOCK_SLEEP_BLOCK=0
    export MOCK_RUN_SIDECAR=0
    export MOCK_TAB_ID=sidecar-tab
    : >"$MOCK_LOG"
    : >"$MOCK_RUN_COMMANDS"
    : >"$MOCK_PROMPTS"
    : >"$MOCK_ROTATIONS"
    : >"$MOCK_SLEEPS"
    rm -f "$MOCK_SLEEP_STARTED" "$MOCK_SLEEP_RELEASE"
    printf 'idle\n' >"$MOCK_AGENT_STATES"
    printf '1\n' >"$MOCK_AGENT_GET_COUNT_FILE"
}

test_normal_invocation_splits_a_no_focus_sidecar_from_the_exact_coordinator_pane() {
    local root_tmp decision_tmp bin_tmp root_json decision_json bin output
    new_tmp_var root_tmp
    new_tmp_var decision_tmp
    new_tmp_var bin_tmp
    root_json="$root_tmp/root.json"
    decision_json="$decision_tmp/decision.json"
    bin="$bin_tmp/bin"

    write_fixtures "$root_json" "$decision_json"
    make_mock_runtime "$root_json" "$decision_json" "$bin"
    export PATH="$bin:$PATH"
    export HERDR_ENV=1
    export HERDR_WORKSPACE_ID=mock-workspace

    output=$("$DRIVER" --root "$ROOT_ID" --coordinator coordinator-agent)
    assert_contains 'agent get coordinator-agent' "$MOCK_LOG"
    assert_contains 'pane split --pane coordinator-pane --direction down' "$MOCK_LOG"
    assert_contains '--cwd' "$MOCK_LOG"
    assert_contains '--no-focus' "$MOCK_LOG"
    assert_contains '--sidecar --sidecar-pane sidecar-pane' "$MOCK_RUN_COMMANDS"
    assert_contains 'launched sidecar pane=sidecar-pane coordinator_pane=coordinator-pane direction=down' <(printf '%s\n' "$output")
    [[ $(wc -l <"$MOCK_RUN_COMMANDS") -eq 1 ]] || fail 'normal invocation launched more than one sidecar command'
}

test_sidecar_derives_policy_and_prompts_only_settled_states() {
    local root_tmp decision_tmp bin_tmp root_json decision_json bin output
    new_tmp_var root_tmp
    new_tmp_var decision_tmp
    new_tmp_var bin_tmp
    root_json="$root_tmp/root.json"
    decision_json="$decision_tmp/decision.json"
    bin="$bin_tmp/bin"

    write_fixtures "$root_json" "$decision_json"
    make_mock_runtime "$root_json" "$decision_json" "$bin"
    printf 'working\nidle\ndone\ndone\n' >"$MOCK_AGENT_STATES"
    export PATH="$bin:$PATH"
    export HERDR_ENV=1
    export HERDR_WORKSPACE_ID=mock-workspace

    output=$("$DRIVER" --sidecar --root "$ROOT_ID" --coordinator coordinator-agent --timeout-ms 1)
    assert_contains 'coordinator_status=working' <(printf '%s\n' "$output")
    assert_contains 'coordinator_status=idle' <(printf '%s\n' "$output")
    assert_contains 'coordinator_status=done mode=generic-polling-mode retries=2/2' <(printf '%s\n' "$output")
    assert_contains 'maximum retries reached' <(printf '%s\n' "$output")
    [[ $(grep -c '^prompt ' "$MOCK_PROMPTS") -eq 2 ]] || fail 'sidecar did not submit exactly two settled retries'
    [[ $(wc -l <"$MOCK_SLEEPS") -eq 1 ]] || fail 'sidecar did not wait for the working coordinator state'
    if grep -E 'tab create|pane run|agent start|agent send-keys|pane close' "$MOCK_LOG" >/dev/null; then
        fail 'sidecar used Herdr topology or worker-control operations'
    fi
    if grep -E '^bd (update|close|comment|create|set|edit)' "$MOCK_LOG" >/dev/null; then
        fail 'sidecar mutated Beads'
    fi
}

test_context_threshold_rotates_exact_target_with_root_assignment() {
    local root_tmp decision_tmp bin_tmp root_json decision_json bin output
    new_tmp_var root_tmp
    new_tmp_var decision_tmp
    new_tmp_var bin_tmp
    root_json="$root_tmp/root.json"
    decision_json="$decision_tmp/decision.json"
    bin="$bin_tmp/bin"

    write_fixtures "$root_json" "$decision_json" true
    make_mock_runtime "$root_json" "$decision_json" "$bin"
    printf 'working\nidle\ndone\n' >"$MOCK_AGENT_STATES"
    printf '77%%/100k (auto)\n10%%/100k (auto)\n10%%/100k (auto)\n' >"$MOCK_CONTEXT_LINES"
    export PATH="$bin:$PATH"
    export HERDR_ENV=1

    output=$("$DRIVER" --sidecar --root "$ROOT_ID" --coordinator coordinator-agent --timeout-ms 1)
    assert_contains 'context threshold reached; rotating target=coordinator-agent pane=coordinator-pane provider=configured-provider model=configured-model thinking=configured-thinking' <(printf '%s\n' "$output")
    assert_contains 'context-aware rotation consumes retry 1/2' <(printf '%s\n' "$output")
    assert_contains "start agent start coordinator-name --kind pi --pane coordinator-pane -- --provider configured-provider --model configured-model --thinking configured-thinking" "$MOCK_ROTATIONS"
    assert_contains 'send-keys agent send-keys coordinator-agent ctrl+c' "$MOCK_ROTATIONS"
    assert_contains 'send-keys agent send-keys coordinator-agent ctrl+d' "$MOCK_ROTATIONS"
    assert_contains 'release-agent pane release-agent coordinator-pane --source herdr:pi --agent pi --seq 17' "$MOCK_ROTATIONS"
    assert_contains "execute-engineering-molecule" "$MOCK_PROMPTS"
    assert_contains "$ROOT_ID" "$MOCK_PROMPTS"
    [[ $(grep -c '^prompt ' "$MOCK_PROMPTS") -eq 2 ]] || fail 'rotation and settled continuation did not share the retry budget'
    [[ $(grep -c '^start ' "$MOCK_ROTATIONS") -eq 1 ]] || fail 'rotation started more than one fresh coordinator'
    [[ $(grep -c '^send-keys ' "$MOCK_ROTATIONS") -eq 2 ]] || fail 'rotation did not cancel and exit only the exact coordinator target'
    assert_contains 'maximum retries reached' <(printf '%s\n' "$output")
}

test_context_uses_final_footer_when_scrollback_quotes_prior_footers() {
    local root_tmp decision_tmp bin_tmp root_json decision_json bin output
    new_tmp_var root_tmp
    new_tmp_var decision_tmp
    new_tmp_var bin_tmp
    root_json="$root_tmp/root.json"
    decision_json="$decision_tmp/decision.json"
    bin="$bin_tmp/bin"

    write_fixtures "$root_json" "$decision_json" true
    make_mock_runtime "$root_json" "$decision_json" "$bin"
    printf 'working\nidle\ndone\n' >"$MOCK_AGENT_STATES"
    printf 'quoted worker footer: 10%%/100k (auto)\ncurrent coordinator footer: 77%%/100k (auto)\n10%%/100k (auto)\n10%%/100k (auto)\n' >"$MOCK_CONTEXT_LINES"
    export PATH="$bin:$PATH"
    export HERDR_ENV=1

    output=$("$DRIVER" --sidecar --root "$ROOT_ID" --coordinator coordinator-agent --timeout-ms 1)
    assert_contains 'context threshold reached; rotating target=coordinator-agent' <(printf '%s\n' "$output")
    [[ $(grep -c '^send-keys ' "$MOCK_ROTATIONS") -eq 2 ]] || fail 'quoted stale footer prevented the final footer rotation'
}

test_duplicate_launch_closes_only_its_own_sidecar_pane() {
    local root_tmp decision_tmp bin_tmp root_json decision_json bin first_output second_output first_pid
    new_tmp_var root_tmp
    new_tmp_var decision_tmp
    new_tmp_var bin_tmp
    root_json="$root_tmp/root.json"
    decision_json="$decision_tmp/decision.json"
    bin="$bin_tmp/bin"

    write_fixtures "$root_json" "$decision_json"
    make_mock_runtime "$root_json" "$decision_json" "$bin"
    printf 'working\n' >"$MOCK_AGENT_STATES"
    export PATH="$bin:$PATH"
    export HERDR_ENV=1
    export HERDR_WORKSPACE_ID=mock-workspace
    export MOCK_SLEEP_BLOCK=1
    ("$DRIVER" --sidecar --root "$ROOT_ID" --coordinator coordinator-agent --max-retries 1 >"$bin/first.out" 2>&1) &
    first_pid=$!
    while [[ ! -f "$MOCK_SLEEP_STARTED" ]]; do
        /bin/sleep 0.01
    done

    export MOCK_RUN_SIDECAR=1
    second_output=$("$DRIVER" --root "$ROOT_ID" --coordinator coordinator-agent)
    : >"$MOCK_SLEEP_RELEASE"
    wait "$first_pid"

    assert_contains 'close pane close sidecar-pane' "$MOCK_ROTATIONS"
    assert_contains 'launched sidecar pane=sidecar-pane coordinator_pane=coordinator-pane direction=down' <(printf '%s\n' "$second_output")
    [[ ! -s "$MOCK_PROMPTS" ]] || fail 'duplicate launch prompted the coordinator'
    if grep -E '^send-keys |^start ' "$MOCK_ROTATIONS" >/dev/null; then
        fail 'duplicate launch restarted or terminated the coordinator'
    fi
}

test_stale_lock_is_reclaimed_without_prompting_or_closing_a_pane() {
    local root_tmp decision_tmp bin_tmp root_json decision_json bin output lock
    new_tmp_var root_tmp
    new_tmp_var decision_tmp
    new_tmp_var bin_tmp
    root_json="$root_tmp/root.json"
    decision_json="$decision_tmp/decision.json"
    bin="$bin_tmp/bin"

    write_fixtures "$root_json" "$decision_json"
    make_mock_runtime "$root_json" "$decision_json" "$bin"
    printf 'idle\nidle\n' >"$MOCK_AGENT_STATES"
    export PATH="$bin:$PATH"
    export HERDR_ENV=1
    export XDG_RUNTIME_DIR="$bin/runtime"
    lock="$XDG_RUNTIME_DIR/coordinator-continuation-67656e657269632d726f6f74.lock"
    mkdir -p "$lock"
    printf '999999999\n' >"$lock/pid"

    output=$("$DRIVER" --sidecar --root "$ROOT_ID" --coordinator coordinator-agent --max-retries 1 --timeout-ms 1)
    assert_contains 'coordinator_status=idle' <(printf '%s\n' "$output")
    assert_contains 'maximum retries reached' <(printf '%s\n' "$output")
    [[ ! -e "$lock" ]] || fail 'stale sidecar lock was not reclaimed and released'
    [[ $(grep -c '^prompt ' "$MOCK_PROMPTS") -eq 1 ]] || fail 'stale lock recovery did not resume the bounded poller'
    [[ ! -s "$MOCK_ROTATIONS" ]] || fail 'stale lock recovery touched a pane or coordinator'
}

test_missing_context_stops_without_rotation() {
    local root_tmp decision_tmp bin_tmp root_json decision_json bin output
    new_tmp_var root_tmp
    new_tmp_var decision_tmp
    new_tmp_var bin_tmp
    root_json="$root_tmp/root.json"
    decision_json="$decision_tmp/decision.json"
    bin="$bin_tmp/bin"

    write_fixtures "$root_json" "$decision_json" true
    make_mock_runtime "$root_json" "$decision_json" "$bin"
    printf 'working\n' >"$MOCK_AGENT_STATES"
    printf 'no Pi footer\n' >"$MOCK_CONTEXT_LINES"
    export PATH="$bin:$PATH"
    export HERDR_ENV=1

    output=$("$DRIVER" --sidecar --root "$ROOT_ID" --coordinator coordinator-agent)
    assert_contains 'coordinator state or Pi context is missing or ambiguous' <(printf '%s\n' "$output")
    [[ ! -s "$MOCK_PROMPTS" ]] || fail 'missing context caused a prompt'
    [[ ! -s "$MOCK_ROTATIONS" ]] || fail 'missing context caused a rotation'
}

run_tests "coordinator continuation tests"

#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: coordinator-continuation.sh --root ROOT_ID --coordinator EXACT_TARGET [options]

Normal mode splits a no-focus horizontal Herdr sidecar pane from the exact
coordinator pane and launches this script there in --sidecar mode. The sidecar is an opt-in, bounded,
transport-only coordinator poller. It read-only verifies the explicit root's
contract and approved decision, waits for a working coordinator to settle, and
re-prompts only a settled coordinator. When the root enables context rotation,
it uses only an unambiguous Pi-reported context footer and the root's
coordinator assignment to rotate that exact target.

Options:
  --root ID           Explicit Beads root id (required)
  --coordinator ID   Exact Herdr agent name or hosting-pane id (required)
  --max-retries N    Optional override; never exceeds the root contract
  --timeout-ms N     Optional Herdr prompt/wait timeout
  --sidecar           Run the polling process; prevents launcher recursion
  --sidecar-pane ID   Newly-created sidecar pane; duplicate cleanup closes only it
  -h, --help          Show this help
USAGE
}

stop() {
  printf 'coordinator-continuation: stopped: %s\n' "$1"
  exit 0
}

fail_usage() {
  printf 'coordinator-continuation: %s\n' "$1" >&2
  usage >&2
  exit 2
}

ROOT_ID=''
COORDINATOR=''
MAX_RETRIES=''
TIMEOUT_MS=''
SIDECAR=0
SIDECAR_PANE=''
ROOT_STATUS=''
RECOVERY_STATE=''
ACTIVE_ATTEMPTS=0
ROOT_DECISION=''
ROOT_MODE=''
ROOT_MAX_RETRIES=0
ROOT_POLL_MS=0
ROOT_WAITS_FOR=''
ROOT_CONTRACT_JSON=''
SIDECAR_DIRECTION=''
CONTEXT_ENABLED=false
CONTEXT_THRESHOLD=0
CONTEXT_PERCENT=''
CONTEXT_AT_THRESHOLD=0
COORDINATOR_PROVIDER=''
COORDINATOR_MODEL=''
COORDINATOR_THINKING=''
COORDINATOR_STATUS=''
COORDINATOR_PANE_ID=''
COORDINATOR_NAME=''
COORDINATOR_LIFECYCLE_SOURCE=''
COORDINATOR_LIFECYCLE_AGENT=''
COORDINATOR_LIFECYCLE_SEQ=''
COORDINATOR_OUTPUT=''
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/../.." && pwd)"

while (($#)); do
  case "$1" in
    --root)
      (($# >= 2)) || fail_usage '--root requires a value'
      ROOT_ID=$2
      shift 2
      ;;
    --coordinator)
      (($# >= 2)) || fail_usage '--coordinator requires a value'
      COORDINATOR=$2
      shift 2
      ;;
    --max-retries)
      (($# >= 2)) || fail_usage '--max-retries requires a value'
      MAX_RETRIES=$2
      shift 2
      ;;
    --timeout-ms)
      (($# >= 2)) || fail_usage '--timeout-ms requires a value'
      TIMEOUT_MS=$2
      shift 2
      ;;
    --sidecar)
      SIDECAR=1
      shift
      ;;
    --sidecar-pane)
      (($# >= 2)) || fail_usage '--sidecar-pane requires a value'
      SIDECAR_PANE=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail_usage "unknown option: $1"
      ;;
  esac
done

[[ -n "$ROOT_ID" ]] || fail_usage '--root is required'
[[ -n "$COORDINATOR" ]] || fail_usage '--coordinator is required'
[[ "$ROOT_ID" != *[[:space:]]* ]] || fail_usage 'root id must be one exact token'
[[ "$COORDINATOR" != *[[:space:]]* ]] || fail_usage 'coordinator target must be one exact token'
[[ -z "$SIDECAR_PANE" || "$SIDECAR_PANE" != *[[:space:]]* ]] ||
  fail_usage 'sidecar pane must be one exact token'
if [[ -n "$MAX_RETRIES" ]]; then
  [[ "$MAX_RETRIES" =~ ^[1-9][0-9]*$ ]] || fail_usage '--max-retries must be a positive integer'
fi
if [[ -n "$TIMEOUT_MS" ]]; then
  [[ "$TIMEOUT_MS" =~ ^[1-9][0-9]*$ ]] || fail_usage '--timeout-ms must be a positive integer'
fi

[[ "${HERDR_ENV:-}" == 1 ]] || stop 'HERDR_ENV=1 is required'
command -v herdr >/dev/null 2>&1 || stop 'herdr is unavailable'
command -v jq >/dev/null 2>&1 || stop 'jq is unavailable'

launch_sidecar() {
  local coordinator_json coordinator_pane split_result sidecar_command

  read_root || stop 'root contract or state is missing or invalid'
  read_decision || stop 'approved decision is missing or does not match the root contract'
  coordinator_json=$(herdr agent get "$COORDINATOR") ||
    stop 'exact coordinator target is unavailable'
  coordinator_pane=$(jq -er '.result.agent.pane_id // empty' <<<"$coordinator_json") ||
    stop 'exact coordinator target did not report a pane'
  split_result=$(herdr pane split \
    --pane "$coordinator_pane" \
    --direction "$SIDECAR_DIRECTION" \
    --cwd "$PROJECT_ROOT" \
    --no-focus) || stop 'sidecar pane split failed'
  SIDECAR_PANE=$(jq -er '.result.pane.pane_id // empty' <<<"$split_result") ||
    stop 'sidecar pane split response did not contain a pane'

  if [[ -n "$MAX_RETRIES" && -n "$TIMEOUT_MS" ]]; then
    printf -v sidecar_command '%q ' \
      "$SCRIPT_PATH" --sidecar --sidecar-pane "$SIDECAR_PANE" --root "$ROOT_ID" \
      --coordinator "$COORDINATOR" --max-retries "$MAX_RETRIES" --timeout-ms "$TIMEOUT_MS"
  elif [[ -n "$MAX_RETRIES" ]]; then
    printf -v sidecar_command '%q ' \
      "$SCRIPT_PATH" --sidecar --sidecar-pane "$SIDECAR_PANE" --root "$ROOT_ID" \
      --coordinator "$COORDINATOR" --max-retries "$MAX_RETRIES"
  elif [[ -n "$TIMEOUT_MS" ]]; then
    printf -v sidecar_command '%q ' \
      "$SCRIPT_PATH" --sidecar --sidecar-pane "$SIDECAR_PANE" --root "$ROOT_ID" \
      --coordinator "$COORDINATOR" --timeout-ms "$TIMEOUT_MS"
  else
    printf -v sidecar_command '%q ' \
      "$SCRIPT_PATH" --sidecar --sidecar-pane "$SIDECAR_PANE" --root "$ROOT_ID" \
      --coordinator "$COORDINATOR"
  fi
  if ! herdr pane run "$SIDECAR_PANE" "$sidecar_command"; then
    herdr pane close "$SIDECAR_PANE" >/dev/null 2>&1 || true
    stop 'sidecar launch failed'
  fi
  printf 'coordinator-continuation: launched sidecar pane=%s coordinator_pane=%s direction=%s\n' \
    "$SIDECAR_PANE" "$coordinator_pane" "$SIDECAR_DIRECTION"
}

LOCK_DIR=''
LOCK_HELD=0

prepare_lock_path() {
  local lock_base lock_key

  lock_base="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
  lock_key=$(printf '%s' "$ROOT_ID" | od -An -tx1 | tr -d '[:space:]') ||
    stop 'cannot derive the ephemeral root lock'
  [[ -n "$lock_key" ]] || stop 'cannot derive the ephemeral root lock'
  LOCK_DIR="$lock_base/coordinator-continuation-$lock_key.lock"
}

release_lock() {
  if ((LOCK_HELD)); then
    rm -f "$LOCK_DIR/pid"
    rmdir "$LOCK_DIR" 2>/dev/null || true
    LOCK_HELD=0
  fi
}

acquire_sidecar_lock() {
  local owner_pid

  prepare_lock_path
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" >"$LOCK_DIR/pid"
    LOCK_HELD=1
    trap release_lock EXIT INT TERM
    return 0
  fi

  owner_pid=$(cat "$LOCK_DIR/pid" 2>/dev/null || true)
  if [[ "$owner_pid" =~ ^[1-9][0-9]*$ ]] && kill -0 "$owner_pid" 2>/dev/null; then
    if [[ -n "$SIDECAR_PANE" ]]; then
      herdr pane close "$SIDECAR_PANE" >/dev/null 2>&1 ||
        stop 'duplicate sidecar pane cleanup failed'
    fi
    stop 'another sidecar already owns the root lock'
  fi

  if [[ -n "$owner_pid" ]]; then
    rm -f "$LOCK_DIR/pid"
    rmdir "$LOCK_DIR" 2>/dev/null || stop 'root lock is ambiguous'
    acquire_sidecar_lock
  else
    if [[ -n "$SIDECAR_PANE" ]]; then
      herdr pane close "$SIDECAR_PANE" >/dev/null 2>&1 ||
        stop 'ambiguous sidecar pane cleanup failed'
    fi
    stop 'root lock is ambiguous'
  fi
}

read_root() {
  local root_json

  if ! root_json=$(bd show "$ROOT_ID" --long --json 2>/dev/null); then
    return 1
  fi
  jq -e --arg root "$ROOT_ID" --arg driver "$SCRIPT_NAME" '
    length == 1 and .[0].id == $root and
    (.[0].metadata.recovery.active_attempts | type == "array") and
    (.[0].metadata.coordinator_continuity as $contract |
      ($contract | type == "object") and
      ($contract.enabled == true) and
      ($contract.driver == $driver) and
      ($contract.mode | type == "string" and length > 0) and
      ($contract.decision | type == "string" and length > 0) and
      ($contract.waits_for | type == "string" and length > 0) and
      ($contract.max_retries | if type == "number" then . == floor and . > 0 else false end) and
      ($contract.poll_ms | if type == "number" then . == floor and . >= 1000 else false end) and
      ($contract.requires | type == "array" and length > 0) and
      ($contract.stops | type == "array" and length > 0) and
      ($contract.prohibits | type == "array" and length > 0) and
      ($contract.sidecar_layout as $layout |
        ($layout | type == "object") and
        ($layout.target == "exact_coordinator_pane") and
        ($layout.direction == "down") and
        ($layout.duplicate_cleanup == "close_only_new_sidecar_pane")
      ) and
      ($contract.context_rotation | type == "object") and
      ($contract.context_rotation.enabled | type == "boolean") and
      (if $contract.context_rotation.enabled then
        ($contract.context_rotation.threshold_percent |
          if type == "number" then . == floor and . > 0 and . <= 100 else false end) and
        ($contract.context_rotation.requires | type == "array" and length > 0) and
        ($contract.context_rotation.coordinator | type == "object") and
        ($contract.context_rotation.coordinator.provider | type == "string" and length > 0) and
        ($contract.context_rotation.coordinator.model | type == "string" and length > 0) and
        ($contract.context_rotation.coordinator.thinking | type == "string" and length > 0)
      else true end)
    )
  ' >/dev/null <<<"$root_json" || return 1

  ROOT_CONTRACT_JSON=$(jq -c '.[0].metadata.coordinator_continuity' <<<"$root_json")
  ROOT_STATUS=$(jq -r '.[0].status' <<<"$root_json")
  RECOVERY_STATE=$(jq -r '.[0].metadata.recovery.state // ""' <<<"$root_json")
  ACTIVE_ATTEMPTS=$(jq -r '.[0].metadata.recovery.active_attempts | length' <<<"$root_json")
  ROOT_DECISION=$(jq -r '.[0].metadata.coordinator_continuity.decision' <<<"$root_json")
  ROOT_MODE=$(jq -r '.[0].metadata.coordinator_continuity.mode' <<<"$root_json")
  ROOT_MAX_RETRIES=$(jq -r '.[0].metadata.coordinator_continuity.max_retries' <<<"$root_json")
  ROOT_POLL_MS=$(jq -r '.[0].metadata.coordinator_continuity.poll_ms' <<<"$root_json")
  ROOT_WAITS_FOR=$(jq -r '.[0].metadata.coordinator_continuity.waits_for' <<<"$root_json")
  SIDECAR_DIRECTION=$(jq -r '.[0].metadata.coordinator_continuity.sidecar_layout.direction' <<<"$root_json")
  CONTEXT_ENABLED=$(jq -r '.[0].metadata.coordinator_continuity.context_rotation.enabled' <<<"$root_json")
  if [[ "$CONTEXT_ENABLED" == true ]]; then
    CONTEXT_THRESHOLD=$(jq -r '.[0].metadata.coordinator_continuity.context_rotation.threshold_percent' <<<"$root_json")
    COORDINATOR_PROVIDER=$(jq -r '.[0].metadata.coordinator_continuity.context_rotation.coordinator.provider' <<<"$root_json")
    COORDINATOR_MODEL=$(jq -r '.[0].metadata.coordinator_continuity.context_rotation.coordinator.model' <<<"$root_json")
    COORDINATOR_THINKING=$(jq -r '.[0].metadata.coordinator_continuity.context_rotation.coordinator.thinking' <<<"$root_json")
  fi
}

read_decision() {
  local decision_json

  if ! decision_json=$(bd show "$ROOT_DECISION" --long --json 2>/dev/null); then
    return 1
  fi
  jq -e --arg decision "$ROOT_DECISION" --arg driver "$SCRIPT_NAME" \
    --argjson contract "$ROOT_CONTRACT_JSON" '
    length == 1 and .[0].id == $decision and
    .[0].status == "closed" and
    .[0].issue_type == "decision" and
    (.[0].metadata.decision as $decision_meta |
      ($decision_meta | type == "object") and
      ($decision_meta.state == "approved") and
      ($decision_meta.approved == true) and
      ($decision_meta.kind | type == "string" and length > 0) and
      ($decision_meta.scope | type == "string" and length > 0)
    ) and
    (.[0].metadata.driver as $decision_driver |
      ($decision_driver | type == "object" and length > 0) and
      (if ($decision_driver | has("name")) then $decision_driver.name == $driver else true end) and
      (if ($decision_driver | has("mode")) then $decision_driver.mode == $contract.mode else true end) and
      (if ($decision_driver | has("max_retries")) then $decision_driver.max_retries == $contract.max_retries else true end) and
      (if ($decision_driver | has("poll_ms")) then $decision_driver.poll_ms == $contract.poll_ms else true end) and
      (if ($decision_driver | has("waits_for")) then $decision_driver.waits_for == $contract.waits_for else true end) and
      (if ($decision_driver | has("requires")) then $decision_driver.requires == $contract.requires else true end) and
      (if ($decision_driver | has("stops")) then $decision_driver.stops == $contract.stops else true end) and
      (if ($decision_driver | has("prohibits")) then $decision_driver.prohibits == $contract.prohibits else true end) and
      (if ($decision_driver | has("sidecar_layout")) then $decision_driver.sidecar_layout == $contract.sidecar_layout else true end) and
      (if ($decision_driver | has("context_rotation")) then
        ($decision_driver.context_rotation as $decision_rotation |
          ($decision_rotation | type == "object") and
          ($decision_rotation.enabled == $contract.context_rotation.enabled) and
          (if $contract.context_rotation.enabled then
            ($decision_rotation.threshold_percent == $contract.context_rotation.threshold_percent) and
            ($decision_rotation.requires == $contract.context_rotation.requires)
          else true end)
        )
      else true end)
    )
  ' >/dev/null <<<"$decision_json"
}

read_context() {
  local footer matches match_count

  # Agent scrollback can quote prior Herdr reads, including their Pi footers.
  # Only the final rendered Pi footer describes the current coordinator context.
  footer=$(printf '%s\n' "$COORDINATOR_OUTPUT" |
    grep -E '[0-9]+([.][0-9]+)?%/[0-9]+([.][0-9]+)?[kKmMgGtT]? \(auto\)' |
    tail -n 1 || true)
  matches=$(printf '%s\n' "$footer" |
    grep -Eo '[0-9]+([.][0-9]+)?%/[0-9]+([.][0-9]+)?[kKmMgGtT]? \(auto\)' || true)
  match_count=$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')
  [[ "$match_count" == 1 ]] || return 1
  CONTEXT_PERCENT=$(printf '%s\n' "$matches" | sed 's/%\/.*//')
  awk -v percent="$CONTEXT_PERCENT" 'BEGIN {
    exit !(percent ~ /^[0-9]+([.][0-9]+)?$/ && percent >= 0 && percent <= 100)
  }' || return 1
  if awk -v current="$CONTEXT_PERCENT" -v threshold="$CONTEXT_THRESHOLD" \
    'BEGIN { exit !(current >= threshold) }'; then
    CONTEXT_AT_THRESHOLD=1
  else
    CONTEXT_AT_THRESHOLD=0
  fi
}

read_coordinator() {
  local agent_json

  if ! agent_json=$(herdr agent get "$COORDINATOR" 2>/dev/null); then
    return 1
  fi
  jq -e '
    .result.agent.agent_status as $status |
    ($status == "idle" or $status == "done" or $status == "working" or
      $status == "blocked" or $status == "unknown") and
    (.result.agent.pane_id | type == "string" and length > 0) and
    ((.result.agent.name // .result.agent.agent) | type == "string" and length > 0) and
    (.result.agent.agent_session.source | type == "string" and length > 0) and
    (.result.agent.agent | type == "string" and length > 0) and
    (.result.agent.state_change_seq | type == "number" and . == floor and . >= 0)
  ' >/dev/null <<<"$agent_json" || return 1
  COORDINATOR_STATUS=$(jq -r '.result.agent.agent_status' <<<"$agent_json")
  COORDINATOR_PANE_ID=$(jq -r '.result.agent.pane_id' <<<"$agent_json")
  COORDINATOR_NAME=$(jq -r '.result.agent.name // .result.agent.agent' <<<"$agent_json")
  COORDINATOR_LIFECYCLE_SOURCE=$(jq -r '.result.agent.agent_session.source' <<<"$agent_json")
  COORDINATOR_LIFECYCLE_AGENT=$(jq -r '.result.agent.agent' <<<"$agent_json")
  COORDINATOR_LIFECYCLE_SEQ=$(jq -r '.result.agent.state_change_seq' <<<"$agent_json")

  if [[ "$CONTEXT_ENABLED" == true ]]; then
    if ! COORDINATOR_OUTPUT=$(herdr agent read "$COORDINATOR" --source recent-unwrapped --lines 100 2>/dev/null); then
      return 1
    fi
    read_context || return 1
  fi
}

prompt_coordinator() {
  local target="$1" prompt="$2"

  if [[ -n "$TIMEOUT_MS" ]]; then
    herdr agent prompt "$target" "$prompt" --wait --timeout "$TIMEOUT_MS"
  else
    herdr agent prompt "$target" "$prompt" --wait
  fi
}

wait_for_coordinator_shell() {
  local pane_json pane_status deadline

  deadline=$((SECONDS + 30))
  while ((SECONDS < deadline)); do
    pane_json=$(herdr pane get "$COORDINATOR_PANE_ID") || return 1
    pane_status=$(jq -r '.result.pane.agent_status // "unknown"' <<<"$pane_json") || return 1
    [[ "$pane_status" == "unknown" ]] && return 0
    sleep 1
  done
  return 1
}

rotate_coordinator() {
  local rotation_prompt

  printf 'coordinator-continuation: context threshold reached; rotating target=%s pane=%s provider=%s model=%s thinking=%s\n' \
    "$COORDINATOR" "$COORDINATOR_PANE_ID" "$COORDINATOR_PROVIDER" \
    "$COORDINATOR_MODEL" "$COORDINATOR_THINKING"
  if ! herdr agent send-keys "$COORDINATOR" ctrl+c; then
    stop 'exact coordinator cancellation failed'
  fi
  if ! herdr agent send-keys "$COORDINATOR" ctrl+d; then
    stop 'exact coordinator exit failed'
  fi
  if ! wait_for_coordinator_shell; then
    stop 'exact coordinator did not return to a shell'
  fi
  if ! herdr pane release-agent "$COORDINATOR_PANE_ID" \
    --source "$COORDINATOR_LIFECYCLE_SOURCE" \
    --agent "$COORDINATOR_LIFECYCLE_AGENT" \
    --seq "$COORDINATOR_LIFECYCLE_SEQ"; then
    stop 'exact coordinator lifecycle release failed'
  fi
  if ! herdr agent start "$COORDINATOR_NAME" --kind pi --pane "$COORDINATOR_PANE_ID" -- \
    --provider "$COORDINATOR_PROVIDER" --model "$COORDINATOR_MODEL" \
    --thinking "$COORDINATOR_THINKING" >/dev/null; then
    stop 'fresh coordinator start failed'
  fi
  rotation_prompt="Load execute-engineering-molecule, then resume the explicit root $ROOT_ID. Recover from Beads projections and Git, observe the root and active attempts, and continue the coordinator loop. This is a fresh context; do not mutate Beads, route workers, terminate panes, or change integration or acceptance."
  if ! prompt_coordinator "$COORDINATOR_NAME" "$rotation_prompt" >/dev/null; then
    stop 'fresh coordinator recovery prompt failed'
  fi
}

poll_sidecar() {
  local retry_count=0 prompt poll_seconds

  acquire_sidecar_lock
  command -v bd >/dev/null 2>&1 || stop 'bd is unavailable'

  while :; do
    read_root || stop 'root contract or state is missing or invalid'
    read_decision || stop 'approved decision is missing or does not match the root contract'

    case "$ROOT_STATUS:$RECOVERY_STATE" in
      in_progress:executing|executing:executing) ;;
      blocked:*|*:blocked) stop 'root is blocked' ;;
      closed:*|*:closed) stop 'root is closed' ;;
      *) stop "root is not executing (status=$ROOT_STATUS recovery=$RECOVERY_STATE)" ;;
    esac
    ((ACTIVE_ATTEMPTS > 0)) || stop 'root has no active attempts'
    ((ROOT_POLL_MS >= 1000 && ROOT_POLL_MS % 1000 == 0)) ||
      stop 'polling interval is not a safe whole-second value'
    poll_seconds=$((ROOT_POLL_MS / 1000))

    if [[ -z "$MAX_RETRIES" ]]; then
      MAX_RETRIES=$ROOT_MAX_RETRIES
    elif ((MAX_RETRIES > ROOT_MAX_RETRIES)); then
      stop 'requested retries exceed the root contract'
    fi

    read_coordinator || stop 'coordinator state or Pi context is missing or ambiguous'
    printf 'coordinator-continuation: poll root=%s root_status=%s recovery=%s active_attempts=%d coordinator=%s coordinator_status=%s mode=%s retries=%d/%d poll_ms=%d' \
      "$ROOT_ID" "$ROOT_STATUS" "$RECOVERY_STATE" "$ACTIVE_ATTEMPTS" \
      "$COORDINATOR" "$COORDINATOR_STATUS" "$ROOT_MODE" "$retry_count" \
      "$MAX_RETRIES" "$ROOT_POLL_MS"
    if [[ "$CONTEXT_ENABLED" == true ]]; then
      printf ' context=%s%% threshold=%s%%' "$CONTEXT_PERCENT" "$CONTEXT_THRESHOLD"
    fi
    printf '\n'

    case "$COORDINATOR_STATUS" in
      blocked) stop 'coordinator is blocked' ;;
      unknown) stop 'coordinator state is unknown' ;;
      working|idle|done) ;;
      *) stop "unrecognized coordinator state: $COORDINATOR_STATUS" ;;
    esac

    ((retry_count < MAX_RETRIES)) || stop 'maximum retries reached'

    if [[ "$CONTEXT_ENABLED" == true && "$CONTEXT_AT_THRESHOLD" == 1 ]]; then
      retry_count=$((retry_count + 1))
      printf 'coordinator-continuation: context-aware rotation consumes retry %d/%d\n' \
        "$retry_count" "$MAX_RETRIES"
      rotate_coordinator
    elif [[ "$COORDINATOR_STATUS" == working ]]; then
      printf 'coordinator-continuation: coordinator working; waiting %ss before next poll\n' "$poll_seconds"
      sleep "$poll_seconds"
    else
      retry_count=$((retry_count + 1))
      printf 'coordinator-continuation: settled coordinator; submitting retry %d/%d\n' \
        "$retry_count" "$MAX_RETRIES"
      prompt="Coordinator continuation for root $ROOT_ID: re-observe the root and every active attempt, persist the observed transition or exact next instruction before routing or steering, then wait. Do not return status-only while active attempts remain. This bounded polling sidecar is transport-only; do not mutate Beads, route workers, or terminate panes."
      if ! prompt_coordinator "$COORDINATOR" "$prompt" >/dev/null; then
        stop 'coordinator prompt/wait timed out or transport failed'
      fi
    fi
  done
}

if ((SIDECAR)); then
  poll_sidecar
else
  launch_sidecar
fi

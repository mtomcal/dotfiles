#!/bin/bash
# Usage: ./loop.sh [max_iterations] [prompt_file]
# Defaults: 25 iterations, PROMPT.md
#
# Environment:
#   SANDBOX_MODE=workspace-write|read-only|danger-full-access (default: workspace-write)
#   RALPH_DANGER_FULL_ACCESS_APPROVED=1 (required after explicit human approval)

set -euo pipefail

if [ "$#" -gt 2 ]; then
  echo "ERROR: usage: ./loop.sh [max_iterations] [prompt_file]" >&2
  exit 2
fi

MAX_ITERATIONS="${1:-25}"
PROMPT_FILE="${2:-PROMPT.md}"
SANDBOX_MODE="${SANDBOX_MODE:-workspace-write}"
LOG_DIR=".loop-logs"
DONE_SENTINEL="/done"

if ! [[ "$MAX_ITERATIONS" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: max_iterations must be a positive integer: $MAX_ITERATIONS" >&2
  exit 2
fi

case "$SANDBOX_MODE" in
  workspace-write|read-only) ;;
  danger-full-access)
    if [ "${RALPH_DANGER_FULL_ACCESS_APPROVED:-}" != "1" ]; then
      echo "ERROR: danger-full-access requires explicit human approval and RALPH_DANGER_FULL_ACCESS_APPROVED=1" >&2
      exit 2
    fi
    ;;
  *)
    echo "ERROR: invalid SANDBOX_MODE: $SANDBOX_MODE" >&2
    exit 2
    ;;
esac

if ! command -v codex >/dev/null 2>&1; then
  echo "ERROR: codex not found. Install with: npm install -g @openai/codex" >&2
  exit 1
fi

if [ ! -r "$PROMPT_FILE" ]; then
  echo "ERROR: prompt file not readable: $PROMPT_FILE" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 || ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "ERROR: Ralph requires a Git repository with an existing HEAD" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"
echo "Ralph loop: max_iterations=$MAX_ITERATIONS prompt=$PROMPT_FILE sandbox=$SANDBOX_MODE"

for ((ITERATION = 1; ITERATION <= MAX_ITERATIONS; ITERATION++)); do
  LOG_FILE="$LOG_DIR/iteration-$ITERATION.log"
  LAST_MESSAGE_FILE="$LOG_DIR/iteration-$ITERATION.last-message.md"
  BEFORE_HEAD="$(git rev-parse HEAD)"
  rm -f "$LAST_MESSAGE_FILE"

  echo "=== Iteration $ITERATION/$MAX_ITERATIONS ===" | tee "$LOG_FILE"

  # A new codex exec process rereads PROMPT_FILE through stdin every iteration.
  set +e
  codex exec --full-auto --sandbox "$SANDBOX_MODE" -C "$(pwd)" \
    --output-last-message "$LAST_MESSAGE_FILE" - < "$PROMPT_FILE" 2>&1 | tee -a "$LOG_FILE"
  PIPE_STATUS=("${PIPESTATUS[@]}")
  set -e
  CODEX_EXIT="${PIPE_STATUS[0]}"
  TEE_EXIT="${PIPE_STATUS[1]}"

  if [ "$TEE_EXIT" -ne 0 ]; then
    echo "ERROR: logging failed ($TEE_EXIT). Stop and inspect $LOG_FILE before rerunning." >&2
    exit "$TEE_EXIT"
  fi

  if [ "$CODEX_EXIT" -ne 0 ]; then
    echo "ERROR: codex exited non-zero ($CODEX_EXIT). Stop and inspect $LOG_FILE before rerunning." | tee -a "$LOG_FILE" >&2
    exit "$CODEX_EXIT"
  fi

  if [ ! -f "$LAST_MESSAGE_FILE" ]; then
    echo "ERROR: codex produced no final-message evidence: $LAST_MESSAGE_FILE" | tee -a "$LOG_FILE" >&2
    exit 1
  fi

  AFTER_HEAD="$(git rev-parse HEAD)"
  if [ "$AFTER_HEAD" = "$BEFORE_HEAD" ]; then
    echo "ERROR: iteration $ITERATION produced no commit. Stop and inspect $LOG_FILE before rerunning." | tee -a "$LOG_FILE" >&2
    exit 1
  fi

  if ! git merge-base --is-ancestor "$BEFORE_HEAD" "$AFTER_HEAD"; then
    echo "ERROR: iteration $ITERATION rewrote or replaced history instead of adding descendant commits." | tee -a "$LOG_FILE" >&2
    exit 1
  fi

  COMMIT_COUNT="$(git rev-list --count "$BEFORE_HEAD..$AFTER_HEAD")"
  echo "Commit evidence: $BEFORE_HEAD..$AFTER_HEAD ($COMMIT_COUNT commit(s))" | tee -a "$LOG_FILE"
  git log --format='  %H %s' "$BEFORE_HEAD..$AFTER_HEAD" | tee -a "$LOG_FILE"

  # Command substitution removes trailing newlines; all other text prevents equality.
  if [ "$(cat "$LAST_MESSAGE_FILE")" = "$DONE_SENTINEL" ]; then
    echo "Exact done sentinel received after iteration $ITERATION: $DONE_SENTINEL" | tee -a "$LOG_FILE"
    exit 0
  fi
done

echo "ERROR: reached max iterations ($MAX_ITERATIONS) without exact done sentinel ($DONE_SENTINEL)." >&2
exit 2


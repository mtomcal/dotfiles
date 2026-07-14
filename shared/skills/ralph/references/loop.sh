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

# Evidence sequence numbers persist across invocations; the worker bound does not.
HIGHEST_EVIDENCE_SEQUENCE=0
shopt -s nullglob
for EVIDENCE_PATH in \
  "$LOG_DIR"/iteration-*.log \
  "$LOG_DIR"/iteration-*.last-message.md \
  "$LOG_DIR"/.iteration-*.claim; do
  EVIDENCE_NAME="${EVIDENCE_PATH##*/}"
  EVIDENCE_SEQUENCE=""
  if [[ "$EVIDENCE_NAME" =~ ^iteration-([1-9][0-9]*)\.log$ ]] ||
    [[ "$EVIDENCE_NAME" =~ ^iteration-([1-9][0-9]*)\.last-message\.md$ ]] ||
    [[ "$EVIDENCE_NAME" =~ ^\.iteration-([1-9][0-9]*)\.claim$ ]]; then
    EVIDENCE_SEQUENCE="${BASH_REMATCH[1]}"
  fi
  if [ -n "$EVIDENCE_SEQUENCE" ] && ((EVIDENCE_SEQUENCE > HIGHEST_EVIDENCE_SEQUENCE)); then
    HIGHEST_EVIDENCE_SEQUENCE="$EVIDENCE_SEQUENCE"
  fi
done
shopt -u nullglob
FIRST_EVIDENCE_SEQUENCE=$((HIGHEST_EVIDENCE_SEQUENCE + 1))

echo "Ralph loop: max_iterations=$MAX_ITERATIONS prompt=$PROMPT_FILE sandbox=$SANDBOX_MODE first_evidence_sequence=$FIRST_EVIDENCE_SEQUENCE"

for ((RUN_ITERATION = 1; RUN_ITERATION <= MAX_ITERATIONS; RUN_ITERATION++)); do
  EVIDENCE_SEQUENCE=$((FIRST_EVIDENCE_SEQUENCE + RUN_ITERATION - 1))
  CLAIM_DIR="$LOG_DIR/.iteration-$EVIDENCE_SEQUENCE.claim"
  LOG_FILE="$LOG_DIR/iteration-$EVIDENCE_SEQUENCE.log"
  LAST_MESSAGE_FILE="$LOG_DIR/iteration-$EVIDENCE_SEQUENCE.last-message.md"
  CLAIMED_LAST_MESSAGE_FILE="$CLAIM_DIR/last-message.md"

  if ! mkdir "$CLAIM_DIR" 2>/dev/null; then
    echo "ERROR: evidence sequence collision: $CLAIM_DIR already exists; refusing to overwrite evidence." >&2
    exit 1
  fi
  if [ -e "$LOG_FILE" ] || [ -L "$LOG_FILE" ] || [ -e "$LAST_MESSAGE_FILE" ] || [ -L "$LAST_MESSAGE_FILE" ]; then
    echo "ERROR: evidence path collision at sequence $EVIDENCE_SEQUENCE; refusing to overwrite evidence." >&2
    exit 1
  fi
  if ! (set -o noclobber; : > "$LOG_FILE") 2>/dev/null; then
    echo "ERROR: could not create fresh evidence log: $LOG_FILE" >&2
    exit 1
  fi

  BEFORE_HEAD="$(git rev-parse HEAD)"
  echo "=== Worker iteration $RUN_ITERATION/$MAX_ITERATIONS (evidence sequence $EVIDENCE_SEQUENCE) ===" | tee -a "$LOG_FILE"

  # A new codex exec process rereads PROMPT_FILE through stdin every worker iteration.
  set +e
  codex exec --full-auto --sandbox "$SANDBOX_MODE" -C "$(pwd)" \
    --output-last-message "$CLAIMED_LAST_MESSAGE_FILE" - < "$PROMPT_FILE" 2>&1 | tee -a "$LOG_FILE"
  PIPE_STATUS=("${PIPESTATUS[@]}")
  set -e
  CODEX_EXIT="${PIPE_STATUS[0]}"
  TEE_EXIT="${PIPE_STATUS[1]}"

  if [ -f "$CLAIMED_LAST_MESSAGE_FILE" ]; then
    if ! ln "$CLAIMED_LAST_MESSAGE_FILE" "$LAST_MESSAGE_FILE" 2>/dev/null; then
      echo "ERROR: final-message evidence collision: $LAST_MESSAGE_FILE; refusing to overwrite evidence." | tee -a "$LOG_FILE" >&2
      exit 1
    fi
  fi

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
    echo "ERROR: worker iteration $RUN_ITERATION (evidence sequence $EVIDENCE_SEQUENCE) produced no commit. Stop and inspect $LOG_FILE before rerunning." | tee -a "$LOG_FILE" >&2
    exit 1
  fi

  if ! git merge-base --is-ancestor "$BEFORE_HEAD" "$AFTER_HEAD"; then
    echo "ERROR: worker iteration $RUN_ITERATION (evidence sequence $EVIDENCE_SEQUENCE) rewrote or replaced history instead of adding descendant commits." | tee -a "$LOG_FILE" >&2
    exit 1
  fi

  COMMIT_COUNT="$(git rev-list --count "$BEFORE_HEAD..$AFTER_HEAD")"
  echo "Commit evidence: $BEFORE_HEAD..$AFTER_HEAD ($COMMIT_COUNT commit(s))" | tee -a "$LOG_FILE"
  git log --format='  %H %s' "$BEFORE_HEAD..$AFTER_HEAD" | tee -a "$LOG_FILE"

  # Command substitution removes trailing newlines; all other text prevents equality.
  if [ "$(cat "$LAST_MESSAGE_FILE")" = "$DONE_SENTINEL" ]; then
    echo "Exact done sentinel received after worker iteration $RUN_ITERATION (evidence sequence $EVIDENCE_SEQUENCE): $DONE_SENTINEL" | tee -a "$LOG_FILE"
    exit 0
  fi
done

echo "ERROR: reached max iterations ($MAX_ITERATIONS) without exact done sentinel ($DONE_SENTINEL)." >&2
exit 2


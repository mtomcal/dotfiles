#!/bin/bash
# Usage: ./loop.sh [max_iterations] [prompt_file]
# Examples:
#   ./loop.sh              # Unlimited iterations, PROMPT.md
#   ./loop.sh 25           # Max 25 iterations
#   ./loop.sh 25 TASK.md   # Custom prompt file
#
# Environment:
#   SANDBOX_MODE=workspace-write|read-only|danger-full-access (default: workspace-write)

set -euo pipefail

MAX_ITERATIONS="${1:-0}"
PROMPT_FILE="${2:-PROMPT.md}"
SANDBOX_MODE="${SANDBOX_MODE:-workspace-write}"

ITERATION=0
LOG_DIR=".loop-logs"
DONE_PATTERN="/done"

mkdir -p "$LOG_DIR"

if ! command -v codex >/dev/null 2>&1; then
  echo "ERROR: codex not found. Install with: npm install -g @openai/codex" >&2
  exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

while true; do
  ITERATION=$((ITERATION + 1))
  if [ "$MAX_ITERATIONS" -ne 0 ] && [ "$ITERATION" -gt "$MAX_ITERATIONS" ]; then
    echo "Reached max iterations ($MAX_ITERATIONS). Exiting."
    exit 0
  fi

  LOG_FILE="$LOG_DIR/iteration-$ITERATION.log"
  echo "=== Iteration $ITERATION ===" | tee "$LOG_FILE"

  # Read instructions from PROMPT_FILE each iteration via stdin.
  set +e
  codex exec --full-auto --sandbox "$SANDBOX_MODE" -C "$(pwd)" - < "$PROMPT_FILE" 2>&1 | tee -a "$LOG_FILE"
  CODEX_EXIT="${PIPESTATUS[0]}"
  set -e

  if grep -q "$DONE_PATTERN" "$LOG_FILE"; then
    echo "Done pattern found ($DONE_PATTERN). Exiting."
    exit 0
  fi

  if [ "$CODEX_EXIT" -ne 0 ]; then
    echo "codex exited non-zero ($CODEX_EXIT). Check $LOG_FILE and fix before continuing." >&2
  fi
done


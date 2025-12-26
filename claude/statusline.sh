#!/bin/bash
# Claude Code context window meter
# Displays model name, git branch/worktree status, and context window usage

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
VERSION=$(echo "$input" | jq -r '.version // ""')

# Get git branch and dirty status
if git rev-parse --is-inside-work-tree &>/dev/null; then
    BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    # Check if in a worktree (not main working directory)
    GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
    if [[ "$GIT_DIR" == *".git/worktrees/"* ]]; then
        WORKTREE_NAME=$(basename "$(git rev-parse --show-toplevel)")
        BRANCH_DISPLAY="⎇ ${WORKTREE_NAME}:${BRANCH}"
    else
        BRANCH_DISPLAY="⎇ ${BRANCH}"
    fi

    # Check for dirty state (uncommitted changes)
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        BRANCH_DISPLAY="${BRANCH_DISPLAY} ●"
        DIRTY_COLOR="\033[33m"  # Yellow for dirty
    else
        DIRTY_COLOR="\033[36m"  # Cyan for clean
    fi
    RESET_GIT="\033[0m"
    GIT_STATUS="${DIRTY_COLOR}${BRANCH_DISPLAY}${RESET_GIT}"
else
    GIT_STATUS=""
fi
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage')

# Get session duration
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
if [ "$DURATION_MS" != "null" ] && [ "$DURATION_MS" -gt 0 ] 2>/dev/null; then
    DURATION_SEC=$((DURATION_MS / 1000))
    HOURS=$((DURATION_SEC / 3600))
    MINUTES=$(((DURATION_SEC % 3600) / 60))
    SECONDS=$((DURATION_SEC % 60))

    if [ "$HOURS" -gt 0 ]; then
        DURATION_DISPLAY="⏱ ${HOURS}h${MINUTES}m"
    elif [ "$MINUTES" -gt 0 ]; then
        DURATION_DISPLAY="⏱ ${MINUTES}m${SECONDS}s"
    else
        DURATION_DISPLAY="⏱ ${SECONDS}s"
    fi
else
    DURATION_DISPLAY=""
fi

# Get session cost
COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
if [ "$COST_USD" != "null" ] && [ "$COST_USD" != "0" ] 2>/dev/null; then
    # Round to 2 decimal places
    COST_ROUNDED=$(printf "%.2f" "$COST_USD")
    COST_DISPLAY="\033[35m\$${COST_ROUNDED}\033[0m"  # Magenta
else
    COST_DISPLAY=""
fi

if [ "$USAGE" != "null" ] && [ -n "$USAGE" ]; then
    CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    if [ "$CURRENT_TOKENS" != "null" ] && [ "$CONTEXT_SIZE" -gt 0 ] 2>/dev/null; then
        PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))

        # Build smooth progress bar (15 chars wide, using partial blocks)
        BAR_WIDTH=15
        TOTAL_EIGHTHS=$((PERCENT_USED * BAR_WIDTH * 8 / 100))
        FULL_BLOCKS=$((TOTAL_EIGHTHS / 8))
        REMAINDER=$((TOTAL_EIGHTHS % 8))

        # Partial block characters (0-7 eighths)
        PARTIALS=(" " "▏" "▎" "▍" "▌" "▋" "▊" "▉")

        # Color based on usage: green < 50%, yellow 50-75%, red > 75%
        if [ "$PERCENT_USED" -lt 50 ]; then
            COLOR="\033[32m"  # Green
        elif [ "$PERCENT_USED" -lt 75 ]; then
            COLOR="\033[33m"  # Yellow
        else
            COLOR="\033[31m"  # Red
        fi
        RESET="\033[0m"

        BAR=""
        for ((i=0; i<FULL_BLOCKS; i++)); do BAR+="█"; done
        if [ "$FULL_BLOCKS" -lt "$BAR_WIDTH" ]; then
            BAR+="${PARTIALS[$REMAINDER]}"
            EMPTY=$((BAR_WIDTH - FULL_BLOCKS - 1))
            for ((i=0; i<EMPTY; i++)); do BAR+=" "; done
        fi

        # Build output with optional components
        OUTPUT="[$MODEL]"
        [ -n "$VERSION" ] && OUTPUT+=" v${VERSION}"
        [ -n "$GIT_STATUS" ] && OUTPUT+=" ${GIT_STATUS}"
        OUTPUT+=" ${COLOR}▐${BAR}▌${RESET} ${PERCENT_USED}%"
        [ -n "$DURATION_DISPLAY" ] && OUTPUT+=" ${DURATION_DISPLAY}"
        [ -n "$COST_DISPLAY" ] && OUTPUT+=" ${COST_DISPLAY}"
        echo -e "$OUTPUT"
    else
        OUTPUT="[$MODEL]"
        [ -n "$VERSION" ] && OUTPUT+=" v${VERSION}"
        [ -n "$GIT_STATUS" ] && OUTPUT+=" ${GIT_STATUS}"
        [ -n "$DURATION_DISPLAY" ] && OUTPUT+=" ${DURATION_DISPLAY}"
        [ -n "$COST_DISPLAY" ] && OUTPUT+=" ${COST_DISPLAY}"
        echo -e "$OUTPUT"
    fi
else
    OUTPUT="[$MODEL]"
    [ -n "$VERSION" ] && OUTPUT+=" v${VERSION}"
    [ -n "$GIT_STATUS" ] && OUTPUT+=" ${GIT_STATUS}"
    [ -n "$DURATION_DISPLAY" ] && OUTPUT+=" ${DURATION_DISPLAY}"
    [ -n "$COST_DISPLAY" ] && OUTPUT+=" ${COST_DISPLAY}"
    echo -e "$OUTPUT"
fi

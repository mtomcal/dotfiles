#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-$PWD}"
REAL_PI_BIN="${PI_BIN:-$HOME_DIR/.local/bin/pi-bin}"
PI_AGENT_DIR="$HOME_DIR/.pi/agent"

if [[ ! -e "$REAL_PI_BIN" ]]; then
    printf 'pi: real Pi binary not found: %s\n' "$REAL_PI_BIN" >&2
    exit 1
fi

if [[ "${PI_WRAPPER_DRY_RUN:-0}" == "1" ]]; then
    printf 'runtime=%s\n' "$PI_AGENT_DIR"
    printf 'binary=%s\n' "$REAL_PI_BIN"
    printf 'home=%s\n' "$HOME_DIR"
    exit 0
fi

exec "$REAL_PI_BIN" "$@"

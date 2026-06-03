#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    LINK_TARGET="$(readlink "$SCRIPT_PATH")"
    if [[ "$LINK_TARGET" = /* ]]; then
        SCRIPT_PATH="$LINK_TARGET"
    else
        SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_PATH")" && cd "$(dirname "$LINK_TARGET")" && pwd)/$(basename "$LINK_TARGET")"
    fi
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# shellcheck source=lib/pim.sh
source "$SCRIPT_DIR/lib/pim.sh"

HOME_DIR="$(pim_home_dir)"
COMMAND_NAME="${0##*/}"
EXPLICIT_PROFILE="$(pim_profile_from_command_name "$COMMAND_NAME" "pi")"
pim_resolve_runtime_profile "$HOME_DIR" "$EXPLICIT_PROFILE"

REAL_PI_BIN="${PI_BIN:-$HOME_DIR/.local/bin/pi-bin}"
if [[ ! -e "$REAL_PI_BIN" ]]; then
    printf 'pi: real Pi binary not found: %s\n' "$REAL_PI_BIN" >&2
    exit 1
fi

if [[ "${PI_WRAPPER_DRY_RUN:-0}" == "1" ]]; then
    printf 'profile=%s\n' "$PIM_RESOLVED_PROFILE"
    printf 'runtime=%s\n' "$PIM_RESOLVED_RUNTIME"
    printf 'binary=%s\n' "$REAL_PI_BIN"
    if [[ -n "$EXPLICIT_PROFILE" ]]; then
        printf 'home=%s\n' "$HOME_DIR/.pi/profile-homes/$PIM_RESOLVED_PROFILE"
    else
        printf 'home=%s\n' "$HOME_DIR"
    fi
    exit 0
fi

if [[ -n "$EXPLICIT_PROFILE" ]]; then
    PROFILE_HOME="$HOME_DIR/.pi/profile-homes/$PIM_RESOLVED_PROFILE"
    mkdir -p "$PROFILE_HOME/.pi"
    if [[ -L "$PROFILE_HOME/.pi/agent" ]]; then
        rm "$PROFILE_HOME/.pi/agent"
    elif [[ -e "$PROFILE_HOME/.pi/agent" ]]; then
        printf 'pi: profile shim path exists and is not a symlink: %s\n' "$PROFILE_HOME/.pi/agent" >&2
        exit 1
    fi
    ln -s "$PIM_RESOLVED_RUNTIME" "$PROFILE_HOME/.pi/agent"
    export HOME="$PROFILE_HOME"
fi

exec "$REAL_PI_BIN" "$@"

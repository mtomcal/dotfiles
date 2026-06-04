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

# Subcommands that pim recognizes (used for bare-arg disambiguation)
_KNOWN_CMDS="list current path doctor create activate use help -h --help"

usage() {
    cat >&2 <<'EOF'
Usage: pim [command]

Commands:
  list                 List source profiles
  current              Print active profile
  <profile>            Activate a profile (build + deploy)
  path <profile>       Print deployed runtime path
  doctor               Validate active profile state
  create <profile>     Scaffold a profile
  activate <profile>   Build and deploy, activate the profile
                          (same as 'use', listed for readability)
EOF
}

require_profile() {
    local profile="${1:-}"
    if [[ -z "$profile" ]]; then
        usage
        exit 2
    fi
    if ! pim_validate_profile_name "$profile"; then
        printf 'pim: invalid profile name: %s\n' "$profile" >&2
        exit 1
    fi
}

profile_exists() {
    local root="$1"
    local profile="$2"
    [[ -d "$root/pi/profiles/$profile" ]]
}

cmd_dashboard() {
    local root profiles_dir name resolved deployed home active_link runtime current
    root="$(pim_dotfiles_dir)"
    profiles_dir="$root/pi/profiles"
    [[ -d "$profiles_dir" ]] || return 0

    home="$(pim_home_dir)"
    active_link="$(pim_active_agent_link "$home")"

    for profile_path in "$profiles_dir"/*; do
        [[ -d "$profile_path" ]] || continue
        name="$(basename "$profile_path")"

        resolved="NO"
        if [[ -d "$profile_path/resolved" ]]; then
            resolved="YES"
        fi

        deployed="NO"
        runtime="$home/.pi/profiles/$name/agent"
        if [[ -d "$runtime" ]]; then
            deployed="YES"
        fi

        local marker="  "
        if [[ -L "$active_link" ]]; then
            local current
            current="$(cmd_current)"
            if [[ "$current" == "$name" ]]; then
                marker="*"
            fi
        fi

        printf '%s %-12s resolved=%-6s deployed=%s\n' "$marker" "$name" "$resolved" "$deployed"
    done | sort -k2
}

cmd_list() {
    local root profiles_dir profile
    root="$(pim_dotfiles_dir)"
    profiles_dir="$root/pi/profiles"
    [[ -d "$profiles_dir" ]] || return 0

    for profile in "$profiles_dir"/*; do
        [[ -d "$profile" ]] || continue
        basename "$profile"
    done | sort
}

cmd_current() {
    local home active_file
    home="$(pim_home_dir)"
    active_file="$(pim_active_profile_file "$home")"
    if [[ -f "$active_file" ]]; then
        sed -n '1p' "$active_file"
    else
        pim_default_profile
    fi
}

cmd_path() {
    local profile="$1"
    require_profile "$profile"
    pim_profile_runtime_dir "$(pim_home_dir)" "$profile"
}

# Activate a profile: always build→deploy, then atomically swap active state.
cmd_activate() {
    local profile="$1"
    require_profile "$profile"

    local root home runtime active_link active_file tmp_link
    root="$(pim_dotfiles_dir)"
    home="$(pim_home_dir)"
    runtime="$(pim_profile_runtime_dir "$home" "$profile")"
    active_link="$(pim_active_agent_link "$home")"
    active_file="$(pim_active_profile_file "$home")"

    if ! profile_exists "$root" "$profile"; then
        printf 'pim: profile not found: %s\n' "$profile" >&2
        exit 1
    fi

    # ── build phase (always runs) ──
    PIM_DOTFILES_DIR="$root" pim_build_profile "$profile" || {
        printf 'pim: activate failed during build\n' >&2
        return 1
    }

    # ── deploy phase (always runs) ──
    pim_deploy_profile "$profile" || {
        printf 'pim: activate failed during deploy\n' >&2
        return 1
    }

    # ── atomically swap active state ──
    tmp_link="$home/.pi/.agent.tmp.$$"
    mkdir -p "$home/.pi"
    ln -s "$runtime" "$tmp_link"
    mv -Tf "$tmp_link" "$active_link" 2>/dev/null || {
        rm -f "$active_link"
        mv "$tmp_link" "$active_link"
    }
    printf '%s\n' "$profile" > "$active_file"
    printf 'activated profile: %s\n' "$profile"
}

cmd_doctor() {
    local root home profile runtime active_link shared
    root="$(pim_dotfiles_dir)"
    home="$(pim_home_dir)"
    profile="$(cmd_current)"
    runtime="$(pim_profile_runtime_dir "$home" "$profile")"
    active_link="$(pim_active_agent_link "$home")"
    shared="$root/shared/skills"

    [[ -d "$shared" ]] || { printf 'pim: missing shared skills: %s\n' "$shared" >&2; return 1; }
    pim_validate_no_duplicate_profile_skills "$shared" "$root/pi/profiles/$profile/skills" || return 1
    [[ -L "$active_link" ]] || { printf 'pim: active agent path is not a symlink: %s\n' "$active_link" >&2; return 1; }
    [[ "$(readlink "$active_link")" == "$runtime" ]] || {
        printf 'pim: active agent symlink target is wrong for profile %s\n' "$profile" >&2; return 1
    }
    [[ -d "$runtime" ]] || { printf 'pim: active runtime missing: %s\n' "$runtime" >&2; return 1; }

    printf 'pim doctor: ok\n'
}

cmd_create() {
    local profile="$1"
    require_profile "$profile"

    local root profile_dir
    root="$(pim_dotfiles_dir)"
    profile_dir="$root/pi/profiles/$profile"
    if [[ -e "$profile_dir" ]]; then
        printf 'pim: profile already exists: %s\n' "$profile" >&2
        exit 1
    fi

    mkdir -p "$profile_dir/skills" "$profile_dir/agents"
    printf 'PI_PROFILE=%s\n' "$profile" > "$profile_dir/profile.env"
    if [[ -f "$root/pi/base/extensions.list" ]]; then
        cp "$root/pi/base/extensions.list" "$profile_dir/extensions.list"
    else
        : > "$profile_dir/extensions.list"
    fi

    printf 'created profile: %s\n' "$profile"
}

main() {
    local command="${1:-}"
    shift || true

    # ── zero-argument → dashboard ──
    if [[ -z "$command" ]]; then
        cmd_dashboard
        return 0
    fi

    # ── known subcommand routes ──
    case "$command" in
        list)     cmd_list "$@" ;;
        current)  cmd_current "$@" ;;
        path)     cmd_path "${1:-}" ;;
        activate | use)
                    [[ -n "${1:-}" ]] || { usage; exit 2; }
                    cmd_activate "$1" ;;
        doctor)   cmd_doctor "$@" ;;
        create)   cmd_create "${1:-}" ;;
        help | -h | --help) usage ;;
        *)

            # ── bare-arg disambiguation: treat as profile name to activate ──
            if pim_validate_profile_name "$command"; then
                cmd_activate "$command"
            else
                printf 'pim: unknown command: %s\n  Try --help for usage\n' "$command" >&2
                exit 1
            fi
            ;;
    esac
}

main "$@"

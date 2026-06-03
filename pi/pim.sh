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

usage() {
    cat >&2 <<'EOF'
Usage: pim <command> [args]

Commands:
  list                 List source profiles
  current              Print active profile
  use <profile>        Make a deployed profile active
  path <profile>       Print deployed runtime path
  doctor               Validate active profile state
  create <profile>     Scaffold and build a profile
  build [profile]      Build one profile, or all profiles
  deploy [profile]     Deploy resolved output to ~/.pi/profiles
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

cmd_use() {
    local profile="$1"
    require_profile "$profile"

    local root home runtime active_link active_file tmp_link
    root="$(pim_dotfiles_dir)"
    home="$(pim_home_dir)"
    runtime="$(pim_profile_runtime_dir "$home" "$profile")"
    active_link="$(pim_active_agent_link "$home")"
    active_file="$(pim_active_profile_file "$home")"
    tmp_link="$home/.pi/.agent.tmp.$$"

    if ! profile_exists "$root" "$profile"; then
        printf 'pim: profile not found: %s\n' "$profile" >&2
        exit 1
    fi
    if [[ ! -d "$runtime" ]]; then
        pim_deploy_profile "$profile" || exit 1
    fi

    mkdir -p "$home/.pi"
    ln -s "$runtime" "$tmp_link"
    mv -Tf "$tmp_link" "$active_link" 2>/dev/null || {
        rm -f "$active_link"
        mv "$tmp_link" "$active_link"
    }
    printf '%s\n' "$profile" > "$active_file"
    printf 'active profile: %s\n' "$profile"
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
        printf 'pim: active agent symlink target is wrong for profile %s\n' "$profile" >&2
        return 1
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
    PIM_DOTFILES_DIR="$root" pim_build_profile "$profile"
    printf 'created profile: %s\n' "$profile"
}

cmd_build() {
    local profile="${1:-}"
    local root profile_dir
    root="$(pim_dotfiles_dir)"

    if [[ -n "$profile" ]]; then
        require_profile "$profile"
        PIM_DOTFILES_DIR="$root" pim_build_profile "$profile"
        printf 'built profile: %s\n' "$profile"
        return 0
    fi

    for profile_dir in "$root/pi/profiles"/*; do
        [[ -d "$profile_dir" ]] || continue
        profile="$(basename "$profile_dir")"
        PIM_DOTFILES_DIR="$root" pim_build_profile "$profile"
        printf 'built profile: %s\n' "$profile"
    done
}

cmd_deploy() {
    local profile="${1:-}"

    if [[ -n "$profile" ]]; then
        require_profile "$profile"
        pim_deploy_profile "$profile"
        printf 'deployed profile: %s\n' "$profile"
        return 0
    fi

    pim_deploy_all_profiles
    printf 'deployed profiles\n'
}

main() {
    local command="${1:-}"
    shift || true

    case "$command" in
        list) cmd_list "$@" ;;
        current) cmd_current "$@" ;;
        path) cmd_path "${1:-}" ;;
        use) cmd_use "${1:-}" ;;
        doctor) cmd_doctor "$@" ;;
        create) cmd_create "${1:-}" ;;
        build) cmd_build "${1:-}" ;;
        deploy) cmd_deploy "${1:-}" ;;
        -h|--help|help) usage ;;
        *) usage; exit 2 ;;
    esac
}

main "$@"

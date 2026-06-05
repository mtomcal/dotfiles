#!/usr/bin/env bash

pim_dotfiles_dir() {
    if [[ -n "${PIM_DOTFILES_DIR:-}" ]]; then
        printf '%s\n' "$PIM_DOTFILES_DIR"
    else
        local lib_dir
        lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$lib_dir/../.." && pwd
    fi
}

pim_home_dir() {
    printf '%s\n' "${PIM_HOME:-$HOME}"
}

pim_default_profile() {
    printf '%s\n' "${PIM_DEFAULT_PROFILE:-coding}"
}

pim_validate_profile_name() {
    local profile="$1"
    [[ "$profile" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

pim_profile_source_dir() {
    local root="$1"
    local profile="$2"
    printf '%s/pi/profiles/%s\n' "$root" "$profile"
}

pim_profile_runtime_dir() {
    local home="$1"
    local profile="$2"
    printf '%s/.pi/profiles/%s/agent\n' "$home" "$profile"
}

pim_profile_from_command_name() {
    local command_name="$1"
    local prefix="$2"
    local base
    base="$(basename "$command_name")"
    case "$base" in
        "$prefix"-*) printf '%s\n' "${base#"$prefix"-}" ;;
        *) printf '\n' ;;
    esac
}

pim_current_profile() {
    local home="$1"
    local active_file
    active_file="$(pim_active_profile_file "$home")"
    if [[ -f "$active_file" ]]; then
        sed -n '1p' "$active_file"
    else
        pim_default_profile
    fi
}

pim_resolve_runtime_profile() {
    local home="$1"
    local explicit_profile="${2:-}"
    local profile runtime

    profile="$explicit_profile"
    if [[ -z "$profile" ]]; then
        profile="$(pim_current_profile "$home")"
    fi
    if ! pim_validate_profile_name "$profile"; then
        printf 'pim: invalid profile name: %s\n' "$profile" >&2
        return 1
    fi

    runtime="$(pim_profile_runtime_dir "$home" "$profile")"
    if [[ ! -d "$runtime" ]]; then
        printf 'pim: profile runtime not found: %s\n' "$runtime" >&2
        return 1
    fi

    PIM_RESOLVED_PROFILE="$profile"
    PIM_RESOLVED_RUNTIME="$runtime"
}

pim_active_profile_file() {
    local home="$1"
    printf '%s/.pi/active-profile\n' "$home"
}

pim_active_agent_link() {
    local home="$1"
    printf '%s/.pi/agent\n' "$home"
}

pim_replace_symlink() {
    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"
    if [[ -L "$target" ]]; then
        if [[ "$(readlink "$target")" == "$source" ]]; then
            return 0
        fi
        rm "$target"
    elif [[ -e "$target" ]]; then
        printf 'pim: target exists and is not a symlink: %s\n' "$target" >&2
        return 1
    fi
    ln -s "$source" "$target"
}

pim_prepare_shared_auth() {
    local home="$1"

    mkdir -p "$home/.pi"
    if [[ ! -f "$home/.pi/auth.json" ]]; then
        printf '{}\n' > "$home/.pi/auth.json"
    fi
}

pim_deploy_profile() {
    local profile="$1"
    local root home profile_dir resolved runtime extension required
    root="$(pim_dotfiles_dir)"
    home="$(pim_home_dir)"
    profile_dir="$(pim_profile_source_dir "$root" "$profile")"
    resolved="$profile_dir/resolved"
    runtime="$(pim_profile_runtime_dir "$home" "$profile")"

    if ! pim_validate_profile_name "$profile"; then
        printf 'pim: invalid profile name: %s\n' "$profile" >&2
        return 1
    fi
    if [[ ! -d "$profile_dir" ]]; then
        printf 'pim: profile not found: %s\n' "$profile" >&2
        return 1
    fi
    if [[ ! -d "$resolved" ]]; then
        printf 'pim: profile has no resolved output: %s\n' "$profile" >&2
        return 1
    fi
    for required in settings.json models.json agents skills; do
        if [[ ! -e "$resolved/$required" && ! -L "$resolved/$required" ]]; then
            printf 'pim: resolved output for profile "%s" is missing %s\n' "$profile" "$required" >&2
            return 1
        fi
    done

    pim_prepare_shared_auth "$home"
    mkdir -p "$runtime/extensions" "$runtime/sessions"
    pim_replace_symlink "$resolved/settings.json" "$runtime/settings.json"
    pim_replace_symlink "$resolved/models.json" "$runtime/models.json"
    pim_replace_symlink "$resolved/agents" "$runtime/agents"
    pim_replace_symlink "$resolved/skills" "$runtime/skills"
    pim_replace_symlink "$home/.pi/auth.json" "$runtime/auth.json"

    if [[ -d "$resolved/extensions" ]]; then
        for extension in "$resolved/extensions"/*; do
            [[ -e "$extension" || -L "$extension" ]] || continue
            pim_replace_symlink "$extension" "$runtime/extensions/$(basename "$extension")"
        done
    fi
}

pim_deploy_all_profiles() {
    local root profile_dir profile
    root="$(pim_dotfiles_dir)"
    for profile_dir in "$root/pi/profiles"/*; do
        [[ -d "$profile_dir" ]] || continue
        profile="$(basename "$profile_dir")"
        pim_deploy_profile "$profile"
    done
}

pim_resolve_profile_paths() {
    local profile="$1"
    local root
    root="$(pim_dotfiles_dir)"

    if ! pim_validate_profile_name "$profile"; then
        printf 'pim: invalid profile name: %s\n' "$profile" >&2
        return 1
    fi

    PIM_PROFILE_NAME="$profile"
    PIM_ROOT="$root"
    PIM_BASE_DIR="$root/pi/base"
    PIM_SHARED_SKILLS_DIR="$root/shared/skills"
    PIM_PROFILE_DIR="$(pim_profile_source_dir "$root" "$profile")"
    PIM_RESOLVED_DIR="$PIM_PROFILE_DIR/resolved"
    PIM_EXTENSIONS_DIR="$root/pi/extensions"
}

pim_link_entries() {
    local source_dir="$1"
    local target_dir="$2"

    [[ -d "$source_dir" ]] || return 0
    mkdir -p "$target_dir"

    local entry name
    for entry in "$source_dir"/*; do
        [[ -e "$entry" || -L "$entry" ]] || continue
        name="$(basename "$entry")"
        rm -rf "$target_dir/$name"
        pim_ln_s "$entry" "$target_dir/$name"
    done
}

pim_relative_link_target() {
    local source="$1"
    local link_dir="$2"
    local source_trimmed="${source#/}"
    local link_trimmed="${link_dir#/}"
    local old_ifs="$IFS"
    local -a source_parts link_parts
    local i rel j

    IFS='/'
    read -r -a source_parts <<< "$source_trimmed"
    read -r -a link_parts <<< "$link_trimmed"
    IFS="$old_ifs"

    i=0
    while [[ $i -lt ${#source_parts[@]} && $i -lt ${#link_parts[@]} && "${source_parts[$i]}" == "${link_parts[$i]}" ]]; do
        i=$((i + 1))
    done

    rel=""
    for ((j = i; j < ${#link_parts[@]}; j++)); do
        if [[ -n "${link_parts[$j]}" ]]; then
            rel="${rel}../"
        fi
    done
    for ((j = i; j < ${#source_parts[@]}; j++)); do
        rel="${rel}${source_parts[$j]}"
        if [[ $j -lt $((${#source_parts[@]} - 1)) ]]; then
            rel="${rel}/"
        fi
    done

    printf '%s\n' "${rel:-.}"
}

pim_ln_s() {
    local source="$1"
    local link="$2"
    local link_dir target
    link_dir="$(dirname "$link")"
    target="$(pim_relative_link_target "$source" "$link_dir")"
    ln -s "$target" "$link"
}

pim_select_file() {
    local profile_file="$1"
    local base_file="$2"

    if [[ -f "$profile_file" ]]; then
        printf '%s\n' "$profile_file"
    else
        printf '%s\n' "$base_file"
    fi
}

pim_validate_no_duplicate_profile_skills() {
    local shared_dir="$1"
    local profile_skills_dir="$2"

    [[ -d "$profile_skills_dir" ]] || return 0
    [[ -d "$shared_dir" ]] || return 0

    local skill name
    for skill in "$profile_skills_dir"/*; do
        [[ -d "$skill" || -L "$skill" ]] || continue
        name="$(basename "$skill")"
        if [[ -e "$shared_dir/$name" || -L "$shared_dir/$name" ]]; then
            printf 'pim: profile skill "%s" duplicates shared skill\n' "$name" >&2
            return 1
        fi
    done
}

pim_extensions_list_file() {
    local profile_dir="$1"
    local base_dir="$2"

    if [[ -f "$profile_dir/extensions.list" ]]; then
        printf '%s\n' "$profile_dir/extensions.list"
    elif [[ -f "$base_dir/extensions.list" ]]; then
        printf '%s\n' "$base_dir/extensions.list"
    fi
}

pim_materialize_extensions() {
    local list_file="$1"
    local extensions_source="$2"
    local target_dir="$3"

    mkdir -p "$target_dir"
    [[ -n "$list_file" && -f "$list_file" ]] || return 0

    local extension
    while IFS= read -r extension || [[ -n "$extension" ]]; do
        extension="${extension%%#*}"
        extension="${extension//[[:space:]]/}"
        [[ -n "$extension" ]] || continue
        if [[ ! -d "$extensions_source/$extension" ]]; then
            printf 'pim: extension "%s" not found\n' "$extension" >&2
            return 1
        fi
        pim_ln_s "$extensions_source/$extension" "$target_dir/$extension"
    done < "$list_file"
}

pim_build_profile() {
    local profile="$1"
    pim_resolve_profile_paths "$profile" || return 1

    if [[ ! -d "$PIM_PROFILE_DIR" ]]; then
        printf 'pim: profile not found: %s\n' "$profile" >&2
        return 1
    fi
    if [[ ! -d "$PIM_SHARED_SKILLS_DIR" ]]; then
        printf 'pim: shared skills directory not found: %s\n' "$PIM_SHARED_SKILLS_DIR" >&2
        return 1
    fi

    local profile_skills_dir="$PIM_PROFILE_DIR/skills"
    pim_validate_no_duplicate_profile_skills "$PIM_SHARED_SKILLS_DIR" "$profile_skills_dir" || return 1

    local settings_source models_source
    settings_source="$(pim_select_file "$PIM_PROFILE_DIR/settings.json" "$PIM_BASE_DIR/settings.json")"
    models_source="$(pim_select_file "$PIM_PROFILE_DIR/models.json" "$PIM_BASE_DIR/models.json")"

    [[ -f "$settings_source" ]] || { printf 'pim: settings.json not found for profile %s\n' "$profile" >&2; return 1; }
    [[ -f "$models_source" ]] || { printf 'pim: models.json not found for profile %s\n' "$profile" >&2; return 1; }

    local tmp_resolved
    tmp_resolved="$(mktemp -d "$PIM_PROFILE_DIR/.resolved.tmp.XXXXXX")"

    pim_ln_s "$settings_source" "$tmp_resolved/settings.json"
    pim_ln_s "$models_source" "$tmp_resolved/models.json"
    mkdir -p "$tmp_resolved/agents" "$tmp_resolved/skills" "$tmp_resolved/extensions"

    pim_link_entries "$PIM_BASE_DIR/agents" "$tmp_resolved/agents"
    pim_link_entries "$PIM_PROFILE_DIR/agents" "$tmp_resolved/agents"
    pim_link_entries "$PIM_SHARED_SKILLS_DIR" "$tmp_resolved/skills"
    pim_link_entries "$profile_skills_dir" "$tmp_resolved/skills"

    local extension_list
    extension_list="$(pim_extensions_list_file "$PIM_PROFILE_DIR" "$PIM_BASE_DIR")"
    pim_materialize_extensions "$extension_list" "$PIM_EXTENSIONS_DIR" "$tmp_resolved/extensions" || {
        rm -rf "$tmp_resolved"
        return 1
    }

    rm -rf "$PIM_RESOLVED_DIR"
    mv "$tmp_resolved" "$PIM_RESOLVED_DIR"
}

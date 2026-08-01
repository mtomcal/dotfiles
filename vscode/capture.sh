#!/usr/bin/env bash
#
# Capture the current macOS Visual Studio Code Desktop configuration into this
# repository's managed layer.
#
# This command is explicit-only. It is never invoked by install.sh, it never
# deploys symlinks, and it never installs anything. It writes repository
# sources; deployment writes system targets. They are separate operations.

set -uo pipefail

MODULE_DIR="$(cd "$(dirname "$0")" && pwd)" || {
    printf 'Error: could not resolve the vscode module directory\n' >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: capture.sh [--force]

Capture macOS Visual Studio Code Desktop settings, keybindings, snippets, and
extension identities into ${MODULE_DIR}.

  --force    Replace managed sources that already exist
  --help     Show this message

Capture refuses to replace an existing managed source unless --force is given.
It does not deploy configuration and does not install anything.
EOF
}

print_error() {
    printf 'Error: %s\n' "$*" >&2
}

die() {
    print_error "$*"
    exit 1
}

# --- Managed destinations -----------------------------------------------------

# One declaration of the capture unit, shared by preflight and publication so
# the two can never disagree about what is being written.
#
# Each entry is "kind:relative-destination", where the kind selects how the
# artifact is staged.
CAPTURE_UNIT=(
    'settings:settings.json'
    'keybindings:keybindings.json'
    'snippets:snippets'
    'extensions:extensions/desktop.txt'
)

capture_kind() {
    printf '%s' "${1%%:*}"
}

capture_relative_path() {
    printf '%s' "${1#*:}"
}

# The path reported to the operator: repository-relative where possible.
capture_display_path() {
    printf 'vscode/%s' "$(capture_relative_path "$1")"
}

# --- Validation ---------------------------------------------------------------

FORCE=0

parse_options() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --force)
                FORCE=1
                ;;
            --help | -h)
                usage
                exit 0
                ;;
            *)
                usage >&2
                die "unknown argument: $1"
                ;;
        esac
        shift
    done
}

validate_platform_and_cli() {
    local system
    system="$(uname -s 2>/dev/null || true)"
    if [ "$system" != "Darwin" ]; then
        die "capture requires macOS; this host reports '${system:-unknown}'"
    fi

    if ! command -v code >/dev/null 2>&1; then
        die "capture requires the 'code' command from Visual Studio Code Desktop"
    fi
}

DESKTOP_USER_DIR=""

resolve_desktop_sources() {
    DESKTOP_USER_DIR="$HOME/Library/Application Support/Code/User"

    local missing=""
    [ -f "$DESKTOP_USER_DIR/settings.json" ] || missing="$missing
  $DESKTOP_USER_DIR/settings.json"
    [ -f "$DESKTOP_USER_DIR/keybindings.json" ] || missing="$missing
  $DESKTOP_USER_DIR/keybindings.json"
    [ -d "$DESKTOP_USER_DIR/snippets" ] || missing="$missing
  $DESKTOP_USER_DIR/snippets"

    if [ -n "$missing" ]; then
        die "capture needs the complete desktop configuration; missing:$missing"
    fi
}

# Every destination is inspected before anything is written, so a conflict can
# never be discovered after a partial write.
preflight_destinations() {
    local entry destination conflicts=""

    for entry in "${CAPTURE_UNIT[@]}"; do
        destination="$MODULE_DIR/$(capture_relative_path "$entry")"
        if [ -e "$destination" ] || [ -L "$destination" ]; then
            conflicts="$conflicts
  $(capture_display_path "$entry")"
        fi
    done

    if [ -n "$conflicts" ] && [ "$FORCE" -ne 1 ]; then
        print_error "capture would replace existing managed sources:$conflicts"
        die "rerun with --force to replace them deliberately"
    fi
}

# --- Staging ------------------------------------------------------------------

STAGE_ROOT=""

# Every input is copied into one disposable root first. Nothing reaches a
# managed destination until all of them are staged, so a failure while reading
# the desktop configuration cannot leave a half-written capture behind.
stage_capture() {
    STAGE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/vscode-capture.XXXXXX")" ||
        die "could not create a staging directory"

    local entry kind
    for entry in "${CAPTURE_UNIT[@]}"; do
        kind="$(capture_kind "$entry")"
        case "$kind" in
            settings | keybindings)
                cp "$DESKTOP_USER_DIR/$kind.json" "$STAGE_ROOT/$kind" ||
                    die "could not read $DESKTOP_USER_DIR/$kind.json"
                ;;
            snippets)
                mkdir -p "$STAGE_ROOT/snippets" ||
                    die "could not stage snippets"
                cp -R "$DESKTOP_USER_DIR/snippets/." "$STAGE_ROOT/snippets/" ||
                    die "could not read $DESKTOP_USER_DIR/snippets"
                ;;
            extensions)
                stage_extension_identities "$STAGE_ROOT/extensions" ||
                    die "could not list installed extensions with 'code --list-extensions'"
                ;;
        esac
    done
}

# Captured identities are stored unpinned: an installed version is a property
# of the machine, not of the managed declaration.
stage_extension_identities() {
    local target="$1"
    local listing

    listing="$(code --list-extensions 2>/dev/null)" || return 1

    printf '%s\n' "$listing" |
        awk '{
            sub(/@.*$/, "", $0)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
            if ($0 != "") print
        }' >"$target" || return 1
}

# --- Publication --------------------------------------------------------------

# Publication is two-phase. Phase one copies each staged artifact next to its
# destination; phase two renames it into place within the same directory. Any
# phase-one failure aborts before a single destination has changed, and any
# phase-two failure restores what was already replaced.
PREPARED=()
BACKUPS=()
COMMITTED=()

working_path() {
    local prefix="$1"
    local destination="$2"
    printf '%s/.capture-%s-%s-%s' \
        "$(dirname "$destination")" "$prefix" "$$" "$(basename "$destination")"
}

prepare_capture() {
    local entry kind destination prepared

    for entry in "${CAPTURE_UNIT[@]}"; do
        kind="$(capture_kind "$entry")"
        destination="$MODULE_DIR/$(capture_relative_path "$entry")"
        prepared="$(working_path new "$destination")"

        mkdir -p "$(dirname "$destination")" ||
            die "could not create $(dirname "$(capture_display_path "$entry")")"
        rm -rf "$prepared"
        cp -R "$STAGE_ROOT/$kind" "$prepared" ||
            die "could not prepare $(capture_display_path "$entry")"
        PREPARED[${#PREPARED[@]}]="$prepared"
    done
}

rollback_capture() {
    local index record destination backup

    index=$((${#COMMITTED[@]} - 1))
    while [ "$index" -ge 0 ]; do
        record="${COMMITTED[$index]}"
        destination="${record%%|*}"
        backup="${record#*|}"
        rm -rf "$destination"
        if [ -n "$backup" ]; then
            mv "$backup" "$destination" ||
                print_error "could not restore $destination from $backup"
        fi
        index=$((index - 1))
    done
    COMMITTED=()
}

commit_capture() {
    local index entry destination prepared backup

    index=0
    for entry in "${CAPTURE_UNIT[@]}"; do
        destination="$MODULE_DIR/$(capture_relative_path "$entry")"
        prepared="${PREPARED[$index]}"
        backup=""

        if [ -e "$destination" ] || [ -L "$destination" ]; then
            backup="$(working_path old "$destination")"
            rm -rf "$backup"
            BACKUPS[${#BACKUPS[@]}]="$backup"
            if ! mv "$destination" "$backup"; then
                rollback_capture
                die "could not replace $(capture_display_path "$entry")"
            fi
        fi

        # Recorded before the destination is filled: from here on the original
        # is displaced, so rollback owns restoring it whichever step fails.
        COMMITTED[${#COMMITTED[@]}]="$destination|$backup"

        if ! mv "$prepared" "$destination"; then
            rollback_capture
            die "could not publish $(capture_display_path "$entry")"
        fi

        index=$((index + 1))
    done
}

publish_capture() {
    prepare_capture
    commit_capture
}

# --- Reporting ----------------------------------------------------------------

# A capture is unreviewed machine data until a human reads it. Say so plainly,
# and say it after the work, where it is the last thing on screen.
report_capture() {
    local entry

    printf 'Captured the desktop configuration into %s\n' "$MODULE_DIR"
    for entry in "${CAPTURE_UNIT[@]}"; do
        printf '  %s\n' "$(capture_display_path "$entry")"
    done
    printf '\n'
    printf 'WARNING: this capture is unreviewed machine data.\n'
    printf 'Review every captured file and remove credentials, tokens, secrets,\n'
    printf 'and machine-specific paths before you commit them.\n'
    printf 'Nothing was deployed; run the installer separately to deploy.\n'
}

# --- Cleanup ------------------------------------------------------------------

# Runs on every exit path: success, refusal, failure, and interruption. Staged
# input, prepared artifacts, and displaced originals are all working state and
# never outlive the command.
cleanup() {
    local path

    if [ -n "$STAGE_ROOT" ] && [ -d "$STAGE_ROOT" ]; then
        rm -rf "$STAGE_ROOT"
    fi
    if [ ${#PREPARED[@]} -gt 0 ]; then
        for path in "${PREPARED[@]}"; do
            rm -rf "$path"
        done
    fi
    if [ ${#BACKUPS[@]} -gt 0 ]; then
        for path in "${BACKUPS[@]}"; do
            rm -rf "$path"
        done
    fi
}

main() {
    parse_options "$@"
    validate_platform_and_cli
    resolve_desktop_sources
    preflight_destinations
    stage_capture
    publish_capture
    report_capture
}

trap cleanup EXIT
trap 'cleanup; exit 130' HUP INT TERM

main "$@"

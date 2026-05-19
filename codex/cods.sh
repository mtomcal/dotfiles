#!/bin/bash
# cods — Run Codex --yolo in a sandboxed Docker container
#
# Usage:
#   cods                              # Run codex --yolo in cwd
#   cods "fix the tests"              # Pass prompt/args to codex
#   cods --mount-ro ~/Code/lib        # Mount extra path read-only
#   cods --mount-rw ~/Code/lib        # Mount extra path read-write
#   cods -- --model gpt-5.4           # Pass args after --
#   cods --dry-run                    # Print docker run command
#   cods --no-rebuild                 # Skip auto-rebuild check
#   cods --build                      # Rebuild the Docker image
#
# CWD is always mounted read-write at the same absolute path. ~/.codex is
# mounted read-write, with auth.json overlaid read-only when present.

set -e

IMAGE_NAME="${CODEX_SANDBOX_IMAGE:-cods:latest}"
DOCKERFILE_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$DOCKERFILE_DIR/.." && pwd)"
MEMORY_LIMIT="${CODEX_SANDBOX_MEMORY:-8g}"
CPU_LIMIT="${CODEX_SANDBOX_CPUS:-4}"
PIDS_LIMIT="${CODEX_SANDBOX_PIDS:-512}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

EXTRA_VOLUMES=()
CODEX_ARGS=()
BUILD_ONLY=false
NO_REBUILD=false
DRY_RUN=false
FORWARD_ENV=true
ALLOW_DANGEROUS_MOUNT=false
PARSING_CODS_ARGS=true

usage() {
    cat >&2 <<EOF
Usage: cods [OPTIONS] [-- CODEX_ARGS...]

Options:
  --mount-ro PATH             Mount extra path read-only at the same path
  --mount-rw PATH             Mount extra path read-write at the same path
  --allow-dangerous-mount     Allow high-risk extra mounts
  --no-env-forward            Do not forward API-key-shaped environment vars
  --env NAME                  Forward one explicit environment variable
  --dry-run                   Print the docker run command and exit
  --no-rebuild                Skip Codex version auto-rebuild check
  --build                     Build the Docker image and exit
  --help                      Show this help
EOF
}

abs_path() {
    local path="$1"
    if [[ -d "$path" ]]; then
        (cd "$path" && pwd)
    elif [[ -e "$path" ]]; then
        local dir
        dir="$(cd "$(dirname "$path")" && pwd)"
        printf '%s/%s\n' "$dir" "$(basename "$path")"
    else
        return 1
    fi
}

is_dangerous_mount() {
    local path="$1"
    case "$path" in
        /|"$HOME"|"$HOME/.ssh"|"$HOME/.ssh"/*|/var/run/docker.sock|/run/docker.sock)
            return 0
            ;;
    esac
    return 1
}

add_mount() {
    local mode="$1"
    local source
    source="$(abs_path "$2")" || {
        echo -e "${RED}[cods]${NC} Path not found: $2" >&2
        exit 1
    }

    if [[ "$ALLOW_DANGEROUS_MOUNT" != true ]] && is_dangerous_mount "$source"; then
        echo -e "${RED}[cods]${NC} Refusing high-risk mount: ${source}" >&2
        echo "Use --allow-dangerous-mount only when you explicitly accept the risk." >&2
        exit 1
    fi

    EXTRA_VOLUMES+=("-v" "${source}:${source}:${mode}")
}

EXPLICIT_ENV=()

while [[ $# -gt 0 ]]; do
    if [[ "$PARSING_CODS_ARGS" == true ]]; then
        case "$1" in
            --)
                PARSING_CODS_ARGS=false
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            --build)
                BUILD_ONLY=true
                shift
                ;;
            --no-rebuild)
                NO_REBUILD=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-env-forward)
                FORWARD_ENV=false
                shift
                ;;
            --allow-dangerous-mount)
                ALLOW_DANGEROUS_MOUNT=true
                shift
                ;;
            --env)
                if [[ -z "${2:-}" ]]; then
                    echo -e "${RED}[cods]${NC} --env requires a variable name" >&2
                    exit 1
                fi
                EXPLICIT_ENV+=("$2")
                shift 2
                ;;
            --mount-ro)
                if [[ -z "${2:-}" ]]; then
                    echo -e "${RED}[cods]${NC} --mount-ro requires a path" >&2
                    exit 1
                fi
                add_mount ro "$2"
                shift 2
                ;;
            --mount-rw)
                if [[ -z "${2:-}" ]]; then
                    echo -e "${RED}[cods]${NC} --mount-rw requires a path" >&2
                    exit 1
                fi
                add_mount rw "$2"
                shift 2
                ;;
            -*)
                CODEX_ARGS+=("$1")
                shift
                ;;
            *)
                CODEX_ARGS+=("$1")
                shift
                ;;
        esac
    else
        CODEX_ARGS+=("$1")
        shift
    fi
done

build_image() {
    local codex_ver
    local base_image
    codex_ver="${CODEX_SANDBOX_VERSION:-$(npm view @openai/codex version 2>/dev/null || echo "latest")}"
    base_image="dotfiles-dev-base:$(id -u)-$(id -g)"
    echo -e "${GREEN}[cods]${NC} Ensuring shared sandbox base image ${base_image}..."
    docker build \
        -f "$DOTFILES_DIR/docker/dev-base.Dockerfile" \
        --build-arg HOST_USER="$(whoami)" \
        --build-arg HOST_UID="$(id -u)" \
        --build-arg HOST_GID="$(id -g)" \
        -t "$base_image" "$DOTFILES_DIR"
    echo -e "${GREEN}[cods]${NC} Building Docker image ${IMAGE_NAME} (Codex @${codex_ver})..."
    docker build \
        --build-arg BASE_IMAGE="$base_image" \
        --build-arg CODEX_VERSION="$codex_ver" \
        --build-arg HOST_USER="$(whoami)" \
        --build-arg HOST_GID="$(id -g)" \
        -t "$IMAGE_NAME" "$DOCKERFILE_DIR"
    echo -e "${GREEN}[cods]${NC} Image built successfully"
}

if [[ "$BUILD_ONLY" == true ]]; then
    build_image
    exit 0
fi

if [[ "$DRY_RUN" != true ]]; then
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}[cods]${NC} Docker not found. Install Docker first." >&2
        exit 1
    fi

    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo -e "${YELLOW}[cods]${NC} Image ${IMAGE_NAME} not found, building..."
        build_image
    elif [[ "$NO_REBUILD" != true ]]; then
        image_codex=$(docker image inspect "$IMAGE_NAME" --format '{{ index .Config.Labels "codex.version" }}' 2>/dev/null)
        latest_codex="${CODEX_SANDBOX_VERSION:-$(npm view @openai/codex version 2>/dev/null || true)}"

        if [[ -n "$latest_codex" && ( -z "$image_codex" || "$image_codex" != "$latest_codex" ) ]]; then
            if [[ -z "$image_codex" ]]; then
                echo -e "${YELLOW}[cods]${NC} Codex version label missing in image — rebuilding..."
            else
                echo -e "${YELLOW}[cods]${NC} Codex v${image_codex} in image, v${latest_codex} available — rebuilding..."
            fi
            build_image
        fi
    fi
fi

HOST_CWD="$(pwd)"
CODEX_DIR="$HOME/.codex"
HOST_USER="$(whoami)"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
CONTAINER_HOME="/home/${HOST_USER}"

mkdir -p "$CODEX_DIR"

DOCKER_TTY_ARGS=(-i)
if [[ -t 0 && -t 1 ]]; then
    DOCKER_TTY_ARGS=(-it)
fi

DOCKER_ARGS=(
    --rm
    "${DOCKER_TTY_ARGS[@]}"
    --user "${HOST_UID}:${HOST_GID}"
    --memory "$MEMORY_LIMIT"
    --cpus "$CPU_LIMIT"
    --pids-limit "$PIDS_LIMIT"
    -e HOME="${CONTAINER_HOME}"
    -e TERM=${TERM:-xterm-256color}
    -e LANG=${LANG:-C.UTF-8}
    -e LC_ALL=${LC_ALL:-C.UTF-8}
    -w "$HOST_CWD"
    -v "${HOST_CWD}:${HOST_CWD}:rw"
    -v "${CODEX_DIR}:${CONTAINER_HOME}/.codex:rw"
)

if [[ -f "${CODEX_DIR}/auth.json" ]]; then
    DOCKER_ARGS+=("-v" "${CODEX_DIR}/auth.json:${CONTAINER_HOME}/.codex/auth.json:ro")
fi

DOCKER_ARGS+=("${EXTRA_VOLUMES[@]}")

FORWARDED_ENV=()
add_env_if_set() {
    local name="$1"
    if [[ -n "${!name:-}" ]]; then
        DOCKER_ARGS+=("-e" "$name")
        FORWARDED_ENV+=("$name")
    fi
}

if [[ "$FORWARD_ENV" == true ]]; then
    for VAR in ANTHROPIC_API_KEY OPENAI_API_KEY GOOGLE_API_KEY GEMINI_API_KEY; do
        add_env_if_set "$VAR"
    done

    while IFS='=' read -r key _; do
        case "$key" in
            *API_KEY|*API_TOKEN|*APIKEY)
                case "$key" in
                    ANTHROPIC_API_KEY|OPENAI_API_KEY|GOOGLE_API_KEY|GEMINI_API_KEY) ;;
                    *) add_env_if_set "$key" ;;
                esac
                ;;
        esac
    done < <(env)
fi

for VAR in "${EXPLICIT_ENV[@]}"; do
    add_env_if_set "$VAR"
done

if [[ "$DRY_RUN" == true ]]; then
    printf '%q ' docker run "${DOCKER_ARGS[@]}" "$IMAGE_NAME" codex --yolo "${CODEX_ARGS[@]}"
    printf '\n'
    exit 0
fi

if [[ ${#FORWARDED_ENV[@]} -gt 0 ]]; then
    echo -e "${YELLOW}[cods]${NC} Forwarding env vars: ${FORWARDED_ENV[*]}" >&2
fi

set +e
docker run "${DOCKER_ARGS[@]}" "$IMAGE_NAME" codex --yolo "${CODEX_ARGS[@]}"
status=$?
set -e

if [[ "$status" -eq 137 ]]; then
    echo -e "${YELLOW}[cods]${NC} Container was killed, likely by the memory limit (${MEMORY_LIMIT})." >&2
fi

exit "$status"

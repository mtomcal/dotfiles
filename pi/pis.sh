#!/bin/bash
# pis — Run Pi coding agent in a sandboxed Docker container
#
# Usage:
#   pis                              # Run pi in cwd
#   pis ~/Code/lib                   # Mount extra dir (read-only)
#   pis -rw ~/Code/lib               # Mount extra dir (read-write)
#   pis ~/Code/lib -- --mode print   # Extra dir + pi args
#   pis -- -p "fix the tests"        # Pi args only
#   pis --no-rebuild                 # Skip auto-rebuild check
#   pis --build                      # Rebuild the Docker image
#
# CWD is always mounted read-write. Extra directories are read-only
# unless preceded by -rw. Everything after -- is passed to pi.

set -e

IMAGE_NAME="pis:latest"
DOCKERFILE_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$DOCKERFILE_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ===========================
# Parse arguments
# ===========================

EXTRA_VOLUMES=()
PI_ARGS=()
BUILD_ONLY=false
NO_REBUILD=false
NEXT_RW=false
PARSING_PIS_ARGS=true

while [[ $# -gt 0 ]]; do
    if [[ "$PARSING_PIS_ARGS" == true ]]; then
        case "$1" in
            --)
                PARSING_PIS_ARGS=false
                shift
                ;;
            --build)
                BUILD_ONLY=true
                shift
                ;;
            --no-rebuild)
                NO_REBUILD=true
                shift
                ;;
            -rw)
                NEXT_RW=true
                shift
                ;;
            -*)
                echo -e "${RED}[pis]${NC} Unknown flag: $1" >&2
                echo "Usage: pis [--no-rebuild] [-rw] [extra_dirs...] [-- pi_args...]" >&2
                exit 1
                ;;
            *)
                # Positional arg: extra directory to mount
                DIR="$(cd "$1" 2>/dev/null && pwd)" || {
                    echo -e "${RED}[pis]${NC} Directory not found: $1" >&2
                    exit 1
                }
                if [[ "$NEXT_RW" == true ]]; then
                    EXTRA_VOLUMES+=("-v" "${DIR}:${DIR}:rw")
                    NEXT_RW=false
                else
                    EXTRA_VOLUMES+=("-v" "${DIR}:${DIR}:ro")
                fi
                shift
                ;;
        esac
    else
        PI_ARGS+=("$1")
        shift
    fi
done

# ===========================
# Build image if needed
# ===========================

build_image() {
    # Resolve the exact Pi version from npm so we can pin it in the build.
    # This ensures Docker cache is invalidated when the version changes and
    # the pi.version label matches the installed package.
    local pi_ver
    local base_image
    pi_ver=$(npm view @earendil-works/pi-coding-agent version 2>/dev/null || echo "latest")
    base_image="dotfiles-dev-base:$(id -u)-$(id -g)"
    echo -e "${GREEN}[pis]${NC} Ensuring shared sandbox base image ${base_image}..."
    docker build \
        -f "$DOTFILES_DIR/docker/dev-base.Dockerfile" \
        --build-arg HOST_USER="$(whoami)" \
        --build-arg HOST_UID="$(id -u)" \
        --build-arg HOST_GID="$(id -g)" \
        -t "$base_image" "$DOTFILES_DIR"
    echo -e "${GREEN}[pis]${NC} Building Docker image ${IMAGE_NAME} (Pi @${pi_ver})..."
    docker build \
        --build-arg BASE_IMAGE="$base_image" \
        --build-arg PI_VERSION="$pi_ver" \
        --build-arg HOST_USER="$(whoami)" \
        --build-arg HOST_GID="$(id -g)" \
        -t "$IMAGE_NAME" "$DOCKERFILE_DIR"
    echo -e "${GREEN}[pis]${NC} Image built successfully"
}

if [[ "$BUILD_ONLY" == true ]]; then
    build_image
    exit 0
fi

if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo -e "${YELLOW}[pis]${NC} Image ${IMAGE_NAME} not found, building..."
    build_image
elif [[ "$NO_REBUILD" != true ]]; then
    # Auto-rebuild: compare the Pi version baked into the image against npm latest.
    # The pi.version label is set at build time, so docker image inspect is
    # instant (no container startup needed).
    image_pi=$(docker image inspect "$IMAGE_NAME" --format '{{ index .Config.Labels "pi.version" }}' 2>/dev/null)
    latest_pi=$(npm view @earendil-works/pi-coding-agent version 2>/dev/null)

    if [[ -n "$latest_pi" && ( -z "$image_pi" || "$image_pi" != "$latest_pi" ) ]]; then
        if [[ -z "$image_pi" ]]; then
            echo -e "${YELLOW}[pis]${NC} Pi version label missing in image — rebuilding..."
        else
            echo -e "${YELLOW}[pis]${NC} Pi v${image_pi} in image, v${latest_pi} available — rebuilding..."
        fi
        build_image
    fi
fi

# ===========================
# Prepare mounts
# ===========================

HOST_CWD="$(pwd)"
PI_AGENT_DIR="$HOME/.pi/agent"

HOST_USER="$(whoami)"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
CONTAINER_HOME="/home/${HOST_USER}"

DOCKER_ARGS=(
    --rm
    -it
    --user "${HOST_UID}:${HOST_GID}"
    -e HOME="${CONTAINER_HOME}"
    -w "$HOST_CWD"

    # Locale and terminal — forward from host for emoji and wide char support.
    # The Dockerfile sets LANG/LC_ALL=C.UTF-8 as defaults;
    # forwarding the host TERM ensures tmux can negotiate capabilities
    # with the outer terminal emulator (true color, Unicode, etc.).
    -e TERM=${TERM:-xterm-256color}
    -e LANG=${LANG:-C.UTF-8}
    -e LC_ALL=${LC_ALL:-C.UTF-8}

    # Project directory (read-write)
    -v "${HOST_CWD}:${HOST_CWD}:rw"

    # Pi agent state — mounted under the container user's home directory
    # so files are created with the host user's ownership, not root.
    -v "${PI_AGENT_DIR}/sessions:${CONTAINER_HOME}/.pi/agent/sessions:rw"
    -v "${PI_AGENT_DIR}/auth.json:${CONTAINER_HOME}/.pi/agent/auth.json:ro"
    -v "${PI_AGENT_DIR}/settings.json:${CONTAINER_HOME}/.pi/agent/settings.json:ro"
    -v "${PI_AGENT_DIR}/models.json:${CONTAINER_HOME}/.pi/agent/models.json:ro"
    -v "${PI_AGENT_DIR}/skills:${CONTAINER_HOME}/.pi/agent/skills:ro"
    -v "${PI_AGENT_DIR}/extensions:${CONTAINER_HOME}/.pi/agent/extensions:ro"

    # Tmux configuration
    -v "$HOME/.tmux.conf:${CONTAINER_HOME}/.tmux.conf:ro"
)

# Extra directory mounts
DOCKER_ARGS+=("${EXTRA_VOLUMES[@]}")

# Forward API key env vars that are set
for VAR in ANTHROPIC_API_KEY OPENAI_API_KEY GOOGLE_API_KEY GEMINI_API_KEY; do
    if [[ -n "${!VAR}" ]]; then
        DOCKER_ARGS+=("-e" "$VAR")
    fi
done

# Also forward any other *_API_KEY or *_API_TOKEN env vars
while IFS='=' read -r key _; do
    case "$key" in
        *API_KEY|*API_TOKEN|*APIKEY)
            # Skip if already added above
            case "$key" in
                ANTHROPIC_API_KEY|OPENAI_API_KEY|GOOGLE_API_KEY|GEMINI_API_KEY) ;;
                *) DOCKER_ARGS+=("-e" "$key") ;;
            esac
            ;;
    esac
done < <(env)

# ===========================
# Ensure mount sources exist
# ===========================

mkdir -p "${PI_AGENT_DIR}/sessions"

# Create empty files if they don't exist (Docker would create directories)
for F in auth.json settings.json models.json; do
    if [[ ! -f "${PI_AGENT_DIR}/${F}" ]]; then
        echo -e "${YELLOW}[pis]${NC} Creating empty ${PI_AGENT_DIR}/${F}"
        echo '{}' > "${PI_AGENT_DIR}/${F}"
    fi
done

if [[ ! -d "${PI_AGENT_DIR}/skills" ]]; then
    mkdir -p "${PI_AGENT_DIR}/skills"
fi

# ===========================
# Run
# ===========================

exec docker run "${DOCKER_ARGS[@]}" "$IMAGE_NAME" "${PI_ARGS[@]}"

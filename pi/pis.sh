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
    pi_ver=$(npm view @mariozechner/pi-coding-agent version 2>/dev/null || echo "latest")
    echo -e "${GREEN}[pis]${NC} Building Docker image ${IMAGE_NAME} (Pi @${pi_ver})..."
    docker build --build-arg PI_VERSION="$pi_ver" -t "$IMAGE_NAME" "$DOCKERFILE_DIR"
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
    latest_pi=$(npm view @mariozechner/pi-coding-agent version 2>/dev/null)

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

DOCKER_ARGS=(
    --rm
    -it
    -w "$HOST_CWD"

    # Project directory (read-write)
    -v "${HOST_CWD}:${HOST_CWD}:rw"

    # Pi agent state
    -v "${PI_AGENT_DIR}/sessions:/root/.pi/agent/sessions:rw"
    -v "${PI_AGENT_DIR}/auth.json:/root/.pi/agent/auth.json:ro"
    -v "${PI_AGENT_DIR}/settings.json:/root/.pi/agent/settings.json:ro"
    -v "${PI_AGENT_DIR}/models.json:/root/.pi/agent/models.json:ro"
    -v "${PI_AGENT_DIR}/skills:/root/.pi/agent/skills:ro"
    -v "${PI_AGENT_DIR}/extensions:/root/.pi/agent/extensions:ro"

    # Tmux configuration
    -v "$HOME/.tmux.conf:/root/.tmux.conf:ro"
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

#!/bin/bash
# pis — Run Pi coding agent in a sandboxed Docker container
#
# Usage:
#   pis                              # Run pi in cwd
#   pis ~/Code/lib                   # Mount extra dir (read-only)
#   pis -rw ~/Code/lib               # Mount extra dir (read-write)
#   pis ~/Code/lib -- --mode print   # Extra dir + pi args
#   pis -- -p "fix the tests"        # Pi args only
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
            -rw)
                NEXT_RW=true
                shift
                ;;
            -*)
                echo -e "${RED}[pis]${NC} Unknown flag: $1" >&2
                echo "Usage: pis [-rw] [extra_dirs...] [-- pi_args...]" >&2
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
    echo -e "${GREEN}[pis]${NC} Building Docker image ${IMAGE_NAME}..."
    docker build -t "$IMAGE_NAME" "$DOCKERFILE_DIR"
    echo -e "${GREEN}[pis]${NC} Image built successfully"
}

if [[ "$BUILD_ONLY" == true ]]; then
    build_image
    exit 0
fi

if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo -e "${YELLOW}[pis]${NC} Image ${IMAGE_NAME} not found, building..."
    build_image
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
    -v "${PI_AGENT_DIR}/agents:/root/.pi/agent/agents:ro"
    -v "${PI_AGENT_DIR}/prompts:/root/.pi/agent/prompts:ro"
    -v "${PI_AGENT_DIR}/extensions:/root/.pi/agent/extensions:ro"
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

# Pi Coding Agent — Sandboxed Development Environment
# Build: docker build -t pis:latest ~/dotfiles/pi/
# Used by: pis (pi-sandbox wrapper script)

FROM ubuntu:24.04

# Pin the Pi version so Docker cache is invalidated when the version changes.
# Default to 'latest' for manual builds; the pis wrapper script resolves
# the exact version and passes --build-arg PI_VERSION=<x.y.z>.
ARG PI_VERSION=latest

# Host user args — the pis wrapper script passes these at build time so
# the container has a matching user with a real /etc/passwd entry.
# This ensures git, ssh, and other tools that need a username work inside
# the container, and files written to mounted volumes are owned by the
# host user (not root).
ARG HOST_USER=mtomcal
ARG HOST_UID=1000
ARG HOST_GID=1000

# Resolve the user's home directory for use in ENV and RUN instructions.
# Docker ENV can reference ARGs defined in the same build stage.
ENV USER_HOME="/home/${HOST_USER}"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Write locale defaults into /etc/environment so login shells and SSH
# sessions also pick up UTF-8, not just the Docker ENV layer.
RUN echo "LANG=C.UTF-8" >> /etc/environment \
    && echo "LC_ALL=C.UTF-8" >> /etc/environment

# Use Arizona mirror instead of default Ubuntu repos (faster, avoids
# security.ubuntu.com hangs on some networks).
# Step 1: switch to HTTP (ca-certificates not yet installed), install certs,
# then upgrade to HTTPS.
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirror.arizona.edu/ubuntu/|g; s|http://security.ubuntu.com/ubuntu/|http://mirror.arizona.edu/ubuntu/|g; s|http://ports.ubuntu.com/ubuntu-ports/|http://mirror.arizona.edu/ubuntu-ports/|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update && apt-get install -y ca-certificates \
    && sed -i 's|http://mirror.arizona.edu/|https://mirror.arizona.edu/|g' /etc/apt/sources.list.d/ubuntu.sources \
    && rm -rf /var/lib/apt/lists/*

# Base dev tools + locale support
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    jq \
    tmux \
    zsh \
    ripgrep \
    fd-find \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    unzip \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate UTF-8 locale (en_US.UTF-8 as the full locale, C.UTF-8 as fallback)
# Both are needed: some programs (e.g. Python) specifically look for
# en_US.UTF-8, while C.UTF-8 is always available as a minimal locale.
RUN sed -i '/en_US\.UTF-8/s/^# //g' /etc/locale.gen && locale-gen en_US.UTF-8

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/

# Go 1.24+ (system-wide install to /usr/local/go)
ARG GO_VERSION=1.24.2
RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" \
      | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# fd-find is installed as fdfind on Debian; alias it
RUN ln -sf "$(which fdfind)" /usr/local/bin/fd

# ===========================
# Create the host user early so all tooling installs under their home
# ===========================
# Remove the default 'ubuntu' user/group first (ubuntu:24.04 creates
# ubuntu:1000:1000) to avoid GID/UID conflicts when the host user is 1000.
RUN userdel -r ubuntu 2>/dev/null; \
    groupdel ubuntu 2>/dev/null; \
    groupadd -g ${HOST_GID} ${HOST_USER} && \
    useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/zsh ${HOST_USER} && \
    mkdir -p ${USER_HOME}/.local/share ${USER_HOME}/.pi/agent ${USER_HOME}/go-workspace && \
    chown -R ${HOST_USER}:${HOST_USER} ${USER_HOME}

# Go workspace (user-local)
ENV GOPATH="${USER_HOME}/go-workspace"
ENV PATH="${GOPATH}/bin:${PATH}"

# fnm + Node.js LTS + Pi coding agent
# Installed under the user's home directory so the non-root container user
# has full access. Combined into one RUN so fnm's PATH is available for
# npm install. Files are chowned to the host user afterwards.
ENV FNM_DIR="${USER_HOME}/.local/share/fnm"
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "${FNM_DIR}" --skip-shell \
    && export PATH="${FNM_DIR}:${PATH}" \
    && eval "$(fnm env --shell bash)" \
    && fnm install --lts \
    && fnm default lts-latest \
    && npm install -g @mariozechner/pi-coding-agent@${PI_VERSION} \
    && chown -R ${HOST_USER}:${HOST_USER} ${USER_HOME}

# Resolve node binary path for subsequent layers and runtime.
# fnm aliases/default/ IS the node installation root (contains bin/, lib/).
# Docker ENV can't follow symlinks, so create a stable /usr/local/node link.
RUN ln -sf "${FNM_DIR}/aliases/default" /usr/local/node
ENV PATH="/usr/local/node/bin:${FNM_DIR}:${PATH}"

# Default working directory (overridden by pis script)
# Stamp the resolved Pi version into the image metadata so the pis wrapper
# can compare it against the latest npm release without starting a container.
LABEL pi.version="${PI_VERSION}"

WORKDIR /workspace

# Entrypoint: start pi inside tmux so the tmux orchestration skill
# can spawn additional Pi agents in separate panes/windows.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
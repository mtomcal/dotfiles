# Pi Coding Agent — Sandboxed Development Environment
# Build: docker build -t pis:latest ~/dotfiles/pi/
# Used by: pis (pi-sandbox wrapper script)

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Base dev tools
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
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Go 1.24+
ARG GO_VERSION=1.24.2
RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" \
      | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/root/go-workspace"
ENV PATH="${GOPATH}/bin:${PATH}"

# fnm + Node.js LTS
ENV FNM_DIR="/root/.local/share/fnm"
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "${FNM_DIR}" --skip-shell
ENV PATH="${FNM_DIR}:${PATH}"
RUN eval "$(${FNM_DIR}/fnm env --shell bash)" \
    && fnm install --lts \
    && fnm default lts-latest
# Ensure fnm shims are on PATH for all subsequent RUN and runtime
SHELL ["/bin/bash", "-c"]
ENV PATH="/root/.local/share/fnm/aliases/lts-latest/installation/bin:${PATH}"

# Pi coding agent
RUN npm install -g @mariozechner/pi-coding-agent@latest

# fd-find is installed as fdfind on Debian; alias it
RUN ln -sf "$(which fdfind)" /usr/local/bin/fd

# Default working directory (overridden by pis script)
WORKDIR /workspace

ENTRYPOINT ["pi"]

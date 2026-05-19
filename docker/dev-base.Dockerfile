# Dotfiles shared sandbox base image
# Build: docker build -f docker/dev-base.Dockerfile -t dotfiles-dev-base:1000-1000 .

FROM ubuntu:24.04

ARG HOST_USER=mtomcal
ARG HOST_UID=1000
ARG HOST_GID=1000
ARG GO_VERSION=1.24.2

ENV USER_HOME="/home/${HOST_USER}"
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN echo "LANG=C.UTF-8" >> /etc/environment \
    && echo "LC_ALL=C.UTF-8" >> /etc/environment

RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then \
        sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirror.arizona.edu/ubuntu/|g; s|http://security.ubuntu.com/ubuntu/|http://mirror.arizona.edu/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources; \
    fi \
    && apt-get update && apt-get install -y ca-certificates \
    && if [ "$ARCH" = "amd64" ]; then \
        sed -i 's|http://mirror.arizona.edu/|https://mirror.arizona.edu/|g' /etc/apt/sources.list.d/ubuntu.sources; \
    fi \
    && rm -rf /var/lib/apt/lists/*

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
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US\.UTF-8/s/^# //g' /etc/locale.gen && locale-gen en_US.UTF-8

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/

RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" \
      | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd

RUN userdel -r ubuntu 2>/dev/null; \
    groupdel ubuntu 2>/dev/null; \
    if ! getent group ${HOST_GID} >/dev/null; then \
        groupadd -g ${HOST_GID} ${HOST_USER}; \
    fi && \
    useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/zsh ${HOST_USER} && \
    mkdir -p ${USER_HOME}/.local/share ${USER_HOME}/go-workspace && \
    chown -R ${HOST_USER}:${HOST_GID} ${USER_HOME}

ENV GOPATH="${USER_HOME}/go-workspace"
ENV PATH="${GOPATH}/bin:${PATH}"
ENV FNM_DIR="${USER_HOME}/.local/share/fnm"

RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "${FNM_DIR}" --skip-shell \
    && export PATH="${FNM_DIR}:${PATH}" \
    && eval "$(fnm env --shell bash)" \
    && fnm install --lts \
    && fnm default lts-latest \
    && chown -R ${HOST_USER}:${HOST_GID} ${USER_HOME} \
    && echo "Installed Node on ${ARCH} ($(node -e 'console.log(process.arch)'))"

RUN ln -sf "${FNM_DIR}/aliases/default" /usr/local/node
ENV PATH="/usr/local/node/bin:${FNM_DIR}:${PATH}"

WORKDIR /workspace

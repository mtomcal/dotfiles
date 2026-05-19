# Codex CLI — Sandboxed Development Environment
# Build: docker build --build-arg BASE_IMAGE=dotfiles-dev-base:1000-1000 -t cods:latest ~/dotfiles/codex/
# Used by: cods (Codex sandbox wrapper script)

ARG BASE_IMAGE=dotfiles-dev-base:1000-1000
FROM ${BASE_IMAGE}

ARG CODEX_VERSION=latest
ARG HOST_USER=mtomcal

RUN mkdir -p ${USER_HOME}/.codex \
    && npm install -g @openai/codex@${CODEX_VERSION} \
    && chown -R ${HOST_USER}:${HOST_USER} ${USER_HOME} \
    && echo "Installed Codex ($(node -e 'console.log(process.arch)'))"

LABEL codex.version="${CODEX_VERSION}"

CMD ["codex"]

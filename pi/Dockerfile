# Pi Coding Agent — Sandboxed Development Environment
# Build: docker build --build-arg BASE_IMAGE=dotfiles-dev-base:1000-1000 -t pis:latest ~/dotfiles/pi/
# Used by: pis (pi-sandbox wrapper script)

ARG BASE_IMAGE=dotfiles-dev-base:1000-1000
FROM ${BASE_IMAGE}

ARG PI_VERSION=latest
ARG HOST_USER=mtomcal
ARG HOST_GID=1000

RUN mkdir -p ${USER_HOME}/.pi/agent \
    && npm install -g @earendil-works/pi-coding-agent@${PI_VERSION} \
    && chown -R ${HOST_USER}:${HOST_GID} ${USER_HOME} \
    && echo "Installed Pi ($(node -e 'console.log(process.arch)'))"

LABEL pi.version="${PI_VERSION}"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

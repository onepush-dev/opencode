# OpenCode for Railway: the official upstream image plus the tools a browser-based
# coding agent needs (git for repos and OpenCode's undo snapshots, bash, ssh, node, python).
# The upstream image (alpine) ships only the opencode binary + ripgrep.
ARG OPENCODE_IMAGE=ghcr.io/anomalyco/opencode:1.19.3@sha256:6ebc13097f2381301220abe9d1b2a54f50cd1603a910dc1c66e93d8f2c4e8ebb
FROM ${OPENCODE_IMAGE}

RUN apk add --no-cache \
      bash git git-lfs openssh-client curl ca-certificates tzdata tini jq less \
      nodejs npm python3 py3-pip \
  && git lfs install --system --skip-repo \
  && opencode --version

# Everything stateful lives under /data (mount the Railway volume there):
#   /data/home/.config/opencode       global config (opencode.json, agents, commands)
#   /data/home/.local/share/opencode  provider logins (auth.json), sessions DB, snapshots
#   /data/home/.local/state, .cache   UI state, installed LSPs/plugins
#   /data/home/.gitconfig, .ssh       git identity and keys
#   /data/workspace                   your projects (default working directory)
ENV HOME=/data/home \
    OPENCODE_WORKSPACE=/data/workspace \
    SHELL=/bin/bash \
    OPENCODE_DISABLE_AUTOUPDATE=true \
    BUN_RUNTIME_TRANSPILER_CACHE_PATH=0

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0755 /usr/local/bin/railway-entrypoint.sh

WORKDIR /data/workspace
EXPOSE 4096
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/railway-entrypoint.sh"]
CMD []

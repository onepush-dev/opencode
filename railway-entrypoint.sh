#!/bin/sh
# Starts `opencode serve` (API + embedded web UI) on 0.0.0.0:$PORT behind HTTP basic auth.
# Any arguments are passed straight to the opencode CLI instead (e.g. `opencode run ...`).
set -eu

HOME="${HOME:-/data/home}"
OPENCODE_WORKSPACE="${OPENCODE_WORKSPACE:-/data/workspace}"
export HOME OPENCODE_WORKSPACE

mkdir -p "$HOME/.config/opencode" "$HOME/.local/share/opencode" "$HOME/.local/state" "$HOME/.cache" "$OPENCODE_WORKSPACE"

# Sensible git defaults on first boot; never overwrite what the user set.
git config --global --get init.defaultBranch >/dev/null 2>&1 || git config --global init.defaultBranch main
git config --global --get user.name  >/dev/null 2>&1 || git config --global user.name  "${GIT_USER_NAME:-OpenCode}"
git config --global --get user.email >/dev/null 2>&1 || git config --global user.email "${GIT_USER_EMAIL:-opencode@localhost}"

if [ "$#" -gt 0 ]; then
  cd "$OPENCODE_WORKSPACE"
  exec opencode "$@"
fi

# Never expose an unauthenticated agent (it can run shell commands) to the internet.
if [ -z "${OPENCODE_SERVER_PASSWORD:-}" ] && [ "${OPENCODE_ALLOW_NO_PASSWORD:-false}" != "true" ]; then
  echo "railway-entrypoint: OPENCODE_SERVER_PASSWORD is empty; refusing to start an open server." >&2
  echo "railway-entrypoint: set OPENCODE_SERVER_PASSWORD (or OPENCODE_ALLOW_NO_PASSWORD=true on a private network)." >&2
  exit 1
fi

cd "$OPENCODE_WORKSPACE"
echo "railway-entrypoint: opencode $(opencode --version) serving ${OPENCODE_WORKSPACE} on ${OPENCODE_HOSTNAME:-0.0.0.0}:${PORT:-4096} (user ${OPENCODE_SERVER_USERNAME:-opencode})"
exec opencode serve --hostname "${OPENCODE_HOSTNAME:-0.0.0.0}" --port "${PORT:-4096}"

#!/usr/bin/env bash
# Amigoscode Academy - every course in this repo, in one terminal app.
# Docker is the only thing you need installed.
#
#   ./academy.sh            macOS, Linux, WSL, Git Bash, GitHub Codespaces
#   academy.cmd             Windows (PowerShell or Command Prompt)
#
# The first run builds a small image (about a minute). After that it starts instantly,
# and it rebuilds itself only when the academy's code changes.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="amigoscode/academy:local"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Install Docker Desktop (Mac/Windows) or Docker Engine (Linux):"
  echo "  https://docs.docker.com/get-docker/"
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed but not running. Start Docker and run ./academy.sh again."
  exit 1
fi

# Rebuild only when the academy source changes (the fingerprint is an image label).
HASH="$(cd "$HERE/academy" && cat go.mod go.sum Dockerfile ./*.go | cksum | awk '{print $1}')"
CURRENT="$(docker image inspect -f '{{ index .Config.Labels "academy.hash" }}' "$IMAGE" 2>/dev/null || true)"
if [ "$CURRENT" != "$HASH" ]; then
  echo "Building the Amigoscode Academy (first run only, about a minute)..."
  if ! docker build -q --label "academy.hash=$HASH" -t "$IMAGE" "$HERE/academy" >/dev/null; then
    echo "Could not build the academy. Check that Docker is running and you are online."
    exit 1
  fi
fi

# The repo is mounted at the same path it has on your machine, so every path the
# exercises hand to Docker (bind mounts, compose files) means the same thing inside
# and outside the container.
args=(--rm -i
  -v /var/run/docker.sock:/var/run/docker.sock
  -v "$HERE:$HERE" -w "$HERE"
  -e "ACADEMY_REPO=$HERE"
  -e "TERM=${TERM:-xterm-256color}"
  -e "COLORTERM=${COLORTERM:-truecolor}"
  --add-host host.docker.internal:host-gateway)

[ -t 0 ] && [ -t 1 ] && args+=(-t)

# On Linux (and Codespaces) run as you, so files the academy writes stay yours.
if [ "$(uname -s)" = "Linux" ]; then
  SOCK_GID="$(stat -c %g /var/run/docker.sock 2>/dev/null || echo 0)"
  args+=(--user "$(id -u):$(id -g)" --group-add "$SOCK_GID" -e HOME=/tmp)
fi

exec docker run "${args[@]}" "$IMAGE" "$@"

#!/usr/bin/env bash
# Runs on the HOST. Starts a misbehaving container to debug.
set -uo pipefail

docker pull -q alpine >/dev/null 2>&1 || true

if ! docker inspect buggy >/dev/null 2>&1; then
  docker run -d --name buggy \
    --label version=1.2.3 \
    -e APP_ENV=production \
    alpine sh -c 'echo "starting up"; echo "ERROR: config value missing"; while true; do echo heartbeat; sleep 5; done' \
    >/dev/null
fi

echo "Seeded: container 'buggy' is running (and misbehaving)."

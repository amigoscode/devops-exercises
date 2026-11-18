#!/usr/bin/env bash
# Runs on the HOST against your real Docker daemon.
# Pulls the images this section uses and leaves two containers running to manage.
set -uo pipefail

docker pull -q nginx:alpine     >/dev/null 2>&1 || true
docker pull -q amigoscode/2048  >/dev/null 2>&1 || true

# A container to practise 'docker stop' on.
docker inspect scratch >/dev/null 2>&1 || docker run -d --name scratch nginx:alpine >/dev/null
# An abandoned container for the Tier 3 clean-up.
docker inspect old-web >/dev/null 2>&1 || docker run -d --name old-web nginx:alpine >/dev/null

echo "Seeded: images pulled; containers 'scratch' and 'old-web' are running."

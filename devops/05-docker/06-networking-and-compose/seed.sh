#!/usr/bin/env bash
# Runs on the HOST. Pulls the images the stack uses. You create the network,
# the containers and the compose file yourself.
set -uo pipefail

docker pull -q nginx:alpine >/dev/null 2>&1 || true
docker pull -q redis:alpine >/dev/null 2>&1 || true

echo "Seeded: nginx:alpine and redis:alpine ready."
echo "Create the network + containers, then write docker-compose.yml in this section's sandbox."

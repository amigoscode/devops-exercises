#!/usr/bin/env bash
# Tears down the whole stack: containers, network, the dbdata volume and built images.
if [ -n "${SB:-}" ] && [ -f "$SB/docker-compose.yml" ]; then
  docker compose -f "$SB/docker-compose.yml" down -v --rmi local >/dev/null 2>&1 || true
fi
docker rmi -f api:1 >/dev/null 2>&1 || true

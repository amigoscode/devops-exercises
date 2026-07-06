#!/usr/bin/env bash
# Tears the whole system down: containers, network, both volumes and built images.
if [ -n "${SB:-}" ] && [ -f "$SB/docker-compose.yml" ]; then
  docker compose -f "$SB/docker-compose.yml" down -v --rmi local >/dev/null 2>&1 || true
fi
docker rmi -f users:1 orders:1 >/dev/null 2>&1 || true

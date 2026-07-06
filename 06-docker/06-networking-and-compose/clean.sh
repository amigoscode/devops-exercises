#!/usr/bin/env bash
# Removes this section's containers, network, compose stack and its volume.
if [ -n "${SB:-}" ] && [ -f "$SB/docker-compose.yml" ]; then
  docker compose -f "$SB/docker-compose.yml" down -v >/dev/null 2>&1 || true
fi
docker rm -f store api      >/dev/null 2>&1 || true
docker network rm appnet    >/dev/null 2>&1 || true

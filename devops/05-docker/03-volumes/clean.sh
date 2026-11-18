#!/usr/bin/env bash
# Removes only this section's containers and named volume.
docker rm -f bindweb keeper >/dev/null 2>&1 || true
docker volume rm appdata     >/dev/null 2>&1 || true

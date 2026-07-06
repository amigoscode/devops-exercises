#!/usr/bin/env bash
# Removes only this section's containers and built images.
docker rm -f site clock       >/dev/null 2>&1 || true
docker rmi -f static-site:1 clock:1 >/dev/null 2>&1 || true

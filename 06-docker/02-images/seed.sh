#!/usr/bin/env bash
# Runs on the HOST. Ensures the tag source exists and plants a stray 'latest' tag.
set -uo pipefail

docker pull -q nginx:alpine >/dev/null 2>&1 || true
# A risky floating tag for the Tier 3 clean-up.
docker tag nginx:alpine dashboard:latest >/dev/null 2>&1 || true

echo "Seeded: nginx:alpine available; stray 'dashboard:latest' tag planted."

#!/usr/bin/env bash
# Runs on the HOST. Grades the Containers exercises against the real Docker daemon.
set -uo pipefail
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
running(){ docker ps    --format '{{.Names}}' | grep -qx "$1"; }
exists(){  docker ps -a --format '{{.Names}}' | grep -qx "$1"; }
# host port $2 is published to container port 80 of container $1
pubport(){ docker port "$1" 80 2>/dev/null | grep -q ":$2$"; }

echo "Tier 1 - Run your first container"
if running web && pubport web 8080; then
  ok "1.1 'web' is running and publishes host 8080 -> container 80"
else
  no "1.1 run nginx:alpine detached, named 'web', mapping 8080:80"
fi

echo "Tier 2 - Name it, background it, manage it"
if running game && pubport game 8081; then
  ok "2.1 'game' (amigoscode/2048) is running on host 8081 -> container 80"
else
  no "2.1 run amigoscode/2048 detached, named 'game', mapping 8081:80"
fi
if exists scratch && ! running scratch; then
  ok "2.2 'scratch' is stopped (still exists, not running)"
else
  no "2.2 stop the 'scratch' container without removing it (docker stop scratch)"
fi

echo "Tier 3 - Clean up the box"
if ! exists old-web; then
  ok "3.1 the abandoned 'old-web' container is gone"
else
  no "3.1 remove the running 'old-web' container completely (docker rm -f old-web)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can run, name, expose, stop and remove containers."
exit 0

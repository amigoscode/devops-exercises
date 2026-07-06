#!/usr/bin/env bash
# Runs on the HOST. Grades the Networking & Compose exercises.
set -uo pipefail
: "${SB:?SB not set}"
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
running(){ docker ps --format '{{.Names}}' | grep -qx "$1"; }
onnet(){ docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$1" 2>/dev/null | grep -qw "$2"; }
resolves(){ docker exec "$1" getent hosts "$2" >/dev/null 2>&1; }
pubport(){ docker port "$1" 80 2>/dev/null | grep -q ":$2$"; }

echo "Tier 1 - A network for your containers"
if docker network inspect appnet >/dev/null 2>&1; then ok "1.1 user-defined network 'appnet' exists"
else no "1.1 create the network 'appnet' (docker network create appnet)"; fi

echo "Tier 2 - Make containers talk by name"
if running store && onnet store appnet; then ok "2.1 'store' (redis:alpine) is running on appnet"
else no "2.1 run redis:alpine as 'store' attached to appnet (--network appnet)"; fi
if running api && onnet api appnet && pubport api 8082 && resolves api store; then
  ok "2.2 'api' is on appnet, published on 8082, and reaches 'store' by name"
else
  no "2.2 run nginx:alpine as 'api' on appnet, -p 8082:80; it must resolve 'store' by name"
fi

echo "Tier 3 - Let Compose run the whole stack"
svc="$(docker compose -f "$SB/docker-compose.yml" ps --services --status running 2>/dev/null || true)"
if echo "$svc" | grep -qx web && echo "$svc" | grep -qx cache; then
  ok "3.1 Compose stack is up: 'web' and 'cache' services running"
else
  no "3.1 write docker-compose.yml (services web + cache) and 'docker compose up -d'"
fi
vol_ok=false; docker volume ls --format '{{.Name}}' | grep -q 'cachedata' && vol_ok=true
if docker ps --format '{{.Ports}}' | grep -q '8083->80/tcp' && $vol_ok; then
  ok "3.2 'web' is published on 8083 and the 'cachedata' volume was created"
else
  no "3.2 publish web on 8083:80 and mount a named volume 'cachedata' into cache"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can connect containers by name and run a stack with Compose."
exit 0

#!/usr/bin/env bash
# Runs on the HOST. Grades the Images exercises against the real Docker daemon.
set -uo pipefail
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
img(){ docker image inspect "$1" >/dev/null 2>&1; }
same(){ [ -n "$(docker image inspect -f '{{.Id}}' "$1" 2>/dev/null)" ] && \
        [ "$(docker image inspect -f '{{.Id}}' "$1" 2>/dev/null)" = "$(docker image inspect -f '{{.Id}}' "$2" 2>/dev/null)" ]; }

echo "Tier 1 - Pull and inspect"
if img httpd:alpine; then ok "1.1 'httpd:alpine' pulled locally"
else no "1.1 pull the httpd:alpine image (docker pull httpd:alpine)"; fi

echo "Tier 2 - Tag your own versions"
if img dashboard:1 && same dashboard:1 nginx:alpine; then
  ok "2.1 'dashboard:1' tags nginx:alpine"
else
  no "2.1 tag nginx:alpine as dashboard:1 (docker tag nginx:alpine dashboard:1)"
fi
if img dashboard:2 && same dashboard:2 nginx:alpine; then
  ok "2.2 'dashboard:2' tags nginx:alpine"
else
  no "2.2 tag nginx:alpine as dashboard:2 as well"
fi

echo "Tier 3 - Make it production-safe"
if img busybox:1.36; then ok "3.1 pinned 'busybox:1.36' pulled locally"
else no "3.1 pull the pinned version busybox:1.36 (not latest)"; fi
if ! img dashboard:latest && img dashboard:1 && img dashboard:2; then
  ok "3.2 stray 'dashboard:latest' removed; pinned versions kept"
else
  no "3.2 remove only the dashboard:latest tag (docker rmi dashboard:latest), keep 1 and 2"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can pull, pin, tag and version images."
exit 0

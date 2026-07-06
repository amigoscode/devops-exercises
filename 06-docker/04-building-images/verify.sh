#!/usr/bin/env bash
# Runs on the HOST. Grades the Building Images exercises against the real Docker daemon.
set -uo pipefail
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
img(){ docker image inspect "$1" >/dev/null 2>&1; }
running(){ docker ps --format '{{.Names}}' | grep -qx "$1"; }
pubport(){ docker port "$1" 80 2>/dev/null | grep -q ":$2$"; }

echo "Tier 1 - Your first Dockerfile"
baked="$(docker run --rm static-site:1 cat /usr/share/nginx/html/index.html 2>/dev/null || true)"
if img static-site:1 && echo "$baked" | grep -q 'Amigoscode'; then
  ok "1.1 'static-site:1' built with the site COPYed into the web root"
else
  no "1.1 write a Dockerfile (FROM nginx:alpine, COPY . into the web root) and build static-site:1"
fi
if running site && pubport site 8082; then
  ok "1.2 'site' is running from static-site:1 on host 8082 -> 80"
else
  no "1.2 run a container named 'site' from static-site:1, mapping 8082:80"
fi

echo "Tier 2 - An image with a build step"
if img clock:1; then ok "2.1 'clock:1' image built"
else no "2.1 write clock/Dockerfile (FROM python:3-alpine, WORKDIR, COPY, RUN, CMD) and build clock:1"; fi
if running clock && docker logs clock 2>&1 | grep -q 'clock service starting'; then
  ok "2.2 'clock' is running and its logs show it started"
else
  no "2.2 run clock:1 detached as 'clock'; docker logs clock should show it starting"
fi

echo "Tier 3 - Production-grade image"
listing="$(docker run --rm clock:1 sh -c 'ls -a /src 2>/dev/null || ls -a' 2>/dev/null || true)"
if img clock:1 && echo "$listing" | grep -q 'app.py' && ! echo "$listing" | grep -q 'secret.txt'; then
  ok "3.1 secret.txt is excluded from the image (.dockerignore), app.py still present"
else
  no "3.1 add a .dockerignore so secret.txt/notes.md are not copied, then rebuild clock:1"
fi
who="$(docker run --rm clock:1 whoami 2>/dev/null || true)"
if [ -n "$who" ] && [ "$who" != root ]; then
  ok "3.2 clock:1 runs as a non-root user ('$who')"
else
  no "3.2 make clock:1 run as a non-root user (add a USER instruction), then rebuild"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can build small, secret-free, non-root images from a Dockerfile."
exit 0

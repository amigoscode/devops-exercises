#!/usr/bin/env bash
# Runs on the HOST. Grades the Volumes exercises against the real Docker daemon.
set -uo pipefail
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
running(){ docker ps --format '{{.Names}}' | grep -qx "$1"; }

echo "Tier 1 - Bind mount a folder"
bind_ok=false
if running bindweb; then
  # a bind-type mount landing on the nginx web root
  mounts="$(docker inspect -f '{{range .Mounts}}{{.Type}}|{{.Source}}|{{.Destination}} {{end}}' bindweb 2>/dev/null)"
  content="$(docker exec bindweb cat /usr/share/nginx/html/index.html 2>/dev/null || true)"
  if echo "$mounts" | grep -q 'bind|.*sandbox/03-volumes/site|/usr/share/nginx/html' \
     && echo "$content" | grep -q 'bind-mounted'; then bind_ok=true; fi
fi
$bind_ok && ok "1.1 'bindweb' serves the site via a bind mount on the web root" \
         || no "1.1 run nginx:alpine as 'bindweb', -p 8080:80, bind-mount site/ to /usr/share/nginx/html"

echo "Tier 2 - Named volumes"
if docker volume inspect appdata >/dev/null 2>&1; then ok "2.1 named volume 'appdata' exists"
else no "2.1 create the named volume 'appdata' (docker volume create appdata)"; fi
if running keeper && docker inspect -f '{{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}' keeper 2>/dev/null | grep -q 'appdata:/data'; then
  ok "2.2 'keeper' is running with 'appdata' mounted at /data"
else
  no "2.2 run nginx:alpine as 'keeper' mounting appdata at /data (-v appdata:/data)"
fi

echo "Tier 3 - Prove your data survives"
persisted="$(docker run --rm -v appdata:/data nginx:alpine cat /data/persisted.txt 2>/dev/null || true)"
if echo "$persisted" | grep -q 'survived'; then
  ok "3.1 /data/persisted.txt lives in the 'appdata' volume (survives any container)"
else
  no "3.1 write 'survived' to /data/persisted.txt inside the appdata volume"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can bind-mount folders and persist data with named volumes."
exit 0

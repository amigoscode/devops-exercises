#!/usr/bin/env bash
# Runs on the HOST. Creates a small website to bind-mount, and pulls the base image.
set -uo pipefail
: "${SB:?SB not set}"

docker pull -q nginx:alpine >/dev/null 2>&1 || true

mkdir -p "$SB/site"
if [ ! -f "$SB/site/index.html" ]; then
  cat > "$SB/site/index.html" <<'HTML'
<!doctype html>
<html>
  <head><title>Amigoscode</title></head>
  <body>
    <h1>Served from a bind-mounted folder</h1>
    <p>Edit this file on your host and reload - no rebuild needed.</p>
  </body>
</html>
HTML
fi

echo "Seeded: website at 06-docker/sandbox/03-volumes/site/index.html; nginx:alpine ready."

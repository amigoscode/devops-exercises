#!/usr/bin/env bash
# Runs on the HOST. Lays down two starter apps (no Dockerfiles - you write those).
set -uo pipefail
: "${SB:?SB not set}"

docker pull -q nginx:alpine    >/dev/null 2>&1 || true
docker pull -q python:3-alpine >/dev/null 2>&1 || true

mkdir -p "$SB/site" "$SB/clock"

if [ ! -f "$SB/site/index.html" ]; then
  cat > "$SB/site/index.html" <<'HTML'
<!doctype html>
<html>
  <head><title>Amigoscode</title></head>
  <body><h1>Amigoscode dashboard - baked into the image</h1></body>
</html>
HTML
fi

if [ ! -f "$SB/clock/app.py" ]; then
  cat > "$SB/clock/app.py" <<'PY'
import time

print("clock service starting", flush=True)
while True:
    print("tick", flush=True)
    time.sleep(1)
PY
fi

# Junk/secret that must NOT end up in the image (Tier 3).
[ -f "$SB/clock/secret.txt" ] || echo "SUPER_SECRET_TOKEN=do-not-ship-me" > "$SB/clock/secret.txt"
[ -f "$SB/clock/notes.md" ]   || echo "# scratch notes, not for the image" > "$SB/clock/notes.md"

echo "Seeded: site/ and clock/ starter apps. Add the Dockerfiles yourself."

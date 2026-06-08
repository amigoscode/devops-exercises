#!/usr/bin/env bash
# Runs INSIDE the container. Sets up ~/sandbox + a LOCAL web service so curl/ss
# exercises work fully offline.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB"

echo 'hello over http' > "$SB/hello.txt"
cat > "$SB/services.json" <<'EOF'
{ "service": { "name": "checkout-api", "version": "2.3.1" },
  "endpoints": [ { "url": "https://api.example.com/pay" } ] }
EOF

# Start a local HTTP server on port 8000 serving the sandbox (the "service"
# you'll curl). Survives across sessions.
pkill -f 'http.server 8000' 2>/dev/null || true
cd "$SB"
nohup python3 -m http.server 8000 >/dev/null 2>&1 & disown
sleep 1

echo "Sandbox ready. A local service is running at http://localhost:8000"

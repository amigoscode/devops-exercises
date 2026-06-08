#!/usr/bin/env bash
# Runs INSIDE the container. Builds a fresh ~/sandbox + a "runaway" process.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB/data"

# Some data so `du` has something to measure.
for i in 1 2 3; do head -c 20000 /dev/zero > "$SB/data/blob$i.bin" 2>/dev/null || true; done

# A JSON service descriptor for the jq exercises.
cat > "$SB/services.json" <<'EOF'
{
  "service": { "name": "checkout-api", "version": "2.3.1" },
  "replicas": 3,
  "endpoints": [
    { "path": "/health", "url": "https://api.example.com/health" },
    { "path": "/pay",    "url": "https://api.example.com/pay" },
    { "path": "/refund", "url": "https://api.example.com/refund" }
  ]
}
EOF

# A "runaway" process hogging the box - you'll find and kill it in Tier 2.
pkill -x sleep 2>/dev/null || true
nohup sleep 99999 >/dev/null 2>&1 & disown

echo "Sandbox ready. There's a runaway 'sleep' process running - find it and note its PID."

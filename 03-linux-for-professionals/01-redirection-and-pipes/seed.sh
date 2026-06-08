#!/usr/bin/env bash
# Runs INSIDE the container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB/logs"

# A web access log to filter (Tier 2)
cat > "$SB/access.log" <<'EOF'
GET / 200
GET /home 200
POST /login 200
GET /admin 403
GET /missing 404
ERROR upstream timeout
GET /api 500
ERROR db connection lost
EOF

# A names file to sort (Tier 2)
printf 'charlie\nalice\nbob\nalice\n' > "$SB/names.txt"

# A folder of logs for the Tier 3 find/pipeline challenge
printf 'INFO ok\nERROR disk full\nINFO retry\n'        > "$SB/logs/app.log"
printf 'INFO start\nERROR timeout\nERROR timeout\n'    > "$SB/logs/db.log"
printf 'INFO healthy\n'                                > "$SB/logs/web.log"

echo "Sandbox ready at ~/sandbox  (access.log, names.txt, logs/)"

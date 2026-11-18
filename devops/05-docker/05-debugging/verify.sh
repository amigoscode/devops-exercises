#!/usr/bin/env bash
# Runs on the HOST. Grades the Debugging exercises.
set -uo pipefail
: "${SB:?SB not set}"
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
running(){ docker ps --format '{{.Names}}' | grep -qx "$1"; }

echo "Tier 1 - Read the logs"
if [ -f "$SB/error.txt" ] && grep -q 'ERROR' "$SB/error.txt"; then
  ok "1.1 the ERROR log line was captured to error.txt"
else
  no "1.1 save the ERROR line from 'docker logs buggy' to sandbox/05-debugging/error.txt"
fi

echo "Tier 2 - Get inside a running container"
if [ -f "$SB/env.txt" ] && grep -q 'APP_ENV=production' "$SB/env.txt"; then
  ok "2.1 APP_ENV captured from inside the container to env.txt"
else
  no "2.1 use 'docker exec buggy env' and save the APP_ENV line to sandbox/05-debugging/env.txt"
fi
if running buggy && docker exec buggy test -f /tmp/fixed >/dev/null 2>&1; then
  ok "2.2 /tmp/fixed exists inside the running 'buggy' container"
else
  no "2.2 create /tmp/fixed inside the container (docker exec buggy touch /tmp/fixed)"
fi

echo "Tier 3 - Inspect the low-level config"
if [ -f "$SB/version.txt" ] && grep -q '1.2.3' "$SB/version.txt"; then
  ok "3.1 the 'version' label (1.2.3) was pulled with docker inspect"
else
  no "3.1 inspect the container's 'version' label and save it to sandbox/05-debugging/version.txt"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can debug a container with logs, exec and inspect."
exit 0

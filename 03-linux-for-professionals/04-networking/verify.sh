#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Networking exercises (offline-gradable parts).
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=04-networking' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }

echo "Tier 1 - Inspect open sockets"
if [[ -f "$SB/sockets.txt" ]] && grep -q ':8000' "$SB/sockets.txt"; then
  ok "1.1 listed open sockets with ss (saw the service on :8000)"
else
  no "1.1 ss -a > ~/sandbox/sockets.txt (the local service should appear on :8000)"
fi

echo "Tier 2 - Talk to a service with curl"
if [[ -f "$SB/fetched.txt" ]] && grep -q 'hello over http' "$SB/fetched.txt"; then
  ok "2.1 downloaded a file with curl -o"
else
  no "2.1 curl -s http://localhost:8000/hello.txt -o ~/sandbox/fetched.txt"
fi
if [[ -f "$SB/headers.txt" ]] && grep -q '200' "$SB/headers.txt"; then
  ok "2.2 fetched response headers with curl -I (HTTP 200)"
else
  no "2.2 curl -sI http://localhost:8000/ > ~/sandbox/headers.txt"
fi

echo "Tier 3 - curl + jq (the real API workflow)"
if [[ -f "$SB/svc.txt" ]] && grep -qx 'checkout-api' "$SB/svc.txt"; then
  ok "3.1 curled the JSON endpoint and parsed it with jq"
else
  no "3.1 curl -s http://localhost:8000/services.json | jq -r '.service.name' > ~/sandbox/svc.txt"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can inspect the network and talk to services from the command line."
echo
echo "ℹ️  Live-internet drills (not graded - need real network/privileges): see README."

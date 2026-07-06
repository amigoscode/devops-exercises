#!/usr/bin/env bash
# OPTIONAL self-check for the Smart Lead capstone.
#
# This does NOT start anything and is NOT your official grade - a human reviews your
# design. It just probes a stack you have already brought up, the way a reviewer would,
# so you can catch problems before you submit.
#
# Usage:
#   1. Bring your stack up:   docker compose up --build -d
#   2. From your project root: bash self-check.sh
#
# Override the base URL if your API is not on http://localhost:8080
#   BASE_URL=http://localhost:9000 bash self-check.sh
set -uo pipefail
BASE="${BASE_URL:-http://localhost:8080}"

pass=0; fail=0
ok(){ printf '  \033[32m✅ %s\033[0m\n' "$1"; pass=$((pass+1)); }
no(){ printf '  \033[31m❌ %s\033[0m\n' "$1"; fail=$((fail+1)); }
info(){ printf '  .. %s\n' "$1"; }

command -v curl >/dev/null 2>&1 || { echo "curl is required to run this self-check."; exit 2; }

echo "Probing $BASE"

# 1. API is reachable at all (wait up to ~90s for a cold start / build).
echo "1) API reachable"
up=false
for _ in $(seq 1 45); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/v1/messages" 2>/dev/null || true)"
  [ "$code" = "200" ] && { up=true; break; }
  info "waiting for the app to answer on $BASE ... (got '$code')"
  sleep 2
done
$up && ok "GET /api/v1/messages returns 200 (app + database are up)" \
    || { no "the app never answered 200 on $BASE/api/v1/messages"; echo; echo "Score: $pass ok, $fail failed."; exit 1; }

# 2. Submit a message.
echo "2) Submit a message"
post="$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/api/v1/messages" \
        -H 'Content-Type: application/json' \
        -d '{"content":"How much does the pro plan cost?"}' 2>/dev/null || true)"
if [ "$post" = "200" ] || [ "$post" = "201" ]; then
  ok "POST /api/v1/messages accepted (HTTP $post)"
else
  no "POST /api/v1/messages did not succeed (HTTP $post)"
fi

# 3. A lead should appear (async: message -> queue -> analyzer -> lead in DB).
echo "3) End-to-end: a lead gets created"
got=false
for _ in $(seq 1 45); do
  body="$(curl -s "$BASE/api/v1/leads" 2>/dev/null || true)"
  # look for at least one lead object in the response
  if echo "$body" | grep -qE '"id"[[:space:]]*:[[:space:]]*[0-9]+'; then got=true; break; fi
  info "no lead yet, waiting for async processing ..."
  sleep 2
done
$got && ok "GET /api/v1/leads shows a lead (message flowed through the queue + analyzer)" \
     || no "no lead appeared - check the queue exists, the listener runs, and the AI stub is on"

echo
echo "Score: $pass passed, $fail failed."
if [ "$fail" -eq 0 ]; then
  echo "🎉 An outsider can bring your stack up and get a lead end to end. Now polish it against RUBRIC.md and submit."
else
  echo "Not ready yet. Fix the ❌ items above, then run this again."
  exit 1
fi

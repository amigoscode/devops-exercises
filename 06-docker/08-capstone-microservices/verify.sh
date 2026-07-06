#!/usr/bin/env bash
# Runs on the HOST. Grades the Microservices Capstone against the real Docker daemon.
set -uo pipefail
: "${SB:?SB not set}"
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }
CF="$SB/docker-compose.yml"

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
img(){ docker image inspect "$1" >/dev/null 2>&1; }

echo "Tier 1 - Containerize both services"
img users:1  && ok "1.1 users-service image 'users:1' built"   || no "1.1 write users-service/Dockerfile and build it as users:1"
img orders:1 && ok "1.2 orders-service image 'orders:1' built" || no "1.2 write orders-service/Dockerfile and build it as orders:1"

echo "Tier 2 - Compose the whole system"
run=""
[ -f "$CF" ] && run="$(docker compose -f "$CF" ps --services --status running 2>/dev/null || true)"
allup=true
for s in users-db orders-db users-service orders-service web; do
  echo "$run" | grep -qx "$s" || allup=false
done
$allup && ok "2.1 all five services are running (web, users-service, orders-service, users-db, orders-db)" \
       || no "2.1 write docker-compose.yml with all five services and 'docker compose up -d'"
vols="$(docker volume ls --format '{{.Name}}')"
if echo "$vols" | grep -q 'usersdata' && echo "$vols" | grep -q 'ordersdata'; then
  ok "2.2 each database has its own named volume (usersdata + ordersdata)"
else
  no "2.2 give users-db and orders-db their own named volumes (usersdata, ordersdata)"
fi

echo "Tier 3 - Prove the whole system works"
users_json=""; orders_json=""
if [ -f "$CF" ]; then
  for _ in $(seq 1 12); do
    users_json="$(docker compose -f "$CF" exec -T web wget -qO- http://127.0.0.1/api/users 2>/dev/null || true)"
    orders_json="$(docker compose -f "$CF" exec -T web wget -qO- http://127.0.0.1/api/orders 2>/dev/null || true)"
    echo "$orders_json" | grep -q 'Alice' && break
    sleep 2
  done
fi
if echo "$users_json" | grep -q 'Alice' && echo "$users_json" | grep -q 'Bob'; then
  ok "3.1 UI lists users (web -> users-service -> users-db)"
else
  no "3.1 bring the stack up so localhost:8080 lists the users"
fi
if echo "$orders_json" | grep -q 'Keyboard' \
   && echo "$orders_json" | grep -q 'Alice' && echo "$orders_json" | grep -q 'Bob' \
   && ! echo "$orders_json" | grep -q 'unknown'; then
  ok "3.2 orders show buyer names resolved via service-to-service call (full mesh works)"
else
  no "3.2 orders must show the buyer's name (orders-service calls users-service); not 'unknown'"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You built and orchestrated a real microservices system: 2 services, 2 databases, 1 UI."
exit 0

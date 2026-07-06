#!/usr/bin/env bash
# Runs on the HOST. Grades the Full-Stack Capstone against the real Docker daemon.
set -uo pipefail
: "${SB:?SB not set}"
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }
CF="$SB/docker-compose.yml"

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
svc_running(){ docker compose -f "$CF" ps --services --status running 2>/dev/null; }

echo "Tier 1 - Containerize the backend"
if docker image inspect api:1 >/dev/null 2>&1; then
  ok "1.1 backend image 'api:1' built"
else
  no "1.1 write backend/Dockerfile and build it as api:1 (docker build -t api:1 ./sandbox/07-capstone/backend)"
fi

echo "Tier 2 - Compose the stack"
if [ -f "$CF" ]; then
  run="$(svc_running)"
  if echo "$run" | grep -qx db && echo "$run" | grep -qx api && echo "$run" | grep -qx web; then
    ok "2.1 all three services (db, api, web) are running"
  else
    no "2.1 write docker-compose.yml (db + api + web) and 'docker compose up -d'"
  fi
else
  no "2.1 create sandbox/07-capstone/docker-compose.yml, then 'docker compose up -d'"
fi
if docker volume ls --format '{{.Name}}' | grep -q 'dbdata'; then
  ok "2.2 Postgres data is kept in the named volume 'dbdata'"
else
  no "2.2 give db a named volume 'dbdata' mounted at /var/lib/postgresql/data"
fi

echo "Tier 3 - Prove the whole chain works"
# Hit the UI (nginx) which proxies to the API which queries Postgres. Use 127.0.0.1
# (busybox wget resolves localhost to IPv6). Retry: the api may still be connecting.
chain=""
if [ -f "$CF" ]; then
  for _ in $(seq 1 10); do
    chain="$(docker compose -f "$CF" exec -T web wget -qO- http://127.0.0.1/api/messages 2>/dev/null || true)"
    echo "$chain" | grep -q 'Hello from Postgres' && break
    sleep 2
  done
fi
if echo "$chain" | grep -q 'Hello from Postgres'; then
  ok "3.1 end to end works: UI -> API -> Postgres returns the seeded message"
else
  no "3.1 bring the stack up so localhost:8080 shows a message read from Postgres"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You containerized a backend and shipped a real UI + API + Postgres stack."
exit 0

#!/usr/bin/env bash
# Runs on the HOST. Lays down a microservices app: two services, each with its own
# Postgres database, and a UI that talks to both. YOU write the two service
# Dockerfiles and the docker-compose.yml that wires the whole system together.
set -uo pipefail
: "${SB:?SB not set}"

docker pull -q postgres:16-alpine >/dev/null 2>&1 || true
docker pull -q python:3-slim      >/dev/null 2>&1 || true
docker pull -q nginx:alpine       >/dev/null 2>&1 || true

mkdir -p "$SB/users-service" "$SB/orders-service" "$SB/frontend"

# ---- users-service: owns the users database ---------------------------------
if [ ! -f "$SB/users-service/app.py" ]; then
  cat > "$SB/users-service/app.py" <<'PY'
# users-service: reads DB_* from the environment, owns the "users" database,
# and serves /api/users (list) and /api/users/<id> (one user).
import os, time, json
import psycopg2
from http.server import BaseHTTPRequestHandler, HTTPServer

DB = dict(
    host=os.environ.get("DB_HOST", "users-db"),
    dbname=os.environ.get("DB_NAME", "users"),
    user=os.environ.get("DB_USER", "app"),
    password=os.environ.get("DB_PASSWORD", "secret"),
)

def connect():
    for _ in range(30):
        try:
            return psycopg2.connect(**DB)
        except Exception as e:
            print("users waiting for db...", e, flush=True)
            time.sleep(1)
    raise SystemExit("users-service: could not connect to its database")

conn = connect()
with conn, conn.cursor() as cur:
    cur.execute("CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)")
    cur.execute("SELECT count(*) FROM users")
    if cur.fetchone()[0] == 0:
        cur.execute("INSERT INTO users (name) VALUES ('Alice'), ('Bob')")

class Handler(BaseHTTPRequestHandler):
    def _send(self, code, payload):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())

    def do_GET(self):
        if self.path.startswith("/api/health"):
            self._send(200, {"status": "ok"})
        elif self.path.startswith("/api/users/"):
            uid = self.path.rsplit("/", 1)[-1]
            with conn, conn.cursor() as cur:
                cur.execute("SELECT id, name FROM users WHERE id = %s", (uid,))
                row = cur.fetchone()
            if row:
                self._send(200, {"id": row[0], "name": row[1]})
            else:
                self._send(404, {"error": "not found"})
        elif self.path.startswith("/api/users"):
            with conn, conn.cursor() as cur:
                cur.execute("SELECT id, name FROM users ORDER BY id")
                rows = [{"id": r[0], "name": r[1]} for r in cur.fetchall()]
            self._send(200, rows)
        else:
            self._send(404, {"error": "not found"})

    def log_message(self, *args):
        pass

print("users-service listening on 5000", flush=True)
HTTPServer(("0.0.0.0", 5000), Handler).serve_forever()
PY
fi
echo "psycopg2-binary" > "$SB/users-service/requirements.txt"

# ---- orders-service: owns the orders database, and CALLS users-service -------
if [ ! -f "$SB/orders-service/app.py" ]; then
  cat > "$SB/orders-service/app.py" <<'PY'
# orders-service: owns the "orders" database. To label each order with the buyer's
# name it calls the OTHER service (users-service) over the network, by name.
import os, time, json, urllib.request
import psycopg2
from http.server import BaseHTTPRequestHandler, HTTPServer

DB = dict(
    host=os.environ.get("DB_HOST", "orders-db"),
    dbname=os.environ.get("DB_NAME", "orders"),
    user=os.environ.get("DB_USER", "app"),
    password=os.environ.get("DB_PASSWORD", "secret"),
)
USERS_URL = os.environ.get("USERS_URL", "http://users-service:5000")

def connect():
    for _ in range(30):
        try:
            return psycopg2.connect(**DB)
        except Exception as e:
            print("orders waiting for db...", e, flush=True)
            time.sleep(1)
    raise SystemExit("orders-service: could not connect to its database")

conn = connect()
with conn, conn.cursor() as cur:
    cur.execute("CREATE TABLE IF NOT EXISTS orders (id SERIAL PRIMARY KEY, user_id INT NOT NULL, item TEXT NOT NULL)")
    cur.execute("SELECT count(*) FROM orders")
    if cur.fetchone()[0] == 0:
        cur.execute("INSERT INTO orders (user_id, item) VALUES (1, 'Keyboard'), (2, 'Mouse')")

def user_name(uid):
    # Service-to-service call: ask users-service who this user is.
    for _ in range(10):
        try:
            with urllib.request.urlopen(f"{USERS_URL}/api/users/{uid}", timeout=3) as r:
                return json.loads(r.read()).get("name", "unknown")
        except Exception as e:
            print("calling users-service failed, retrying...", e, flush=True)
            time.sleep(1)
    return "unknown"

class Handler(BaseHTTPRequestHandler):
    def _send(self, code, payload):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())

    def do_GET(self):
        if self.path.startswith("/api/health"):
            self._send(200, {"status": "ok"})
        elif self.path.startswith("/api/orders"):
            with conn, conn.cursor() as cur:
                cur.execute("SELECT id, user_id, item FROM orders ORDER BY id")
                rows = cur.fetchall()
            out = [
                {"id": o[0], "item": o[2], "user_id": o[1], "user_name": user_name(o[1])}
                for o in rows
            ]
            self._send(200, out)
        else:
            self._send(404, {"error": "not found"})

    def log_message(self, *args):
        pass

print("orders-service listening on 5000", flush=True)
HTTPServer(("0.0.0.0", 5000), Handler).serve_forever()
PY
fi
echo "psycopg2-binary" > "$SB/orders-service/requirements.txt"

# ---- frontend: one UI that shows data from BOTH services --------------------
if [ ! -f "$SB/frontend/index.html" ]; then
  cat > "$SB/frontend/index.html" <<'HTML'
<!doctype html>
<html>
  <head><title>Amigoscode - Microservices on Docker</title></head>
  <body>
    <h1>Users</h1>
    <ul id="users"><li>loading...</li></ul>
    <h1>Orders</h1>
    <ul id="orders"><li>loading...</li></ul>
    <script>
      fetch('/api/users').then(r => r.json()).then(us => {
        document.getElementById('users').innerHTML =
          us.map(u => '<li>#' + u.id + ' ' + u.name + '</li>').join('');
      });
      fetch('/api/orders').then(r => r.json()).then(os => {
        document.getElementById('orders').innerHTML =
          os.map(o => '<li>' + o.item + ' (ordered by ' + o.user_name + ')</li>').join('');
      });
    </script>
  </body>
</html>
HTML
fi

# nginx serves the UI and routes each API path to the right service.
cat > "$SB/frontend/nginx.conf" <<'CONF'
server {
  listen 80;
  location /api/users  { proxy_pass http://users-service:5000; }
  location /api/orders { proxy_pass http://orders-service:5000; }
  location /           { root /usr/share/nginx/html; index index.html; }
}
CONF

# The frontend image is done for you - use it as the model for the two services.
cat > "$SB/frontend/Dockerfile" <<'DF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
DF

echo "Seeded a microservices app in sandbox/08-capstone-microservices/:"
echo "  users-service/   app.py + requirements.txt   (you add the Dockerfile)"
echo "  orders-service/  app.py + requirements.txt   (you add the Dockerfile)"
echo "  frontend/        index.html + nginx.conf + Dockerfile  (done for you)"
echo "You write: users-service/Dockerfile, orders-service/Dockerfile, docker-compose.yml"

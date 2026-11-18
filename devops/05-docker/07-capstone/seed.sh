#!/usr/bin/env bash
# Runs on the HOST. Lays down a small full-stack app: a static UI, a Python API,
# and the config to talk to Postgres. YOU write the backend Dockerfile and the
# docker-compose.yml that wires the three services together.
set -uo pipefail
: "${SB:?SB not set}"

docker pull -q postgres:16-alpine >/dev/null 2>&1 || true
docker pull -q python:3-slim      >/dev/null 2>&1 || true
docker pull -q nginx:alpine       >/dev/null 2>&1 || true

mkdir -p "$SB/backend" "$SB/frontend"

# ---- Backend: a tiny API that reads/writes a Postgres table -------------------
if [ ! -f "$SB/backend/app.py" ]; then
  cat > "$SB/backend/app.py" <<'PY'
# A tiny HTTP API backed by Postgres. It reads its DB connection from environment
# variables (DB_HOST, DB_NAME, DB_USER, DB_PASSWORD), retries until the database is
# reachable, seeds one row, and serves JSON at /api/health and /api/messages.
import os, time, json
import psycopg2
from http.server import BaseHTTPRequestHandler, HTTPServer

DB = dict(
    host=os.environ.get("DB_HOST", "db"),
    dbname=os.environ.get("DB_NAME", "appdb"),
    user=os.environ.get("DB_USER", "app"),
    password=os.environ.get("DB_PASSWORD", "secret"),
)

def connect():
    for _ in range(30):
        try:
            return psycopg2.connect(**DB)
        except Exception as e:
            print("waiting for db...", e, flush=True)
            time.sleep(1)
    raise SystemExit("could not connect to the database")

conn = connect()
with conn, conn.cursor() as cur:
    cur.execute("CREATE TABLE IF NOT EXISTS messages (id SERIAL PRIMARY KEY, body TEXT NOT NULL)")
    cur.execute("SELECT count(*) FROM messages")
    if cur.fetchone()[0] == 0:
        cur.execute("INSERT INTO messages (body) VALUES (%s)", ("Hello from Postgres",))

class Handler(BaseHTTPRequestHandler):
    def _send(self, code, payload):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())

    def do_GET(self):
        if self.path.startswith("/api/health"):
            self._send(200, {"status": "ok"})
        elif self.path.startswith("/api/messages"):
            with conn, conn.cursor() as cur:
                cur.execute("SELECT id, body FROM messages ORDER BY id")
                rows = [{"id": r[0], "body": r[1]} for r in cur.fetchall()]
            self._send(200, rows)
        else:
            self._send(404, {"error": "not found"})

    def log_message(self, *args):
        pass

print("api listening on 5000", flush=True)
HTTPServer(("0.0.0.0", 5000), Handler).serve_forever()
PY
fi

echo "psycopg2-binary" > "$SB/backend/requirements.txt"

# ---- Frontend: a static page that calls the API (image already set up) --------
if [ ! -f "$SB/frontend/index.html" ]; then
  cat > "$SB/frontend/index.html" <<'HTML'
<!doctype html>
<html>
  <head><title>Amigoscode - Full Stack on Docker</title></head>
  <body>
    <h1>Messages from Postgres</h1>
    <ul id="list"><li>loading...</li></ul>
    <script>
      fetch('/api/messages')
        .then(r => r.json())
        .then(rows => {
          document.getElementById('list').innerHTML =
            rows.map(r => '<li>' + r.body + '</li>').join('');
        });
    </script>
  </body>
</html>
HTML
fi

# nginx serves the page and proxies /api/ to the backend service named "api".
cat > "$SB/frontend/nginx.conf" <<'CONF'
server {
  listen 80;
  location /api/ { proxy_pass http://api:5000/api/; }
  location /     { root /usr/share/nginx/html; index index.html; }
}
CONF

# The frontend image is done for you - study it, it is the pattern for the backend.
cat > "$SB/frontend/Dockerfile" <<'DF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
DF

echo "Seeded a full-stack app in sandbox/07-capstone/:"
echo "  backend/   app.py + requirements.txt   (you add the Dockerfile)"
echo "  frontend/  index.html + nginx.conf + Dockerfile (done for you)"
echo "You write: backend/Dockerfile and docker-compose.yml"

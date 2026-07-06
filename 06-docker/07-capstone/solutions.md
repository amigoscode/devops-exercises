# Solutions - Full-Stack Capstone

## Tier 1 - backend/Dockerfile
```dockerfile
FROM python:3-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
```
Build it:
```bash
docker build -t api:1 ./sandbox/07-capstone/backend
```

## Tier 2 - docker-compose.yml
Create `sandbox/07-capstone/docker-compose.yml`:
```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
    volumes:
      - dbdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 3s
      timeout: 3s
      retries: 10

  api:
    build: ./backend
    image: api:1
    environment:
      DB_HOST: db
      DB_NAME: appdb
      DB_USER: app
      DB_PASSWORD: secret
    depends_on:
      db:
        condition: service_healthy

  web:
    build: ./frontend
    ports:
      - "8080:80"
    depends_on:
      - api

volumes:
  dbdata:
```
Bring it up (run from the folder that has the compose file):
```bash
cd sandbox/07-capstone
docker compose up -d --build
docker compose ps
```

## Tier 3 - prove it and persist it
```bash
curl localhost:8080/api/messages     # [{"id":1,"body":"Hello from Postgres"}]
curl localhost:8080                   # the UI page (it fetches the message)

# Persistence: data lives in the dbdata volume, not the container.
docker compose down          # stops + removes containers/network, KEEPS the volume
docker compose up -d         # data is still there
docker compose down -v       # this time also delete the volume -> next up reseeds
```

The `db` healthcheck + `depends_on: { condition: service_healthy }` (already in the
compose above) make `api` wait until Postgres is actually accepting connections, so it
does not crash-loop on startup.

### Answers
1. `DB_HOST=db` resolves to the `db` container's IP via Compose's built-in DNS on the
   project network - services reach each other by their **service name**.
2. Config that changes per environment (dev/staging/prod) must not be baked into the
   image. Env vars let the same image run anywhere with different credentials, and keep
   secrets out of the code.
3. The container's filesystem is disposable; a named volume is separate storage.
   `docker compose down` removes containers but keeps the volume (data survives);
   `docker compose down -v` also removes the volume (data is wiped).
4. Plain `depends_on` only waits for the container to **start**, not for Postgres to be
   **ready to accept connections**. A healthcheck condition makes `api` wait for the DB
   to actually be up, avoiding startup crashes.
5. Only `web` publishes a port (`8080:80`), so only it is reachable from your browser.
   `api` and `db` have no published ports - they are reachable only from inside the
   Compose network, by service name.

# 07 - Capstone: Full-Stack App on Docker

> Pulls together **Sections 6, 10 & 11**: building images, container networking, and
> Docker Compose - the way a real service is actually shipped.

This is the payoff. You will stand up a real three-tier stack:

```
  browser ->  web (nginx UI)  ->  api (Python backend)  ->  db (Postgres)
                 :8080              service name "api"        named volume
```

The **UI** is served by nginx and proxies API calls to the backend. The **backend**
reads and writes a Postgres table. The **database** keeps its data in a named volume
so it survives restarts. You will containerize the backend and wire all three
together with Docker Compose - exactly the shape of most production apps.

The app code is written for you. Your job is the **Docker** work: build the backend
image, and compose the stack.

## How to use this set

```bash
# from the 06-docker/ folder or the repo root   (on Windows: course.cmd ...)
./course.sh start  07-capstone
#   ...write the Dockerfile + compose file, bring the stack up, then:
./course.sh verify 07-capstone
./course.sh reset  07-capstone      # tears the stack down and re-seeds the starter files

# or from inside this folder, section name left out:
#   ../course.sh verify
```

The seed drops a full-stack app under `06-docker/sandbox/07-capstone/`:

```
backend/   app.py, requirements.txt        <- you add the Dockerfile
frontend/  index.html, nginx.conf, Dockerfile  (done for you - use it as a model)
```

The backend expects its database connection from environment variables:
`DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.

---

## Tier 1 - Containerize the backend *(hint: `FROM python:3-slim`, install `requirements.txt`, then `CMD` to run `app.py`)*

**1.1 (graded)** Write `backend/Dockerfile` so it: bases off `python:3-slim`, sets a
working directory, installs the Python dependencies from `requirements.txt`, copies the
app in, and runs `app.py`. Build it and tag it `api:1`:
```bash
docker build -t api:1 ./sandbox/07-capstone/backend
```
(The provided `frontend/Dockerfile` is the same pattern, simpler - copy the idea.)

## Tier 2 - Compose the stack *(hint: three services - `db`, `api`, `web` - plus a named volume)*

**2.1 (graded)** Write `sandbox/07-capstone/docker-compose.yml` with three services:
- **`db`** - image `postgres:16-alpine`; set `POSTGRES_DB=appdb`, `POSTGRES_USER=app`,
  `POSTGRES_PASSWORD=secret`; store its data in a **named volume** `dbdata` mounted at
  `/var/lib/postgresql/data`.
- **`api`** - build from `./backend`, tagged `image: api:1`; pass the `DB_*` env vars so
  it points at the `db` service (`DB_HOST=db`, and the matching name/user/password).
- **`web`** - build from `./frontend`; publish host port **8080** to **80**.

Then bring the whole stack up in the background with a single command.

**2.2 (graded)** The database's data must live in the **named volume** `dbdata`, not
inside the container - so it survives the container being recreated.

## Tier 3 - Prove the whole chain works *(goal only)*

> **Scenario:** ship day. A request from the browser has to travel UI -> API -> DB and
> come back with real data, or you have not actually shipped anything.

**3.1 (graded)** With the stack up, `http://localhost:8080` shows a message that
**came out of Postgres** (the UI calls the API, which queries the database). Make the
full chain work end to end.

**3.2 (drill)** Prove persistence: `docker compose down` (without `-v`), then
`docker compose up -d` again. The data is still there, because it lives in the
`dbdata` volume. (Run `down -v` to wipe the volume too and start clean.)

**3.3 (drill)** Make startup robust: add a **healthcheck** to `db` (using
`pg_isready`) and `depends_on: { db: { condition: service_healthy } }` to `api`, so the
API waits for Postgres to be ready instead of crashing on boot. See `solutions.md`.

When it is all green you have containerized a backend and orchestrated a real
multi-service app with a database - the single most useful thing Docker does for a
DevOps engineer.

---

## Self-check questions

1. How does the `api` service find the `db` service - what is `DB_HOST=db` actually
   resolving to?
2. Why pass the database credentials as environment variables instead of hard-coding
   them in `app.py`?
3. Why store Postgres data in a named volume? What happens on `docker compose down`
   with vs without `-v`?
4. What problem does `depends_on` with a healthcheck solve that a plain `depends_on`
   does not?
5. In this stack, which container is reachable from your browser, and which are only
   reachable from inside the Compose network?

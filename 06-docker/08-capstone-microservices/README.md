# 08 - Capstone: Microservices on Docker

> The advanced capstone. Everything from the course, on a real microservices
> architecture: multiple services, **a database per service**, service-to-service
> calls, and one UI - all orchestrated with Docker Compose.

You will stand up a five-container system:

```
                   ┌─→ users-service  ─→ users-db   (Postgres)
   browser ─→ web ─┤          ▲
                   └─→ orders-service ─→ orders-db  (Postgres)
                              (calls users-service to resolve buyer names)
```

- **users-service** owns the `users` database. Nothing else touches it.
- **orders-service** owns the `orders` database. To show *who* placed each order, it
  calls **users-service** over the network (by service name) - this is
  service-to-service communication, the heart of microservices.
- **web** (nginx) is the single UI. It serves the page and routes `/api/users` to one
  service and `/api/orders` to the other.

This "database per service" split is exactly how real microservices are built: each
service is independently deployable and owns its own data.

The app code is written for you. Your job is the **Docker** work: containerize both
services and compose the whole system.

## How to use this set

```bash
# from the 06-docker/ folder or the repo root   (on Windows: course.cmd ...)
./course.sh start  08-capstone-microservices
#   ...write the two Dockerfiles + compose file, bring it up, then:
./course.sh verify 08-capstone-microservices
./course.sh reset  08-capstone-microservices     # tear the system down and re-seed

# or from inside this folder, section name left out:
#   ../course.sh verify
```

The seed drops the app under `06-docker/sandbox/08-capstone-microservices/`:

```
users-service/   app.py, requirements.txt        <- you add the Dockerfile
orders-service/  app.py, requirements.txt        <- you add the Dockerfile
frontend/        index.html, nginx.conf, Dockerfile  (done for you - copy the pattern)
```

Each service reads its database connection from env vars: `DB_HOST`, `DB_NAME`,
`DB_USER`, `DB_PASSWORD`. `orders-service` also needs `USERS_URL` to reach the users
service.

---

## Tier 1 - Containerize both services *(hint: both use the same `python:3-slim` pattern - see `frontend/Dockerfile`)*

**1.1 (graded)** Write `users-service/Dockerfile` and build it as `users:1`.

**1.2 (graded)** Write `orders-service/Dockerfile` and build it as `orders:1`.

```bash
docker build -t users:1  ./sandbox/08-capstone-microservices/users-service
docker build -t orders:1 ./sandbox/08-capstone-microservices/orders-service
```

## Tier 2 - Compose the whole system *(hint: five services, and a database per service)*

**2.1 (graded)** Write `docker-compose.yml` with **five services**:
- `users-db` and `orders-db` - each `postgres:16-alpine`, each with its own
  `POSTGRES_DB`/`USER`/`PASSWORD` and its **own named volume**.
- `users-service` - build `./users-service` as `image: users:1`, env pointing at
  `users-db`.
- `orders-service` - build `./orders-service` as `image: orders:1`, env pointing at
  `orders-db`, plus `USERS_URL=http://users-service:5000`.
- `web` - build `./frontend`, publish host port **8080** to **80**.

Bring the whole thing up in the background.

**2.2 (graded)** Give **each** database its **own** named volume (`usersdata` and
`ordersdata`). That is the database-per-service pattern - one service's data is never
mixed with another's.

## Tier 3 - Prove the whole system works *(goal only)*

> **Scenario:** ship day for a microservices app. A page load has to fan out to two
> services and two databases and come back correct.

**3.1 (graded)** `http://localhost:8080` lists the **users** - proving
`web → users-service → users-db` works.

**3.2 (graded)** The same page lists the **orders**, and each order shows the **buyer's
name**. That name is not in the orders database - `orders-service` fetched it by
**calling users-service**. Getting real names (not "unknown") proves the full mesh:
`web → orders-service → orders-db`, and `orders-service → users-service → users-db`.

When it is all green you have built and orchestrated a real microservices system:
independent services, a database each, talking to one another, behind a single UI.
This is the shape of production. 🎯

---

## Self-check questions

1. Why does each service get its **own** database instead of sharing one?
2. How does `orders-service` reach `users-service` - what does
   `http://users-service:5000` resolve to, and who provides that DNS?
3. Why can the two Postgres containers both listen on 5432 without clashing, while the
   UI must publish a unique host port?
4. If `users-service` is down, what happens to `/api/orders`, and how does the code
   here soften that failure?
5. What would you change to run **two** copies of `orders-service` for scale, and what
   makes that possible in this design?

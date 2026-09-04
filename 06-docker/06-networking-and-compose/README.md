# 06 - Networking & Compose

> Maps to **Docker for Professionals - Sections 10 & 11: Communication Between
> Containers + Docker Compose**
> (`docker network create`, `--network`, name-based DNS, `docker compose up/down/ps`)

Real apps are never one container - a web service talks to a cache, an API talks to a
database. First you will wire containers together **by hand** with a network so they
can find each other by name. Then you will throw that away and let **Docker Compose**
declare the whole stack in one file and bring it up with a single command. This is how
production stacks are actually run.

## How to use this set

```bash
# from the 06-docker/ folder or the repo root   (on Windows: course.cmd ...)
./course.sh start  06-networking-and-compose
#   ...run the docker commands below in this terminal, then:
./course.sh verify 06-networking-and-compose
./course.sh reset  06-networking-and-compose

# or from inside this folder, section name left out:
#   ../course.sh verify
```

Write your compose file at
`06-docker/sandbox/06-networking-and-compose/docker-compose.yml`.

---

## Tier 1 - A network for your containers *(hint: `docker network create NAME`, `docker network ls`)*

**1.1 (graded)** Create a user-defined network called `appnet`. Containers on the same
user-defined network can reach each other **by name** (Docker runs a built-in DNS).

## Tier 2 - Make containers talk by name *(hint: `docker run --network appnet ...`)*

**2.1 (graded)** Run a Redis cache named `store` (image `redis:alpine`) attached to
`appnet`.

**2.2 (graded)** Run an nginx container named `api` (image `nginx:alpine`) attached to
`appnet`, published on host port **8082**. Because both containers are on `appnet`,
`api` can reach the cache using the hostname `store` - no IP addresses needed.

> Prove it: `docker exec api getent hosts store` resolves `store` to its IP.

## Tier 3 - Let Compose run the whole stack *(goal only)*

> **Scenario:** wiring containers up one `docker run` at a time does not scale. Declare
> the stack once, in a file, and bring it up (and down) with one command. Compose even
> creates the network for you, so the services already talk by name.

**3.1 (graded)** Write a `docker-compose.yml` in this section's sandbox folder defining
two services:
- `web` - image `nginx:alpine`, publishing host port **8083** to **80**
- `cache` - image `redis:alpine`, with a **named volume** `cachedata` mounted at `/data`

Declare the `cachedata` volume, then bring the stack up in the background with one
command.

**3.2 (graded)** Confirm the stack is up: `web` reachable on `localhost:8083`, and the
`cachedata` volume created by Compose. (`docker compose ps` shows both services;
`docker compose down` would tear it all down again.)

All green = you can connect containers by name and run a multi-service stack with
Compose - the shape of nearly every real deployment.

---

## Self-check questions

1. Why can two containers on the same user-defined network reach each other by
   **name**, but two containers on the default bridge cannot?
2. In Compose, where does the network that lets services talk to each other come from?
3. What does `docker compose up -d` do, and what does `docker compose down` undo?
4. Why declare a **named volume** for the cache instead of storing data in the
   container?
5. What is one advantage of a `docker-compose.yml` over a shell script full of
   `docker run` commands?

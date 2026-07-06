# 06 - Docker for Professionals

Hands-on, auto-graded Docker exercises for the Amigoscode **Docker for Professionals**
course. You will run real containers, build real images, wire up volumes and
networks, and stand up a multi-service app with Docker Compose - then a script
checks your work with instant ✅ / ❌ feedback.

By the end you will do what a DevOps engineer does every day: package an app into an
image, run it reproducibly anywhere, debug it when it misbehaves, and ship a stack
of services that talk to each other.

## How this course is different

In every other course you drop *into* a throwaway container and work there. Here
**Docker itself is the subject**, so there is nothing to drop into - you run
`docker ...` commands directly in your terminal, exactly like Nelson does in the
lessons. The grader then inspects the **real Docker state** your commands produced
(which containers are running, which images and volumes exist, and so on).

You need a working Docker daemon:

- **GitHub Codespaces** (recommended): Docker is already installed and running -
  nothing to set up. Just open the Codespace and go.
- **Your own machine**: install [Docker Desktop](https://docs.docker.com/get-docker/)
  (Mac/Windows) or Docker Engine (Linux) and make sure it is running.

## How to use this set

```bash
# from the 06-docker/ folder
make setup                       # once (optional): pre-pull the images the course uses
make start  S=01-containers      # seed the scenario + print what to do
#   ...run the docker commands from the section README in this terminal, then:
make verify S=01-containers      # grade your work
make reset  S=01-containers      # remove this section's artifacts and start fresh
make stop   S=01-containers      # clean everything this section created
```

`make reset` and `make stop` only ever touch the containers, images, volumes and
networks **these exercises created** (they have specific names, listed in each
section). Your own Docker stuff is never touched.

Some sections give you starter files (an app to containerize, a compose file to
finish). Those appear under `06-docker/sandbox/<section>/`, which is git-ignored, so
your edits never collide when you sync new exercises.

## The three tiers

Every section has the same shape:

1. **Tier 1 - warm-up**: the goal plus the command you need.
2. **Tier 2 - core**: the goal with a lighter hint - you pick the flags.
3. **Tier 3 - challenge**: a real scenario, goal only. You work out the how.

Tasks are marked **(graded)** - checked by `verify.sh` - or **(drill)** - worth
doing but not auto-checked (usually because it needs a login or the internet).

## Sections

| # | Section | You will practise |
|---|---------|-------------------|
| 01 | [Containers](01-containers/) | `run`, `ps`, `-p`, `--name`, `-d`, `stop`/`start`/`rm` |
| 02 | [Images](02-images/) | `image ls`, `pull`, `inspect`, `tag`, versioning |
| 03 | [Volumes](03-volumes/) | bind mounts, named volumes, persisting data |
| 04 | [Building Images](04-building-images/) | `Dockerfile`, `build`, custom images, `.dockerignore` |
| 05 | [Debugging](05-debugging/) | `logs`, `exec`, `inspect` |
| 06 | [Networking & Compose](06-networking-and-compose/) | `network`, service-to-service, `docker compose` |

Stuck on any task? Each section has a `solutions.md` - but try first.

## A note on `docker rm -f` and `docker compose down`

These commands remove containers without asking. That is fine here: everything you
create is disposable and named for the exercise. In production you would be more
careful - but this is exactly the sandbox to build the muscle memory safely.

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

**Docker is the only thing you need to install.** No `make`, no Python, no
build tools - if `docker` works in your terminal, you are ready.

- **GitHub Codespaces** (recommended): Docker is already installed and running -
  nothing to set up. Just open the Codespace and go.
- **Your own machine**: install [Docker Desktop](https://docs.docker.com/get-docker/)
  (Mac/Windows) or Docker Engine (Linux) and make sure it is running.

## How to use this set

Everything runs through one launcher script. Pick the line for your machine:

**macOS, Linux, WSL, Git Bash, Codespaces**

```bash
# from the 06-docker/ folder
./course.sh setup                 # once (optional): pre-pull the images the course uses
./course.sh start  01-containers  # seed the scenario + print what to do
#   ...run the docker commands from the section README in this terminal, then:
./course.sh verify 01-containers  # grade your work
./course.sh reset  01-containers  # remove this section's artifacts and start fresh
./course.sh stop   01-containers  # clean everything this section created
```

**Windows (PowerShell or Command Prompt)**

```powershell
# from the 06-docker\ folder - same commands, course.cmd instead of ./course.sh
course.cmd setup
course.cmd start  01-containers
course.cmd verify 01-containers
course.cmd reset  01-containers
course.cmd stop   01-containers
```

Windows has no `bash`, so `course.cmd` runs the same scripts inside a tiny
throwaway container wired to *your* Docker daemon. It builds that helper image
once, on your first command, and everything it seeds and grades is the real
Docker state on your machine - identical to what Mac and Linux students see.

You do not have to type the full section name. These are all the same command:

```bash
./course.sh verify 01-containers
./course.sh verify containers
./course.sh verify 1
```

Run `./course.sh` (or `course.cmd`) with no arguments to see the commands and the
list of sections.

### Running it from any folder

There is a launcher in the **repo root** and in **`06-docker/`**, so both of these
work out of the box:

```bash
./course.sh verify 01-containers            # from the repo root
cd 06-docker && ./course.sh verify 01-containers
```

Inside a section folder you can drop the section name - it is taken from the folder
you are standing in:

```bash
cd 06-docker/03-volumes
../course.sh verify                          # knows you mean 03-volumes
```

And if you would rather just type `course` anywhere - in a deep sandbox folder, or
in a completely different project - install it once:

```bash
./course.sh install       # macOS/Linux: adds ~/.local/bin/course
course.cmd install        # Windows: adds %USERPROFILE%\.local\bin\course.cmd to your PATH
```

Then, from anywhere:

```bash
course verify 01-containers
cd 06-docker/sandbox/03-volumes/site && course verify
```

`./course.sh uninstall` removes it again. The installed `course` is a two-line
wrapper pointing back at this checkout - it does not copy or move anything.

`reset` and `stop` only ever touch the containers, images, volumes and
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
| 07 | [Capstone: Full-Stack App](07-capstone/) | build a backend image + compose a UI + API + Postgres stack |
| 08 | [Capstone: Microservices](08-capstone-microservices/) | 2 services + 2 databases + 1 UI, with service-to-service calls |
| 09 | [Capstone: Ship a Real App](09-capstone-smart-lead/) | open-ended - containerize a real Spring Boot + Postgres + SQS app, reviewed in the Academy |

Stuck on any task? Each section has a `solutions.md` - but try first.

## A note on `docker rm -f` and `docker compose down`

These commands remove containers without asking. That is fine here: everything you
create is disposable and named for the exercise. In production you would be more
careful - but this is exactly the sandbox to build the muscle memory safely.

# 05 - Debugging

> Maps to **Docker for Professionals - Section 9: Debugging**
> (`docker logs`, `docker logs -f`, `docker exec`, `docker inspect`)

When a container misbehaves in production you cannot just "open the app" - it is a
black box. Three commands are how a DevOps engineer sees inside: `logs` (what it is
printing), `exec` (run commands inside it live), and `inspect` (its full low-level
config). This section is a mini incident: a container is acting up, and you use these
tools to diagnose and fix it.

## How to use this set

```bash
# from the 06-docker/ folder or the repo root   (on Windows: course.cmd ...)
./course.sh start  05-debugging
#   ...run the docker commands below in this terminal, then:
./course.sh verify 05-debugging
./course.sh reset  05-debugging

# or from inside this folder, section name left out:
#   ../course.sh verify
```

The seed leaves a misbehaving container called `buggy` running. Save your findings
into files under `06-docker/sandbox/05-debugging/` (run the commands from the
`06-docker/` folder so the relative paths line up).

---

## Tier 1 - Read the logs *(hint: `docker logs CONTAINER`)*

**1.1 (graded)** The `buggy` container printed an error when it started. Read its logs,
find the line containing `ERROR`, and save **that line** to
`sandbox/05-debugging/error.txt`.

**1.2 (drill)** Follow the logs live with `docker logs -f buggy` and watch the
heartbeats arrive. Press Ctrl+C to stop following (this does **not** stop the
container).

## Tier 2 - Get inside a running container *(hint: `docker exec CONTAINER COMMAND`)*

**2.1 (graded)** Which environment does the app think it is in? Use `docker exec` to
read the container's environment variables, and save the `APP_ENV=...` line to
`sandbox/05-debugging/env.txt`.

**2.2 (graded)** Apply a live fix: use `docker exec` to create an (empty) file at
`/tmp/fixed` **inside** the `buggy` container. (This proves you can run commands in a
running container - exactly how you patch or probe one during an incident.)

## Tier 3 - Inspect the low-level config *(goal only)*

> **Scenario:** the on-call ticket needs the exact version this container was labelled
> with. That detail is not in the logs - it is in the container's metadata.

**3.1 (graded)** Use `docker inspect` to pull the container's `version` **label** and
save just the value to `sandbox/05-debugging/version.txt`.

All green = you can diagnose a container from the outside (`logs`, `inspect`) and from
the inside (`exec`) - the core debugging loop.

---

## Self-check questions

1. What does `docker logs -f` do that `docker logs` does not?
2. Does pressing Ctrl+C while following logs stop the container? Why or why not?
3. What is `docker exec` for, and how is it different from `docker run`?
4. Name two things `docker inspect` can tell you that the logs cannot.
5. How would you open an interactive shell inside a running container?

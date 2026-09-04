# 01 - Containers

> Maps to **Docker for Professionals - Sections 1 & 2: Getting Started + Containers**
> (`docker run`, `-p`, `--name`, `-d`, `docker ps`, `docker ps -a`, `stop`, `start`, `rm`)

A container is a running instance of an image - a tiny, isolated machine that boots
in seconds and throws away cleanly. Running and managing containers is the first
thing you do with Docker, and something a DevOps engineer does dozens of times a day.

## How to use this set

You run `docker` commands directly in your terminal (see the main
[course README](../README.md) for why there is no container to enter here).

```bash
# from the 06-docker/ folder or the repo root   (on Windows: course.cmd ...)
./course.sh start  01-containers      # seeds a couple of containers for you to manage
#   ...run the docker commands below in this terminal, then:
./course.sh verify 01-containers      # grades your work
./course.sh reset  01-containers      # remove this section's containers and start fresh

# or from inside this folder, section name left out:
#   ../course.sh verify
```

The seed leaves two containers running for you: `scratch` and `old-web`.

---

## Tier 1 - Run your first container *(hint: `docker run -d --name NAME -p HOST:CONTAINER IMAGE`)*

**1.1 (graded)** Run an `nginx:alpine` web server **in the background**, name it `web`,
and map **host port 8080** to the container's **port 80**.

**1.2 (drill)** Open `http://localhost:8080` in a browser (or `curl localhost:8080`).
You should see the nginx welcome page - your container is serving traffic.

## Tier 2 - Name it, background it, manage it *(hint: `docker ps`, `docker stop`, `docker start`)*

**2.1 (graded)** Run the game `amigoscode/2048` in the background, named `game`, on
**host port 8081** mapped to container port **80**. (Open `localhost:8081` and play.)

**2.2 (graded)** The seed left a container called `scratch` running. **Stop** it -
without removing it. Confirm with `docker ps -a` that it shows as `Exited`.

## Tier 3 - Challenge: clean up the box *(goal only)*

> **Scenario:** you inherit a server. The previous engineer left an abandoned
> container called `old-web` running from an old deploy. Get the box to the state
> your team expects: `web` serving on 8080, `game` serving on 8081, and no leftover
> junk.

**3.1 (graded)** Remove the `old-web` container **completely** - it is still running,
so a plain remove will refuse. Get rid of it in one command.

When it is all green, you have run, named, exposed, stopped and cleaned up
containers - the core container lifecycle.

---

## Self-check questions

1. What is the difference between an **image** and a **container**?
2. In `-p 8080:80`, which number is the host and which is the container?
3. What does `-d` do, and what happens if you leave it off?
4. Why does `docker rm` refuse a running container, and how do you force it?
5. `docker ps` vs `docker ps -a` - what is the difference?

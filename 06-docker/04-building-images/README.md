# 04 - Building Images

> Maps to **Docker for Professionals - Section 6: Building Docker Images**
> (`Dockerfile`: `FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`, `EXPOSE`; `docker build -t`; `.dockerignore`)

Pulling other people's images is fine - but the real power of Docker is packaging
**your own** app into an image that runs identically on your laptop, in CI, and in
production. You do that with a `Dockerfile`: a short recipe Docker follows to build
an image. This is the single most important Docker skill for a DevOps engineer.

## How to use this set

```bash
# from the 06-docker/ folder or the repo root   (on Windows: course.cmd ...)
./course.sh start  04-building-images
#   ...write Dockerfiles and run docker build in this terminal, then:
./course.sh verify 04-building-images
./course.sh reset  04-building-images

# or from inside this folder, section name left out:
#   ../course.sh verify
```

The seed gives you two starter apps under `06-docker/sandbox/04-building-images/`:
`site/` (a static page) and `clock/` (a tiny Python service). You add the Dockerfiles.

---

## Tier 1 - Your first Dockerfile *(hint: `FROM`, `COPY`, then `docker build -t NAME .`)*

**1.1 (graded)** In `site/`, create a file named `Dockerfile` that:
- starts `FROM nginx:alpine`
- copies everything in the folder into nginx's web root `/usr/share/nginx/html`

Then build it into an image tagged `static-site:1`:
```bash
cd sandbox/04-building-images/site
docker build -t static-site:1 .
```

**1.2 (graded)** Run a container named `site` from your `static-site:1` image,
publishing host port **8082** to **80**. The page is now **baked into the image** -
no bind mount needed. Open `localhost:8082` to see it.

## Tier 2 - An image with a build step *(hint: `FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`)*

The `clock/` folder has `app.py`, a tiny service that prints a heartbeat every second.

**2.1 (graded)** Write a `Dockerfile` in `clock/` that bases off `python:3-alpine`,
sets a working directory, copies the app in, has a **build step** (`RUN`), and defines
the **start command** (`CMD`) that runs `app.py`. Build it as `clock:1`.

**2.2 (graded)** Run it detached, named `clock`. Confirm it works by reading its
output with `docker logs clock` - you should see it starting up and ticking.

## Tier 3 - Challenge: make the image production-grade *(goal only)*

> **Scenario:** a security review is coming. Your image must not ship secrets, and it
> must not run as root.

**3.1 (graded)** The `clock/` folder also contains `secret.txt` and `notes.md` - these
must **never** end up inside the image. Make sure your build excludes them, then
rebuild `clock:1`. (Look up how Docker decides what to skip when copying.)

**3.2 (graded)** Containers that run as `root` are a real risk. Make `clock:1` run as
a **non-root** user, then rebuild. (Your app only needs to read its files, so a plain
unprivileged user is enough.)

**3.3 (drill)** Scan your image for known vulnerabilities with `docker scout quickview
clock:1` (or Trivy). Not graded - it needs internet - but this is exactly how teams
catch vulnerable base images before shipping. Distroless and slim bases are the next
step to shrink the attack surface.

All green = you can package any app into a small, secret-free, non-root image. This is
the heart of Docker.

---

## Self-check questions

1. What does each of `FROM`, `WORKDIR`, `COPY`, `RUN` and `CMD` do?
2. What is the difference between `RUN` and `CMD`?
3. What does `docker build -t static-site:1 .` mean - especially the `.`?
4. What is a `.dockerignore` file for, and name two things you should always ignore.
5. Why is running a container as root a security risk, and how do you avoid it?

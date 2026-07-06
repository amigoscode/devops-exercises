# Solutions - Building Images

## Tier 1
**1.1** `site/Dockerfile`:
```dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
```
Build it:
```bash
cd sandbox/04-building-images/site
docker build -t static-site:1 .
```

**1.2** Run your image:
```bash
docker run -d --name site -p 8082:80 static-site:1
curl localhost:8082
```

## Tier 2
**2.1** `clock/Dockerfile`:
```dockerfile
FROM python:3-alpine
WORKDIR /src
COPY . .
RUN python -m py_compile app.py      # a build step
CMD ["python", "app.py"]
```
Build it:
```bash
cd sandbox/04-building-images/clock
docker build -t clock:1 .
```

**2.2** Run and check the logs:
```bash
docker run -d --name clock clock:1
docker logs clock          # "clock service starting", then "tick"...
docker logs -f clock       # follow live (Ctrl+C to stop following)
```

## Tier 3
**3.1** Add `clock/.dockerignore` so secrets/junk are never copied in:
```
secret.txt
notes.md
*.md
```
Then rebuild: `docker build -t clock:1 .`
Verify nothing leaked: `docker run --rm clock:1 ls /src` (no `secret.txt`).

**3.2** Run as a non-root user. Updated `clock/Dockerfile`:
```dockerfile
FROM python:3-alpine
WORKDIR /src
COPY . .
RUN python -m py_compile app.py
RUN adduser -D appuser       # create an unprivileged user (Alpine syntax)
USER appuser                 # everything after this runs as appuser
CMD ["python", "app.py"]
```
Rebuild, then check: `docker run --rm clock:1 whoami` prints `appuser`, not `root`.

**3.3** Scan it:
```bash
docker scout quickview clock:1     # or: trivy image clock:1
```

### Answers
1. `FROM` = the base image to build on. `WORKDIR` = the directory inside the image
   where later commands run (created if missing). `COPY` = copy files from your build
   context into the image. `RUN` = execute a command **at build time** (installs,
   compiles). `CMD` = the default command run **when a container starts**.
2. `RUN` happens once, while the image is being built, and its result is baked into a
   layer. `CMD` happens every time a container starts from the image.
3. Build an image and tag it `static-site:1`. The `.` is the **build context** - the
   current directory, which Docker sends to the daemon and where it looks for the
   `Dockerfile` and the files you `COPY`.
4. `.dockerignore` lists paths Docker should **not** send into the build / copy into
   the image. Always ignore secrets (`.env`, keys) and heavy/rebuildable dirs
   (`node_modules`, `.git`).
5. A root process that escapes the container has root on concerns beyond it. Running
   as an unprivileged `USER` limits the blast radius if the app is compromised.

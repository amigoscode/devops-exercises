# Solutions - Containers

## Tier 1
**1.1** Run nginx detached, named, with a published port:
```bash
docker run -d --name web -p 8080:80 nginx:alpine
docker ps                      # confirm it is up
```

**1.2** See it serving:
```bash
curl localhost:8080            # or open http://localhost:8080 in a browser
```

## Tier 2
**2.1** Same pattern, different image and port:
```bash
docker run -d --name game -p 8081:80 amigoscode/2048
```

**2.2** Stop (do not remove) the seeded container:
```bash
docker stop scratch
docker ps -a                   # scratch now shows "Exited"
docker start scratch           # (for reference) this would start it again
```

## Tier 3
**3.1** A running container will not be removed by a plain `docker rm`; force it:
```bash
docker rm -f old-web
```

### Answers
1. An **image** is the read-only template (the packaged app + its filesystem). A
   **container** is a running (or stopped) instance created from that image. One
   image, many containers.
2. `-p HOST:CONTAINER`. So `8080:80` = host port 8080 forwards to port 80 inside the
   container. You reach it at `localhost:8080`.
3. `-d` (detached) runs the container in the background and returns your prompt.
   Without it the container runs in the foreground and its logs take over your
   terminal until you press Ctrl+C (which stops it).
4. Removing a running container could destroy something in use, so `docker rm`
   refuses. `docker rm -f` stops and removes it in one step.
5. `docker ps` lists only **running** containers; `docker ps -a` lists **all**
   containers, including stopped/exited ones.

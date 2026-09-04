# Solutions - Volumes

## Tier 1
**1.1** Bind-mount the folder onto nginx's web root:
```bash
cd sandbox/03-volumes/site
docker run -d --name bindweb -p 8080:80 -v "$(pwd)":/usr/share/nginx/html nginx:alpine
# Windows PowerShell: docker run -d --name bindweb -p 8080:80 -v "${PWD}:/usr/share/nginx/html" nginx:alpine
curl localhost:8080            # serves your index.html
```

**1.2** Edit `index.html`, reload - the change is live immediately.

## Tier 2
**2.1** Create a managed volume:
```bash
docker volume create appdata
docker volume ls              # appdata appears
docker volume inspect appdata # see its mount point
```

**2.2** Mount it into a container:
```bash
docker run -d --name keeper -v appdata:/data nginx:alpine
```

## Tier 3
**3.1** Write into the volume, then prove it persists:
```bash
docker exec keeper sh -c 'echo survived > /data/persisted.txt'
docker rm -f keeper
docker run --rm -v appdata:/data nginx:alpine cat /data/persisted.txt   # "survived"
```

### Answers
1. **Bind mount**: share a specific host folder (source lives on your machine) - ideal
   for local dev where you edit files live. **Named volume**: Docker owns the storage -
   ideal for databases and anything you just need to persist and not hand-edit.
2. `-v appdata:/data` = volume name `appdata` mounted at `/data` inside the container.
3. The data lives in the volume, which is a separate object from the container.
   Removing the container does not remove the volume.
4. In a Docker-managed area on the host (on Linux, under `/var/lib/docker/volumes/...`).
   "Managed" means Docker controls the location and lifecycle - you refer to it by name.
5. Your edits on the host appear instantly inside the container with no rebuild, so
   you can develop against a running container in real time.

# Solutions - Images

## Tier 1
**1.1** Pull without running:
```bash
docker pull httpd:alpine
docker image ls                # httpd now appears in the list
```

**1.2** Inspect an image:
```bash
docker image inspect nginx:alpine
docker image inspect nginx:alpine --format '{{.Id}}'   # just the image ID
```

## Tier 2
**2.1 / 2.2** Tagging creates a new name for an existing image:
```bash
docker tag nginx:alpine dashboard:1
docker tag nginx:alpine dashboard:2
docker image ls dashboard      # both tags, same IMAGE ID
```

## Tier 3
**3.1** Pin to a real version tag:
```bash
docker pull busybox:1.36
```

**3.2** Remove only the floating tag:
```bash
docker rmi dashboard:latest
docker image ls dashboard      # 1 and 2 remain
```

### Answers
1. A tag is just a **named pointer** to an image ID. Many tags can point at the same
   ID, so `dashboard:1` and `dashboard:2` can be identical bytes under two names.
2. `latest` floats - it is whatever was most recently tagged. A restart can pull a
   changed image and silently give you different software, with no easy rollback.
3. `docker tag` does **not** copy data. It adds another name (repository:tag) that
   points at the same image ID.
4. A variant is the same software built on a smaller/different base - `alpine` (tiny
   Alpine Linux) or `slim` (trimmed). Smaller image = faster pulls and less to patch.
5. No. `docker rmi` on a tag just removes that tag. The image data is only deleted
   once no tags reference it.

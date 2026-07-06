# Solutions - Networking & Compose

## Tier 1
**1.1** Create a user-defined network:
```bash
docker network create appnet
docker network ls            # appnet is listed
```

## Tier 2
**2.1** Run the cache on the network:
```bash
docker run -d --name store --network appnet redis:alpine
```

**2.2** Run the api on the same network and prove name resolution:
```bash
docker run -d --name api --network appnet -p 8082:80 nginx:alpine
docker exec api getent hosts store     # resolves "store" to its IP - they can talk by name
```

## Tier 3
**3.1 / 3.2** Write `sandbox/06-networking-and-compose/docker-compose.yml`:
```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8083:80"
  cache:
    image: redis:alpine
    volumes:
      - cachedata:/data

volumes:
  cachedata:
```
Bring it up and check it (run from the folder with the file):
```bash
cd sandbox/06-networking-and-compose
docker compose up -d
docker compose ps            # web and cache both running
docker volume ls | grep cachedata
curl localhost:8083          # nginx welcome page
docker compose down          # tears the whole stack down (add -v to drop the volume)
```

### Answers
1. Docker runs an embedded DNS server for **user-defined** networks that resolves
   container names to IPs. The legacy default bridge does not provide name-based DNS,
   only IPs (or the old `--link`).
2. Compose creates a default network for the project automatically and attaches every
   service to it, so services reach each other by their **service name**.
3. `docker compose up -d` creates and starts all services (and their network/volumes)
   in the background. `docker compose down` stops and removes the containers and the
   network (add `-v` to also remove named volumes).
4. A named volume lives outside the container, so the cache's data survives the
   container being recreated on the next `up` or a new image version.
5. It is declarative and version-controlled: one file describes the whole stack, brings
   it up identically every time, and tears it down cleanly - no long, error-prone
   `docker run` commands to remember.

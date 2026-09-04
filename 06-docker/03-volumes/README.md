# 03 - Volumes

> Maps to **Docker for Professionals - Section 5: Volumes**
> (bind mounts with `-v host:container`, named volumes, `docker volume create/ls/inspect/rm`)

Containers are disposable - delete one and everything inside it is gone. So where
does data that must **survive** live? In volumes. Two kinds matter: **bind mounts**
(share a folder from your machine, great for local dev) and **named volumes** (Docker
manages the storage, great for databases). Getting this right is the difference
between "my data vanished" and a system you can trust.

## How to use this set

```bash
# from the 06-docker/ folder or the repo root   (on Windows: course.cmd ...)
./course.sh start  03-volumes
#   ...run the docker commands below in this terminal, then:
./course.sh verify 03-volumes
./course.sh reset  03-volumes

# or from inside this folder, section name left out:
#   ../course.sh verify
```

The seed creates a small website for you at
`06-docker/sandbox/03-volumes/site/index.html`.

---

## Tier 1 - Bind mount a folder *(hint: `docker run -v HOST_PATH:CONTAINER_PATH ...`)*

**1.1 (graded)** Serve the seeded `site/` folder with nginx **without building an
image** - bind-mount it straight in. Run an `nginx:alpine` container named `bindweb`,
publish host port **8080** to **80**, and bind-mount the site folder onto nginx's web
root `/usr/share/nginx/html`.

> Tip: `cd` into the folder first, then use the "current folder" variable as the host path:
> ```bash
> # macOS / Linux / WSL
> cd sandbox/03-volumes/site
> docker run -d --name bindweb -p 8080:80 -v "$(pwd)":/usr/share/nginx/html nginx:alpine
> ```
> ```powershell
> # Windows PowerShell - same command, ${PWD} instead of $(pwd)
> cd sandbox\03-volumes\site
> docker run -d --name bindweb -p 8080:80 -v "${PWD}:/usr/share/nginx/html" nginx:alpine
> ```

**1.2 (drill)** Edit `site/index.html` on your machine and reload `localhost:8080`.
The change shows **instantly** - no rebuild. That is the power of a bind mount for
local development.

## Tier 2 - Named volumes *(hint: `docker volume create`, then `-v NAME:PATH`)*

**2.1 (graded)** Create a Docker-managed **named volume** called `appdata`.

**2.2 (graded)** Run an `nginx:alpine` container named `keeper` that mounts the
`appdata` volume at `/data`.

## Tier 3 - Challenge: prove your data survives *(goal only)*

> **Scenario:** a database's files must outlive any single container. Destroy the
> container, and the data is still there for the next one.

**3.1 (graded)** Write a file `/data/persisted.txt` containing the word `survived`
into the `appdata` volume (from a container that has it mounted). Because it lives in
the volume, a brand-new container mounting `appdata` will still see it - even after
the container that wrote it is gone.

> Prove it to yourself:
> ```bash
> docker rm -f keeper
> docker run --rm -v appdata:/data nginx:alpine cat /data/persisted.txt   # still "survived"
> ```

All green = you can share folders for dev and persist data with managed volumes.

---

## Self-check questions

1. When would you use a **bind mount** vs a **named volume**?
2. In `-v appdata:/data`, which side is the volume and which is the path inside the
   container?
3. Why does data in a named volume survive `docker rm` of the container?
4. Where does Docker store a named volume's data (roughly), and why is that "managed"?
5. Why are bind mounts so handy during local development?

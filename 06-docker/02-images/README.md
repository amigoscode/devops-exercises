# 02 - Images

> Maps to **Docker for Professionals - Sections 3 & 7: Images + Tags & Versioning**
> (`docker image ls`, `docker pull`, `docker image inspect`, `docker tag`, pinning versions)

An image is the packaged, read-only template a container runs from. Knowing how to
pull the right image, inspect it, and tag your own versions is what lets a DevOps
engineer ship software that runs the **same** way everywhere - and roll back when a
release goes wrong.

## How to use this set

```bash
# from the 06-docker/ folder or the repo root   (on Windows: course.cmd ...)
./course.sh start  02-images
#   ...run the docker commands below in this terminal, then:
./course.sh verify 02-images
./course.sh reset  02-images

# or from inside this folder, section name left out:
#   ../course.sh verify
```

The seed leaves a stray `dashboard:latest` tag lying around for the Tier 3 clean-up.

---

## Tier 1 - Pull and inspect *(hint: `docker pull IMAGE`, `docker image ls`, `docker image inspect`)*

**1.1 (graded)** Pull the Apache web server image `httpd:alpine` - just pull it, do
**not** run a container from it.

**1.2 (drill)** Run `docker image ls`, then `docker image inspect nginx:alpine`. Look
at the size, the layers and the created date. This is how you learn what is inside an
image before you trust it.

## Tier 2 - Tag your own versions *(hint: `docker tag SOURCE TARGET`)*

You are going to publish the nginx image under your team's own name, `dashboard`.

**2.1 (graded)** Create a tag `dashboard:1` that points at `nginx:alpine`.

**2.2 (graded)** Ship a second release: tag `nginx:alpine` as `dashboard:2` as well.
Run `docker image ls` and you will see `dashboard` with both `1` and `2` tags.

## Tier 3 - Challenge: make it production-safe *(goal only)*

> **Scenario:** "Never run `latest` in production." A floating `latest` tag can change
> under you on the next restart. Production must pull a **specific, pinned** version.

**3.1 (graded)** Pull a specific pinned version of BusyBox: `busybox:1.36` (a real
version tag, not `latest`), so a deploy is always reproducible.

**3.2 (graded)** The seed left a risky `dashboard:latest` tag behind. Remove **just**
that tag, leaving your pinned `dashboard:1` and `dashboard:2` intact.

All green = you can pull, pin, tag and version images the way real deployments do.

---

## Self-check questions

1. Why can two different tags (`dashboard:1` and `dashboard:2`) point at the same
   image ID?
2. What is the danger of running `latest` in production?
3. What does `docker tag` actually create - a copy of the image, or something else?
4. What is an "image variant" like `alpine` or `slim`, and why prefer it?
5. Does `docker rmi dashboard:latest` delete the image's data if another tag still
   points at it?

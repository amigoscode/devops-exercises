# 03 · System Admin & Maintenance

> Maps to **Linux for Professionals → Section 19: System Admin & Maintenance**
> (package managers, `httpie`/`jq`, processes `top`/`ps`/`kill`, disk `df`/`du`)

Keeping a server healthy: watch disk, manage processes, and parse the JSON that
every modern API and tool speaks. These are the reflexes you reach for when
something's wrong at 2am.

## How to use this set

```bash
# from the 03-linux-for-professionals/ folder
make start  S=03-system-admin
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=03-system-admin
make reset  S=03-system-admin
```

---

## Tier 1 - Disk usage *(hint: `df` and `du`, with a human-readable flag)*

**1.1 (graded)** Capture filesystem usage, human-readable, into `~/sandbox/disk.txt`.

**1.2 (graded)** Measure the **total** size of the `~/sandbox/data` directory and
save it (human-readable) to `~/sandbox/data-size.txt`.

## Tier 2 - Processes *(think: list processes, then stop the wrong one)*

**2.1 (graded)** Snapshot all running processes into `~/sandbox/processes.txt`.

**2.2 (graded)** > **Scenario:** a runaway `sleep` process is hogging the box.
Use `ps` (or `top`/`htop`) to find it, and record its **PID** in
`~/sandbox/runaway-pid.txt`.

## Tier 3 - Parse JSON with `jq` *(goal only - build the jq filters)*

> Everything speaks JSON - APIs, `kubectl`, `docker inspect`, cloud CLIs. `jq` is
> how you pull a field out of it. Work on `~/sandbox/services.json`.

**3.1 (graded)** Extract the **service name** into `~/sandbox/name.txt`.

**3.2 (graded)** Extract the **service version** into `~/sandbox/version.txt`.

**3.3 (graded)** Extract the **replicas** value into `~/sandbox/replicas.txt`.

## 💪 Drills (self-check - need internet, so not graded)

- **Package manager:** `sudo apt update && sudo apt install -y htop`, then run `htop`.
- **httpie + jq over the wire:** `http https://httpbin.org/json | jq '.slideshow.title'`

## Self-check questions

1. `df` vs `du` - what does each tell you?
2. How do you find a misbehaving process and its PID (with `top`/`htop`/`ps`)?
3. What does `jq -r '.service.name'` do, and why `-r`?

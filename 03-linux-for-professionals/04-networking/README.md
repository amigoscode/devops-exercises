# 04 · Networking

> Maps to **Linux for Professionals → Section 20: Networking**
> (`ping`, `ss`, `nslookup`, `netcat`, `traceroute`, `ufw`, `curl`)

Networking is how servers talk. Here you'll inspect interfaces and sockets, and
hit a real HTTP service with `curl` - then parse its JSON, the exact loop you run
against every API in production.

> A **local web service runs at `http://localhost:8000`** inside the container, so
> the `curl`/`ss` tasks work fully offline. The internet-only tools (`ping`,
> `nslookup`, `traceroute`, `ufw`) are **drills** at the bottom - run them on a real
> machine.

## How to use this set

```bash
make start  S=04-networking
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=04-networking
make reset  S=04-networking
```

---

## Tier 1 - Inspect open sockets *(hint: the `ss` command)*

**1.1 (graded)** List **all** open sockets and save them into `~/sandbox/sockets.txt`
- the local service on port 8000 should show up. *(Hint: `ss` with the "all" flag.)*

## Tier 2 - Talk to a service with curl *(think: which curl flag does each job)*

**2.1 (graded)** Download `http://localhost:8000/hello.txt` and **save it to a file**
at `~/sandbox/fetched.txt`.

**2.2 (graded)** Fetch **only the response headers** of `http://localhost:8000/`
into `~/sandbox/headers.txt`.

## Tier 3 - curl + jq: the real API workflow *(goal only)*

**3.1 (graded)** Request `http://localhost:8000/services.json`, extract the
**service name** from the JSON, and save it to `~/sandbox/svc.txt`.

## 💪 Live-internet drills (self-check - need a real network/privileges)

- **ping:** `ping -c 4 google.com` (latency + packet loss)
- **DNS:** `nslookup github.com`
- **route:** `traceroute google.com`
- **firewall (needs a real host):** `sudo apt install -y ufw && sudo ufw status`,
  `sudo ufw allow 22`, `sudo ufw deny 80`

## Self-check questions

1. What does `ss -a` show you, and when is it useful?
2. `curl -o` vs `curl -I` - what's the difference?
3. Why is `curl … | jq` such a common pairing for DevOps work?

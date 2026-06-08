# Linux for Professionals - Hands-On Exercises

The sequel to Linux Fundamentals - the power-user and sysadmin skills that turn you
into someone who can actually operate servers: redirection & pipes, environment
variables, system administration, networking, and SSH.

Every exercise runs in a disposable Ubuntu container and is auto-graded.

## Quick start

```bash
make build                              # build the image once
make start  S=01-redirection-and-pipes
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=01-redirection-and-pipes
make reset  S=01-redirection-and-pipes
```

Needs **Docker** and **make** (both provided in GitHub Codespaces).

## Sections

| # | Section | Course § | Status |
|---|---------|----------|--------|
| 01 | [Redirection & Pipes](01-redirection-and-pipes/) | 17 | ✅ built |
| 02 | [Environment Variables](02-environment-variables/) | 18 | ✅ built |
| 03 | [System Admin & Maintenance](03-system-admin/) | 19 | ✅ built (jq, processes, disk) |
| 04 | [Networking](04-networking/) | 20 | ✅ built (ip, ss, curl+jq; live tools as drills) |
| 05 | [SSH](05-ssh/) | 21 | ✅ built (keys + ssh config; EC2 as drills) |

Each section: `README.md` (3-tier tasks) · `seed.sh` · `verify.sh` · `solutions.md`.

Sections 04-05 auto-grade everything that works offline (a local web service for
`curl`/`ss`, `ssh-keygen` + `~/.ssh/config`); the internet/cloud-only commands
(`ping`, `nslookup`, `ufw`, real EC2) are clearly-labelled self-check drills.

## The 3-tier model

Warm-up → core → a real DevOps challenge, exactly like the other courses.

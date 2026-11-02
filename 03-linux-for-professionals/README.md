# Linux for Professionals - Hands-On Exercises

The sequel to Linux Fundamentals - the power-user and sysadmin skills that turn you
into someone who can actually operate servers: redirection & pipes, environment
variables, system administration, networking, and SSH.

Every exercise runs in a disposable Ubuntu container and is auto-graded.

## Quick start

From the repo root:

```bash
./academy.sh        # macOS, Linux, WSL, Git Bash, Codespaces
academy.cmd         # Windows
```

Pick **Linux for Professionals**, choose a section and press `enter`: you get a fresh Ubuntu
sandbox with the scenario already set up and the questions printed at the top.
Inside it, `questions` shows them again, `check` grades your work, and `exit`
takes you back with your progress saved.

**Docker is the only thing you need installed.** (Codespaces works too - zero install.)

## Sections

| # | Section | Course § | Status |
|---|---------|----------|--------|
| 01 | [Redirection & Pipes](01-redirection-and-pipes/) | 17 | ✅ built |
| 02 | [Environment Variables](02-environment-variables/) | 18 | ✅ built |
| 03 | [System Admin & Maintenance](03-system-admin/) | 19 | ✅ built (jq, processes, disk) |
| 04 | [Networking](04-networking/) | 20 | ✅ built (ip, ss, curl+jq; live tools as drills) |
| 05 | [SSH](05-ssh/) | 21 | ✅ built (ssh config graded; keys + EC2 as drills) |

Each section: `README.md` (3-tier tasks) · `seed.sh` · `verify.sh` · `solutions.md`.

Sections 04-05 auto-grade everything that works offline (a local web service for
`curl`/`ss`, `~/.ssh/config`); `ssh-keygen` and the internet/cloud-only commands
(`ping`, `nslookup`, `ufw`, real EC2) are clearly-labelled self-check drills.

## The 3-tier model

Warm-up → core → a real DevOps challenge, exactly like the other courses.

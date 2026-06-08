# Linux Fundamentals - Hands-On Exercises

Practice exercises for the **Linux Fundamentals** course. Every exercise runs
inside a disposable **Ubuntu container**, so:

- 🛡️ **Safe** - `rm -rf`, `chmod 000`, `chown root` can't touch your real machine
- 🐧 **Real Linux** - actual `useradd`, `chown`, sudoers - works the same on Mac/Windows/Linux
- 🔁 **Resettable** - one command nukes your mistakes and starts fresh
- ✅ **Auto-graded** - every section ships a `verify.sh` that scores your work
- 🚀 **DevOps-flavored** - Tier-3 challenges are real on-call / provisioning scenarios

Using Docker to learn Linux is itself a step toward DevOps - it's the same tool
you'll go deep on later in the track.

## Quick start

```bash
make build                            # build the Ubuntu image once
make start  S=08-file-permissions     # enter a pristine shell, scenario seeded
make verify S=08-file-permissions     # grade your work
make reset  S=08-file-permissions     # fresh start
make stop   S=08-file-permissions     # tidy up
```

You only need **Docker** + **make** installed. (Codespaces works too - zero install.)

## Sections

Each maps to a course section. Every folder has the same shape:
`README.md` (3-tier exercises) · `seed.sh` (builds the scenario) ·
`verify.sh` (auto-grader) · `solutions.md`.

| # | Exercise | Course § | Tier-3 DevOps scenario |
|---|----------|----------|------------------------|
| 01 | The Terminal           | 7  | ✅ **built** - find/re-run/document on-call (history + Ctrl+R) |
| 02 | The Shell              | 8  | ✅ **built** - provision a fresh box (zsh default, aliases, theme) |
| 03 | Linux Commands         | 9  | ✅ **built** - on-call discovery loop (apropos→which→man→run) |
| 04 | The Linux File System  | 10 | ✅ **built** - navigate + know the FHS (configs/logs/bins) |
| 05 | Working with Files     | 11 | ✅ **built** - triage a crashed service's file dump |
| 06 | Working with Directories | 12 | ✅ **built** - structure & archive a release + `rm -rf` discipline |
| 07 | Users and Groups       | 14 | ✅ **built** - onboard a team, grant sudo, then offboard |
| 08 | File Permissions       | 15 | ✅ **built** - fix a broken handed-off service |

> Numbering matches the order above for a clean standalone repo; each README notes
> its course section. **Status: all 8 sections complete, every exercise tested
> end-to-end in the container (before → fail, after → pass).**

## The 3-tier model

Each section ramps the same way:

1. **Warm-up** - one command, build muscle memory
2. **Core** - combine commands to finish a realistic task
3. **Challenge** - a real DevOps scenario that mirrors actual work

## Where this sits in the DevOps path

```
Linux Fundamentals (you are here)
  → Linux for Professionals (pipes, env vars, SSH, networking)
  → Shell Scripting (automation)
  → Git → Docker → CI/CD (GitHub Actions) → AWS
```

# Amigoscode DevOps Exercises

Hands-on, **auto-graded** exercises for the Amigoscode DevOps track. Every exercise
runs inside a disposable Ubuntu container, so destructive commands are safe, the
environment is identical for everyone, and a script checks your work with instant
✅ / ❌ feedback.

The goal: take you from Linux beginner to the practical, day-to-day skills a
**DevOps engineer** relies on.

## New to Docker & make?

Two tools power these exercises - you don't need to know them deeply (you'll learn
both properly later in the track), just enough to run the commands:

- **Docker** packages a whole Linux environment into a disposable **container** - a
  mini Ubuntu machine that boots in seconds and throws away cleanly. Each exercise
  runs in one, so you can break things (even `rm -rf`) with zero risk to your real
  computer, and everyone gets the *exact same* environment.
- **make** is a tiny command runner. Instead of typing long Docker commands, you run
  short ones like `make start` or `make verify`, and `make` runs the real command for
  you (defined in each course's `Makefile`).

So `make start S=01-the-terminal` just means *"use Docker to spin up the Ubuntu
sandbox for this exercise and drop me into it."* In GitHub Codespaces both are
already installed - nothing to set up.

---

## 🚀 Getting started (your own copy + zero install)

You'll keep **your own copy** of these exercises, and still be able to pull in new
content whenever it's added.

### Step 1 - Fork it (your copy)

[**Fork this repository**](https://github.com/amigoscode/devops-exercises/fork) →
this creates `your-username/devops-exercises`, which is yours to keep.

### Step 2 - Open it in GitHub Codespaces (nothing to install)

On **your fork**: **Code → Codespaces → Create codespace on main**.

Wait ~1-2 min while it provisions Docker + `make` + the exercise image (handled by
the included [`.devcontainer`](.devcontainer/devcontainer.json)), then:

```bash
cd 01-linux-fundamentals
make start S=01-the-terminal     # pristine Ubuntu shell, scenario seeded
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=01-the-terminal    # grade your work
make reset S=01-the-terminal     # fresh start
```

### Step 3 - Get new exercises later (one click)

When new courses or fixes are published, open your fork on GitHub and click
**Sync fork → Update branch**. Because your work lives in a git-ignored `~/sandbox`,
updates merge cleanly - you never lose progress.

### 📓 Document your journey

The [`my-journey/`](my-journey/) folder is **yours** - log notes, commands and
takeaways as you go, then commit and push to your fork. Over time it becomes a
public **portfolio of your DevOps journey**. It's never touched by upstream syncs,
so it stays conflict-free.

## 💻 Prefer your own machine?

Clone **your fork** and run the same commands locally - you just need **Docker** and
**make** installed:

```bash
git clone https://github.com/YOUR-USERNAME/devops-exercises.git
cd devops-exercises/01-linux-fundamentals
make build                       # once
make start S=01-the-terminal     # enter a pristine Ubuntu shell, scenario seeded
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=01-the-terminal    # grade your work
make reset S=01-the-terminal     # fresh start
```

---

## Courses

| # | Course | Status |
|---|--------|--------|
| 01 | [Linux Fundamentals](01-linux-fundamentals/) | ✅ 8 sections, fully tested |
| 02 | [Vim](02-vim/) | ✅ 3 sections, fully tested |
| 03 | [Linux for Professionals](03-linux-for-professionals/) | ✅ 5 sections, fully tested |
| 04 | [Shell Scripting](04-shell-scripting/) | ✅ 5 sections, fully tested |
| 05 | [Git & GitHub Fundamentals](05-git-github-fundamentals/) | ✅ 4 sections, fully tested |
| 06 | [Docker for Professionals](06-docker/) | ✅ 6 sections + 3 capstones (full-stack, microservices, real-app review), fully tested |

More courses in the DevOps track (Git for Professionals, CI/CD, AWS) will be added
with the same format.

> The **Docker** course works a little differently: Docker itself is the subject, so
> you run `docker` commands directly in your terminal instead of dropping into a
> sandbox container. It also needs **no `make`** - it ships its own launcher and
> Docker is the only thing you install:
>
> ```bash
> ./course.sh verify 01-containers     # macOS/Linux/WSL - from this folder
> course.cmd  verify 01-containers     # Windows
> ./course.sh install                  # once: a `course` command that works anywhere
> ```
>
> Its [README](06-docker/) explains the rest. Everything else (fork, Codespaces,
> tiers, auto-grading) is identical.

## How the exercises work

- **One container per course, per-section seeds** - `make start S=<section>` drops
  you into a fresh Ubuntu shell with the scenario set up in `~/sandbox`.
- **Three tiers per section**: warm-up → core → a real DevOps challenge.
- **Auto-graded**: each section ships a `verify.sh` that scores your work.
- **Solutions included**: stuck? every section has a `solutions.md` - but try first.

## Repository layout

```
devops-exercises/
├── .devcontainer/            # Codespaces config (Docker-in-Docker + make)
├── my-journey/               # your notes & progress (commit to your fork)
├── 01-linux-fundamentals/    # a course (one folder per course)
│   ├── Dockerfile            # the shared Ubuntu exercise image
│   ├── Makefile              # make build / start / verify / reset / stop
│   └── NN-topic/             # each section: README, seed.sh, verify.sh, solutions.md
├── 02-vim/
└── 03-linux-for-professionals/
```

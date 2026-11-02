# Amigoscode Academy - Hands-On Exercises

Hands-on, **auto-graded** exercises for Amigoscode courses: Linux, Vim, shell
scripting, Git, Docker and SQL. Every exercise runs inside a disposable container,
so destructive commands are safe, the environment is identical for everyone, and a
script checks your work with instant ✅ / ❌ feedback.

The goal: take you from beginner to the practical, day-to-day skills a backend or
**DevOps engineer** relies on.

## ▶ Start here: the Academy

Everything happens in **one terminal app**: browse the courses, read each lesson,
open a real sandbox with one key, and get graded the moment you leave it. Your
progress is tracked for you.

```bash
./academy.sh        # macOS, Linux, WSL, Git Bash, GitHub Codespaces
academy.cmd         # Windows (PowerShell or Command Prompt)
```

**Docker is the only thing you install.** The first run builds the app (about a
minute); after that it starts instantly.

![Browse: courses on the left, sections on the right](academy/docs/home.png)

### How it works

1. **Pick a section** - courses on the left, their sections on the right. `↑↓` to
   move, `→` / `enter` to go in, `←` / `esc` to go back. `c` jumps straight to where
   you left off.
2. **Read the questions** - every question of the section is listed at the top. Move
   through them with `↑↓`; the panel underneath shows the selected one in full, with
   its scenario and hints.
3. **Press `enter`** - you drop into a fresh, disposable sandbox with the scenario
   already set up, and **the questions are printed right there**. Forgot one? Type
   `questions`. Want to see how you're doing? Type `check` - it grades your work on
   the spot without leaving. Break anything you like (even `rm -rf`) - it can't touch
   your machine.
4. **Type `exit` when you're done** - your work is checked instantly. Each question
   turns ✔ or ✘, the cursor jumps to the first one still open, and a ✘ tells you
   exactly what is missing.

![An exercise: questions on top, the selected question underneath](academy/docs/section.png)

| Key | Does |
|-----|------|
| `↑` `↓` | move - between courses, sections, or questions |
| `→` / `enter` | go in - and inside an exercise, open your sandbox |
| `←` / `esc` | go back |
| `v` | check your work again (it also runs when you exit the sandbox) |
| `check` | *inside the sandbox:* check your work without leaving |
| `questions` | *inside the sandbox:* print the questions again |
| `space` | tick off a drill you've practised (drills aren't auto-checked) |
| `l` | show the full lesson |
| `s` | show the solution - it asks you to try once more first |
| `n` / `p` | next / previous section |
| `?` | all keys |

Progress is saved to [`my-journey/progress.json`](my-journey/) - commit it to your
fork with your notes and it becomes part of your portfolio.

---

## 🚀 Getting started (your own copy + zero install)

You'll keep **your own copy** of these exercises, and still be able to pull in new
content whenever it's added.

### Step 1 - Fork it (your copy)

[**Fork this repository**](https://github.com/amigoscode/devops-exercises/fork) →
this creates `your-username/devops-exercises`, which is yours to keep.

### Step 2 - Open it in GitHub Codespaces (nothing to install)

On **your fork**: **Code → Codespaces → Create codespace on main**.

Wait ~1-2 min while it provisions Docker and pre-builds the Academy (handled by the
included [`.devcontainer`](.devcontainer/devcontainer.json)), then in the terminal:

```bash
./academy.sh
```

Prefer your own machine? Install [Docker](https://docs.docker.com/get-docker/), then:

```bash
git clone https://github.com/YOUR-USERNAME/devops-exercises.git
cd devops-exercises
./academy.sh          # Windows: academy.cmd
```

### Step 3 - Get new exercises later (one click)

When new courses or fixes are published, open your fork on GitHub and click
**Sync fork → Update branch**. Because your work lives in a git-ignored `~/sandbox`,
updates merge cleanly - you never lose progress. New sections appear in the Academy
automatically.

### 📓 Document your journey

The [`my-journey/`](my-journey/) folder is **yours** - log notes, commands and
takeaways as you go, then commit and push to your fork. Over time it becomes a
public **portfolio of your journey**. It's never touched by upstream syncs,
so it stays conflict-free.

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
| 07 | [Up and Running with SQL and Databases](07-up-and-running-with-sql/) | ✅ PostgreSQL, psql, databases and tables |
| 08 | [SQL and Databases Fundamentals](08-sql-fundamentals/) | ✅ queries, filtering, aggregates, joins |
| 09 | [Advanced Databases](09-advanced-databases/) | ✅ 10 sections: indexes, transactions, window functions, triggers, security |
| 10 | [Database Design & Implementation](10-database-design/) | ✅ modelling, normalization, design exercises |

More courses (Git for Professionals, CI/CD, AWS) will be added with the same format.

## How the exercises work

- **A disposable sandbox per section** - a fresh Ubuntu container with the scenario
  set up in `~/sandbox`. The **SQL** courses add a real PostgreSQL server and open
  straight in `psql`, connected to the section's database - no Linux needed. Save a
  query with `\w 1.1.sql`, type `:check` to grade it (`:questions` shows the questions
  again), and the grader runs it against an untouched copy of the data. The **Docker** course is the exception: Docker itself is the
  subject, so you run `docker` against your own daemon and the grader inspects the
  real containers, images and volumes you created.
- **Three tiers per section**: warm-up → core → a real-world challenge.
- **Auto-graded**: each section ships a `verify.sh` that scores your work.
- **Solutions included**: stuck? every section has a `solutions.md` - but try first.

## Docker course without the Academy

The Docker course also ships a standalone launcher (`./course.sh` / `course.cmd`) if
you'd rather type the commands yourself - see its [README](06-docker/).

## Repository layout

```
devops-exercises/
├── academy.sh / academy.cmd  # ▶ start here: the terminal app for every course
├── academy/                  # the Academy's source (Go + Charm), built in Docker
├── .devcontainer/            # Codespaces config (Docker-in-Docker, Academy pre-built)
├── my-journey/               # your notes & progress.json (commit to your fork)
├── 01-linux-fundamentals/    # a course (one folder per course)
│   ├── Dockerfile            # the shared Ubuntu exercise image
│   └── NN-topic/             # each section: README, seed.sh, verify.sh, solutions.md
├── 02-vim/
├── ...
├── 06-docker/                # host-Docker course: runner.sh + course.sh launchers
└── 07-10 SQL courses         # Ubuntu + PostgreSQL sandbox (Dockerfile per course)
```

Adding a course or section is just adding a folder in this shape - the Academy
discovers it on the next launch.

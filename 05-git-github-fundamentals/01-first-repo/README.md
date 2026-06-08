# 01 - Your First Repo

> Maps to **Git & GitHub Fundamentals -> Sections 4-6: git commands, your first repository, tracking changes**
> (`git config`, `git init`, `git add`, `git commit`, `git status`, `git log`)

Git is the version-control system the entire software world runs on. Every project,
every deploy, every collaboration starts here: configure git, create a repo, and
record your work as commits.

## How to use this set

```bash
make build                  # once
make start  S=01-first-repo
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=01-first-repo
make reset  S=01-first-repo
```

The grader inspects real git state (`git log`, `git status`), so you genuinely have
to drive git.

---

## Tier 1 - Set up *(hint: `git config --global ...`, then `git init`)*

**1.1 (graded)** Tell git who you are: set your **global** `user.name` and
`user.email`. (Git stamps every commit with these.)

**1.2 (graded)** Turn `~/sandbox/project` into a git repository.

## Tier 2 - Your first commit *(think: stage, then commit)*

**2.1 (graded)** Inside the repo, create a file (e.g. a `README.md`), **stage** it,
and **commit** it with a message.

## Tier 3 - Build some history *(goal only)*

**3.1 (graded)** Make a change (edit the file or add another), stage it, and create
a **second commit** - so the repo's history has two commits.

## Self-check questions

1. Why must you set `user.name`/`user.email` before committing?
2. What's the difference between the working directory, the staging area, and a commit?
3. What does `git log` show you?

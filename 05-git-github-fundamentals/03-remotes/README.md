# 03 - Remote Repositories

> Maps to **Git & GitHub Fundamentals -> Section 7: Remote Repositories**
> (`git remote add`, `git push`, `git clone`)

Commits live on your machine until you **push** them to a remote - GitHub, GitLab,
or any server. That's how code gets backed up and shared with a team. Here your
"remote" is a local bare repo (`~/sandbox/remote.git`) so everything works offline;
pushing to the real GitHub is a drill at the end.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Git & GitHub Fundamentals → Remote Repositories** and press `enter`. Inside the
sandbox, `questions` lists the tasks, `check` grades your work, and `exit` takes
you back with your progress saved. Press `r` in the Academy for a fresh start.

You have a repo at `~/sandbox/project` (one commit) and a remote at
`~/sandbox/remote.git`.

---

## Tier 1 - Link to a remote *(hint: `git remote add <name> <url>`)*

**1.1 (graded)** From inside `~/sandbox/project`, add a remote named **`origin`**
pointing at `~/sandbox/remote.git`.

## Tier 2 - Push *(think: send your branch up to origin)*

**2.1 (graded)** Push your commit(s) to the remote's **`main`** branch.

**2.2 (graded)** Make another commit, then push it too - the remote should end up
with at least two commits.

## Tier 3 - Clone *(goal only)*

**3.1 (graded)** Clone the remote into a fresh directory `~/sandbox/clone` and
confirm the files came across.

## 💪 Drill (self-check - needs a GitHub account)

Do this on your own machine, not in the sandbox (it has no SSH client, and its
`origin` already points at `remote.git`). Create a repo on GitHub, then point a
real project of yours at it and push:
```bash
git remote add origin git@github.com:<you>/<repo>.git
git push -u origin main
```

## Self-check questions

1. What does `origin` refer to, and is the name special?
2. What does `git push -u origin main` do (and what's the `-u` for)?
3. How is `git clone` different from `git init`?

# 03 - Remote Repositories

> Maps to **Git & GitHub Fundamentals -> Section 7: Remote Repositories**
> (`git remote add`, `git push`, `git clone`)

Commits live on your machine until you **push** them to a remote - GitHub, GitLab,
or any server. That's how code gets backed up and shared with a team. Here your
"remote" is a local bare repo (`~/sandbox/remote.git`) so everything works offline;
pushing to the real GitHub is a drill at the end.

## How to use this set

```bash
make start  S=03-remotes
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=03-remotes
make reset  S=03-remotes
```

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

Create a repo on GitHub, then point your real project at it and push:
```bash
git remote add origin git@github.com:<you>/<repo>.git
git push -u origin main
```

## Self-check questions

1. What does `origin` refer to, and is the name special?
2. What does `git push -u origin main` do (and what's the `-u` for)?
3. How is `git clone` different from `git init`?

# 02 - Tracking Changes

> Maps to **Git & GitHub Fundamentals -> Section 6: Tracking Changes**
> (`git status`, `git add`, `git rm --cached`, `git diff`, `git log`)

The thing that confuses every git beginner is the **staging area** - the middle
step between your files and a commit. Master it and git stops feeling like magic.
Work inside `~/sandbox/project` (it already has one commit).

## How to use this set

```bash
make start  S=02-tracking-changes
make verify S=02-tracking-changes
make reset  S=02-tracking-changes
```

---

## Tier 1 - The staging area *(hint: `git add` stages, `git rm --cached` unstages)*

**1.1 (graded)** There's an untracked file `a.txt`. **Stage** it (add it to the
index) - but don't commit yet.

**1.2 (graded)** The file `b.txt` is already staged. **Unstage** it so it goes back
to untracked - without deleting the file from disk.

## Tier 2 - See your changes *(think: which command shows what changed)*

**2.1 (graded)** Edit `tracked.txt` (add a line). Then capture the difference
between your working copy and the last commit into `~/sandbox/changes.diff`.

## Tier 3 - Inspect history *(goal only)*

**3.1 (graded)** Save the repository's commit history to `~/sandbox/history.txt`
(it should include the original `initial` commit).

## Self-check questions

1. What's the difference between an untracked, a staged, and a committed file?
2. How do you unstage a file without losing your changes?
3. `git diff` with no arguments - what is it comparing?

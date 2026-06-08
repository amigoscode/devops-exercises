# 04 - Capstone: Zero to Pushed

> The graduation mission. No new commands - it strings together everything from
> this course: `init`, `add`, `commit`, `remote add`, `push`.

You've been handed an empty folder. Take it all the way to a version-controlled
project pushed to a remote - the exact loop you'll run when starting any new repo.

## How to use this set

```bash
make start  S=04-capstone
make verify S=04-capstone
make reset  S=04-capstone
```

You have an empty project at `~/sandbox/myapp` and an empty remote at
`~/sandbox/origin.git`.

---

## The mission (4 objectives)

1. **(graded)** Turn `~/sandbox/myapp` into a git repo, add a file, and make the
   **first commit**.
2. **(graded)** Add another file (or change one) and make a **second commit**.
3. **(graded)** Link the repo to the remote `~/sandbox/origin.git` as **`origin`**.
4. **(graded)** **Push** your `main` branch so both commits land on the remote.

When `make verify` shows **4/4**, you've done the full new-project git workflow.

## Self-check

- Could you now do this for a real project and push it to GitHub? (That's just
  swapping the local remote path for a `git@github.com:...` URL.)

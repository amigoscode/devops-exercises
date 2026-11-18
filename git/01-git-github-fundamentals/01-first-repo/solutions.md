# Solutions - Your First Repo

## Tier 1
**1.1** Configure your identity (once, globally):
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

**1.2** Initialise the repo:
```bash
cd ~/sandbox/project
git init
```

## Tier 2
**2.1** Create, stage, commit:
```bash
echo "# My Project" > README.md
git add README.md
git commit -m "Add README"
```

## Tier 3
**3.1** Change something, then commit again:
```bash
echo "Now with details." >> README.md
git add README.md
git commit -m "Expand README"
git log --oneline        # two commits
```

### Answers
1. Git records the author of every commit using `user.name`/`user.email`; without
   them it refuses (or can't attribute) the commit.
2. **Working directory** = your files as they are now; **staging area (index)** =
   the snapshot you've marked with `git add` to go into the next commit; **commit** =
   a permanent, named snapshot saved in history.
3. `git log` shows the commit history - hashes, authors, dates and messages.

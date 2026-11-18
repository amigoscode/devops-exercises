# Solutions - Remote Repositories

Commands run inside `~/sandbox/project` unless noted.

## Tier 1
**1.1** Link your local repo to the remote:
```bash
git remote add origin ~/sandbox/remote.git
git remote -v            # shows origin (fetch + push)
```

## Tier 2
**2.1** Push the current branch and set it to track origin:
```bash
git push -u origin main
```

**2.2** Commit something new, then push again:
```bash
echo "more" >> app.txt
git add app.txt && git commit -m "update app"
git push                 # -u already set, so just 'git push'
```

## Tier 3
**3.1** Clone the remote into a new folder:
```bash
git clone ~/sandbox/remote.git ~/sandbox/clone
ls ~/sandbox/clone       # app.txt is there
```

### Answers
1. `origin` is the conventional name for your main remote - it's just a label, you
   could call it anything, but everyone uses `origin`.
2. It uploads your `main` branch to `origin`; `-u` sets the upstream so future
   `git push`/`git pull` need no arguments.
3. `git init` starts a brand-new empty repo; `git clone` copies an existing remote
   repo (history and all) onto your machine.

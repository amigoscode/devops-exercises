# Solutions - Tracking Changes

All commands run inside `~/sandbox/project`.

## Tier 1
**1.1** Stage the untracked file:
```bash
git add a.txt
git status            # a.txt now under "Changes to be committed"
```

**1.2** Unstage (keep the file):
```bash
git rm --cached b.txt
git status            # b.txt back to "Untracked files"; ls still shows it
```

## Tier 2
**2.1** Edit, then diff:
```bash
echo "v2" >> tracked.txt
git diff > ~/sandbox/changes.diff     # shows the +v2 line vs the last commit
```

## Tier 3
**3.1** Save the history:
```bash
git log > ~/sandbox/history.txt       # or: git log --oneline > ...
```

### Answers
1. **Untracked** = git isn't watching it yet; **staged** = marked (with `git add`)
   to go in the next commit; **committed** = saved into history.
2. `git rm --cached <file>` removes it from the index but leaves the file on disk.
3. Plain `git diff` compares your **working directory** against the **staged**
   version (what's in the index) - i.e. changes you haven't staged yet.

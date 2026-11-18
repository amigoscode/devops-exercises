# Solutions - Working with Files

## Tier 1

**1.1**
```bash
touch ~/sandbox/empty.txt                  # empty file
echo "deploy complete" > ~/sandbox/status.txt   # > writes (overwrites) content
```

**1.2** `cat` con**cat**enates its arguments in order:
```bash
cat ~/sandbox/part1.txt ~/sandbox/part2.txt > ~/sandbox/full.txt
```

**1.3 (drill)** No answer to check - `less` is interactive. Get comfortable with
`space`/`b`/`G`/`g`, `/search` + `n`, and `q` to quit.

## Tier 2

**2.1**
```bash
cp ~/sandbox/app.conf ~/sandbox/app.conf.bak
```

**2.2** One `mv` renames *and* moves:
```bash
mv ~/sandbox/draft.txt ~/sandbox/docs/release-notes.md
```

**2.3** The `*` wildcard expands to every matching file:
```bash
mv ~/sandbox/*.log ~/sandbox/logs/
```

## Tier 3

**3.1** You can pass several targets (and wildcards) to one `rm`:
```bash
rm ~/sandbox/dump/*.tmp ~/sandbox/dump/core.dump
# tip: ls the wildcard first to see what it'll hit:  ls ~/sandbox/dump/*.tmp
```

**3.2** Archive just the logs:
```bash
cd ~/sandbox/dump
zip ~/sandbox/logs.zip *.log      # stores app.log, error.log, access.log
```

**3.3** Verify by extracting into a fresh folder:
```bash
unzip ~/sandbox/logs.zip -d ~/sandbox/check
ls ~/sandbox/check                # the three logs should be there
```

### Answers to the self-check

1. `>` redirects a command's **output** into a file (overwriting it). `cp`
   duplicates an existing **file**. Different tools, different jobs.
2. `mv` **moves** a file to another location **and/or renames** it (same command).
3. `rm -r -f`: **-r** recurse into directories, **-f** force (no prompts). Together
   they delete a folder and everything in it, no questions asked.
4. A corrupt or empty archive looks fine until someone needs it. Extracting into a
   throwaway folder proves the contents are really there before you rely on it.

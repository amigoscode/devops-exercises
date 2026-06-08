# Solutions - Linux Commands

The skill here is *finding* the answer. The commands below are the destination;
the journey (man / --help / apropos) is the point.

## Tier 1

**1.1** Find the "all files" flag. `ls --help | grep -i hidden` or `man ls` →
it's `-a` (or `--all`):
```bash
ls -a ~/sandbox/files > ~/sandbox/hidden.txt
```

**1.2** `date --help` shows format sequences. `%F` is the shortcut for
`%Y-%m-%d`:
```bash
date +%F > ~/sandbox/today.txt          # e.g. 2026-06-05
# equivalently: date +%Y-%m-%d
```

## Tier 2

**2.1** Search man-page descriptions by keyword:
```bash
apropos "space usage" > ~/sandbox/apropos-space.txt
# the line:  du (1)  - estimate file space usage
```

**2.2** Locate the program:
```bash
which du > ~/sandbox/where-is-du.txt     # /usr/bin/du
```

**2.3** `man ls` → the long-listing flag is `-l`:
```bash
ls -l ~/sandbox/files > ~/sandbox/long.txt   # shows permissions, owner, size per file
```

## Tier 3

**3.1** Append the toolkit to `~/.zshrc`:
```bash
cat >> ~/.zshrc <<'EOF'
alias gl='git log --oneline'
alias dps='docker ps'
alias kgp='kubectl get pods'
EOF
```
Check: `zsh -ic 'alias gl'` → `gl='git log --oneline'`.

**3.2** The full discovery loop, ending in action:
```bash
apropos "space usage"        # find it -> du
which du                     # confirm it -> /usr/bin/du
man du | grep -A1 human      # read it -> -h / --human-readable, -s for summary
du -sh ~/sandbox/files > ~/sandbox/disk-report.txt
```

### Answers to the self-check

1. `command --help` (fastest), `man command` (fullest), `apropos keyword` (when
   you don't even know the command's name).
2. `apropos` finds a command **by what it does**; `which` tells you **where an
   already-known command lives**.
3. In `bin` directories like `/usr/bin` - `bin` = **binaries** (compiled programs).
4. In `~/.zshrc` (or `~/.bashrc` for bash) - files sourced for every new shell.

# Solutions - The Linux File System

## Tier 1

**1.1**
```bash
cd /
pwd > ~/sandbox/root.txt        # "/"
```

**1.2** `$HOME` always expands to your home directory:
```bash
echo $HOME > ~/sandbox/home.txt # /home/student
```

**1.3**
```bash
tree -L 1 / > ~/sandbox/tree.txt
```
`-L 1` limits the depth to one level, so you see `/`'s immediate children
(`bin etc home usr var ...`).

## Tier 2

**2.1**
```bash
cd /tmp
touch student-was-here.txt
```
Because `/tmp` is now your working directory, `touch` creates the file *there* -
that's how the grader knows you navigated correctly.

**2.2**
```bash
cd ~/sandbox/a/b/c/d
cd ../..            # d -> c is one ..; c -> b is two. You're now in a/b
touch here.txt
```
Each `..` goes up one level. `../..` goes up two - landing in `a/b`.

**2.3**
```bash
ls /etc > ~/sandbox/etc-listing.txt
```
An absolute path (starts with `/`) works from anywhere - no `cd` needed.

## Tier 3

**3.1** The standard locations:
```text
/etc
/var/log
/root
/tmp
```
Write them into the file:
```bash
printf '/etc\n/var/log\n/root\n/tmp\n' > ~/sandbox/fhs.txt
```

**3.2**
```bash
cd /var/log
pwd > ~/sandbox/at-logs.txt     # /var/log
```

### Answers to the self-check

1. **Absolute** starts at `/` and works from anywhere; **relative** is interpreted
   from your current directory (`..` = parent).
2. `cd`, `cd ~`, `cd $HOME` (also `cd` with no args).
3. configs → `/etc`, logs → `/var/log`, binaries → `/usr/bin` (and `/bin`), temp →
   `/tmp`.
4. `cd -` jumps back to the **previous** directory you were in - great for
   bouncing between two locations.

---

## Quick reference

| Goal | Command |
|------|---------|
| Go to root | `cd /` |
| Go home | `cd` or `cd ~` |
| Up one / two | `cd ..` / `cd ../..` |
| Toggle previous dir | `cd -` |
| Where am I | `pwd` |
| Home path variable | `echo $HOME` |

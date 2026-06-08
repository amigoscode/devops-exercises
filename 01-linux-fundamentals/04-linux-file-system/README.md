# 04 · The Linux File System

> Maps to **Linux Fundamentals → Section 10: The Linux File System**
> (the `/` tree, `cd`, `pwd`, `~`/`$HOME`, `..`, `cd -`, absolute vs relative paths, `tree`)

Everything in Linux hangs off a single tree starting at `/`. A DevOps engineer
SSHes into an unfamiliar server and instantly knows where to look - configs in
`/etc`, logs in `/var/log`, binaries in `/usr/bin`. This set makes that map second
nature and your navigation automatic.

## How to use this set

```bash
# from the linux-fundamentals/ folder
make build                          # once
make start  S=04-linux-file-system  # pristine Ubuntu shell, sandbox seeded
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=04-linux-file-system  # grades your work
make reset  S=04-linux-file-system  # fresh start
```

---

## Tier 1 - Orient yourself

**1.1 (graded)** Go to the very top of the filesystem and record where you are into
`~/sandbox/root.txt`. *(Hint: `cd` there, then capture `pwd`.)*

**1.2 (graded)** Capture your home directory path into `~/sandbox/home.txt` - but use
the environment **variable**, don't type the path out.

**1.3 (graded)** Map just the **top level** of the filesystem tree into
`~/sandbox/tree.txt`. *(Hint: the `tree` command has a depth flag.)*

## Tier 2 - Navigate *(think: relative `..` vs absolute paths)*

**2.1 (graded)** Navigate into the temp directory and leave a marker file there
called `student-was-here.txt` (the file proves you were standing in `/tmp`).

**2.2 (graded)** A deep path exists at `~/sandbox/a/b/c/d`. Go into it, then climb
**exactly two levels up using relative `..`** (no absolute paths), and create a
marker `here.txt` where you land (it should end up in `~/sandbox/a/b`).

**2.3 (graded)** Without `cd`-ing anywhere, list the contents of `/etc` by
**absolute path** and save it to `~/sandbox/etc-listing.txt`.

## Tier 3 - Know the standard layout (FHS) *(goal only)*

> Real ops knowledge: the **Filesystem Hierarchy Standard** is where every Linux
> distro keeps things. If you don't know these, you can't operate a server.

**3.1 (graded)** Write the standard **absolute path** for each, one per line, into
`~/sandbox/fhs.txt`:
- system-wide configuration files
- system log files
- the superuser's home directory
- temporary files (wiped on reboot)

**3.2 (graded)** Navigate to the log directory you just identified, and prove you
arrived by capturing `pwd` into `~/sandbox/at-logs.txt`.

When it's green, you can drop onto any box and head straight to what you need.

---

## Self-check questions

1. What's the difference between an **absolute** path (`/var/log`) and a
   **relative** one (`../log`)?
2. Three ways to get back to your home directory?
3. Which directory holds: configs? logs? binaries? temp files?
4. What does `cd -` do, and when is it handy?

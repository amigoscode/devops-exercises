# 03 · Linux Commands

> Maps to **Linux Fundamentals → Section 9: Linux Commands**
> (command = name + options + arguments, `man`, `--help`, `apropos`, `which`, aliases, programs & binaries)

Nobody memorises every flag - not even senior engineers. What separates a DevOps
engineer from a beginner is **how fast they find the answer**: `man`, `--help`,
`apropos`, `which`. Master *finding* and you've mastered the whole command line.

> Every command is `name [options] [arguments]`, e.g. `ls -a ~/sandbox` →
> `ls` is the command, `-a` an option, `~/sandbox` an argument. Options come in
> short (`-a`) and long (`--all`) forms.

## How to use this set

```bash
# from the linux-fundamentals/ folder
make build                          # once (rebuilds with man pages restored)
make start  S=03-linux-commands     # pristine Ubuntu shell, sandbox seeded
make verify S=03-linux-commands     # grades your work
make reset  S=03-linux-commands     # fresh start
```

---

## Tier 1 - Commands have structure

**1.1 (graded)** There's a hidden file in `~/sandbox/files`. Find the `ls` flag that
reveals hidden files (use `ls --help` or `man ls`), then save a listing that
includes it to `~/sandbox/hidden.txt` (the `.secret` file must appear).

**1.2 (graded)** Read `date --help` and use it to write **today's** date, formatted
as `YYYY-MM-DD`, into `~/sandbox/today.txt`.

## Tier 2 - The art of finding help *(hint: `apropos`, `which`, `man`)*

**2.1 (graded)** You need a tool to measure disk usage but don't know its name.
Search by *description* with `apropos` and save the result to
`~/sandbox/apropos-space.txt` (the `du` line should be in there).

**2.2 (graded)** Now find **where that program lives** on disk and save the path to
`~/sandbox/where-is-du.txt`.

**2.3 (graded)** Use `man ls` (or `--help`) to find the flag for a **long listing**
(permissions, owner, size). Run it on `~/sandbox/files` and save the output to
`~/sandbox/long.txt`.

## Tier 3 - Challenge: build your toolkit + on-call discovery *(goal only)*

**3.1 (graded)** Add the aliases you'll use every day to `~/.zshrc` so they resolve
in zsh: `gl` → `git log --oneline`, `dps` → `docker ps`, `kgp` → `kubectl get pods`.

**3.2 (graded)** > **Scenario:** an alert says `/` is filling up. Chain the
help-tools you just learned - find the command that measures disk usage, confirm
where it lives, read its flags - then produce a **one-line, human-readable** usage
report of `~/sandbox/files` into `~/sandbox/disk-report.txt`.

When it's all green, you've done the core loop of real Linux work: *I don't know
the command → I found it → I know where it lives → I read how to use it → I used it.*

---

## Self-check questions

1. You forget how a command works. Name three ways to get help, fastest first.
2. `apropos` vs `which` - when do you reach for each?
3. Where do most commands physically live, and what does `bin` stand for?
4. Where do your custom aliases need to go to survive a new shell session?

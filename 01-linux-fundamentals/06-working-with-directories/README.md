# 06 · Working with Directories

> Maps to **Linux Fundamentals → Section 12: Working with Directories**
> (`mkdir`, `mkdir -p`, `rmdir`, `rm -rf`, the **very dangerous command**, `zip -r`, spaces in names)

Directories are how you structure a deploy, a build, a release. This set teaches
you to create nested trees in one shot, delete them safely, archive them - and to
respect the single most destructive command in Linux.

> 🛡️ Everything runs in a throwaway container, so you can practise `rm -rf`
> **fearlessly**. That safety is exactly why this platform is containerised - on a
> real machine one wrong `rm -rf` has no undo.

## How to use this set

```bash
# from the linux-fundamentals/ folder
make build                              # once
make start  S=06-working-with-directories
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=06-working-with-directories
make reset  S=06-working-with-directories
```

---

## Tier 1 - Create dirs

**1.1 (graded)** Make a single directory `~/sandbox/builds`, and the nested tree
`~/sandbox/app/src/main` **in one command**. *(Hint: `mkdir` has a flag that creates
missing parents.)*

**1.2 (graded)** Remove the empty directory `~/sandbox/old-empty`. Then try the same
on `~/sandbox/has-stuff` and watch it refuse (leave that one alone). *(Hint: `rmdir`
only removes empty dirs.)*

## Tier 2 - Remove dirs (and respect the danger) *(think: `rm` recursively)*

**2.1 (graded)** Delete the whole directory `~/sandbox/temp-build` and everything
inside it.

**2.2 (graded)** Empty `~/sandbox/cache` of its contents but **keep the folder
itself**.

**2.3 (graded - knowledge)** There is one command that wipes an entire Linux system
with no recovery - you should **never** run it. Prove you know which one by writing
it into `~/sandbox/danger.txt` (writing it is safe; running it is not). *(It's `rm`,
recursive + forced, as root, against the filesystem root.)*

## Tier 3 - Challenge: structure & archive a release *(goal only)*

> **Scenario:** ship a clean release directory the way a deploy pipeline expects,
> archive it for distribution, and tidy up a folder a colleague misnamed.

**3.1 (graded)** Build the tree `~/sandbox/release/v2/` with three sub-dirs `bin`,
`config` and `logs`, and add a `VERSION` file (containing `2.0`) inside `v2`.

**3.2 (graded)** Archive the whole `release` directory **recursively** into
`~/sandbox/release-v2.zip`.

**3.3 (graded)** A colleague left a folder literally named `old releases` (with a
space). Rename it to `archived-releases` - mind the space.

All green = you can manage real release directories end to end.

---

## Self-check questions

1. `rmdir` vs `rm -rf` - when does each apply?
2. What does `mkdir -p` do that `mkdir` won't?
3. Why is `rm -rf /` catastrophic, and what protects you while practising here?
4. Two ways to handle a space in a directory name?

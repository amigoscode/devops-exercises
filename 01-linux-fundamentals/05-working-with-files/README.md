# 05 · Working with Files

> Maps to **Linux Fundamentals → Section 11: Working with Files**
> (`touch`, `echo >`, `cat`, `less`, `cp`, `mv`, `rm`, `zip`/`unzip`, wildcards `*`)

This is the bread and butter of every day in ops: creating, reading, copying,
moving, renaming, deleting, and archiving files. By the end you'll clean up a
messy server directory the way an engineer does after a bad deploy - fast and
without fear.

## How to use this set

```bash
# from the linux-fundamentals/ folder
make build                          # once
make start  S=05-working-with-files # pristine Ubuntu shell, sandbox seeded
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=05-working-with-files # grades your work
make reset  S=05-working-with-files # fresh start
```

---

## Tier 1 - Create & read

**1.1 (graded)** Create an **empty** file `~/sandbox/empty.txt`, and a separate file
`~/sandbox/status.txt` containing the line `deploy complete`. *(Hint: `touch` makes
an empty file; `echo` + `>` writes content.)*

**1.2 (graded)** `cat` actually means *concatenate*. Join `part1.txt` and `part2.txt`
(in that order) into a single file `~/sandbox/full.txt`.

**1.3 (drill)** Read `full.txt` a page at a time with `less` and practise the moves:
`space`/`b` to page, `G`/`g` for end/top, `/text` + `n` to search, `q` to quit.

## Tier 2 - Copy, move, rename *(hint: `cp`, `mv`, and `*` wildcards)*

**2.1 (graded)** Always back up a config before touching it: make a copy of
`app.conf` called `app.conf.bak` (same directory).

**2.2 (graded)** `mv` both renames and moves in one step. Turn `~/sandbox/draft.txt`
into `~/sandbox/docs/release-notes.md` (the original should no longer exist).

**2.3 (graded)** Sweep **every** loose `.log` file in `~/sandbox` into the `logs/`
folder using a wildcard.

## Tier 3 - Challenge: triage the dump *(goal only)*

> **Scenario:** a service crashed and dumped a pile of files into `~/sandbox/dump`
> - logs, a core dump, scratch `.tmp` files, a README and a config. Clean it up
> and hand the logs to your team.

**3.1 (graded)** Delete the junk - every `.tmp` file **and** the `core.dump` -
while keeping the logs, the README and the yaml.

**3.2 (graded)** Archive just the `.log` files from `dump/` into a single
`~/sandbox/logs.zip` so you can send them.

**3.3 (graded)** Never trust an archive you didn't verify - extract `logs.zip` into a
fresh folder `~/sandbox/check` and confirm the logs are really there.

All green = you just did real post-incident cleanup.

---

## ⚠️ A word on `rm`

`rm` does **not** use a trash can - deleted is deleted. Wildcards make it powerful
*and* dangerous: `rm *.tmp` is handy, but the next section covers the one command
you must never run. Always `ls` your wildcard first to see what it matches.

## Self-check questions

1. Difference between `>` and the `cp` command for "copying" content?
2. `mv` does two jobs - what are they?
3. What does `rm -rf` mean, letter by letter?
4. Why `zip` then `unzip -d somewhere` to *verify*, instead of trusting it?

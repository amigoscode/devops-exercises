# 01 · Redirection & Pipes

> Maps to **Linux for Professionals → Section 17: Data Redirection & Manipulation**
> (`>`, `>>`, `2>`, `&>`, `<`, `|`, `grep`, `wc`, `sort`, `find`)

This is the single most powerful idea in Linux: small commands, connected. Redirect
output to files, chain commands with pipes, and you can slice through logs and data
that would be impossible to handle by hand. It's what DevOps engineers do all day.

## How to use this set

```bash
# from the 03-linux-for-professionals/ folder
make build                              # once
make start  S=01-redirection-and-pipes
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=01-redirection-and-pipes
make reset  S=01-redirection-and-pipes
```

---

## Tier 1 - Redirect streams *(hint: the `>`, `>>` and `2>` operators)*

**1.1 (graded)** Save the output of listing `/etc` into `~/sandbox/etc.txt`.

**1.2 (graded)** Build `~/sandbox/deploy.log` with two lines - first
`Deploy started`, then `Deploy finished` - where the second is **appended**, not
overwriting the first. (One operator overwrites, another appends.)

**1.3 (graded)** Run a command that fails (e.g. listing a directory that doesn't
exist) and capture **only its error message** into `~/sandbox/err.txt`.

## Tier 2 - Pipe & filter *(think: chain commands with `|`)*

**2.1 (graded)** From `access.log`, keep **only the lines containing `ERROR`** and
save them to `~/sandbox/errors.txt`.

**2.2 (graded)** Count how many `GET` requests are in `access.log`; save just the
number to `~/sandbox/get-count.txt`.

**2.3 (graded)** Sort `names.txt` into `~/sandbox/sorted.txt` - but feed the file in
as **standard input** (the `<` operator), not as an argument.

## Tier 3 - Challenge: log triage *(goal only - you build the pipelines)*

> **Scenario:** several services dropped logs in `~/sandbox/logs/`. Find them,
> count the errors, and produce a sorted error report.

**3.1 (graded)** Produce `~/sandbox/found.txt` listing every `.log` file anywhere
under `~/sandbox/logs`.

**3.2 (graded)** Count the **total** number of ERROR lines across all those logs;
save the number to `~/sandbox/error-count.txt`.

**3.3 (graded)** Collect **every** ERROR line from all the logs, **sorted**, into
`~/sandbox/errors-sorted.txt`.

All green = you can carve answers out of raw logs - a core DevOps superpower.

## Self-check questions

1. Difference between `>` and `>>`?
2. How do you save a command's **errors** separately from its output?
3. What does `cat x | grep y | wc -l` count?
4. Why are pipes more powerful than running each command separately?

# 01 · Bash Basics

> Maps to **Shell Scripting → Section 1: Introduction to Bash**
> (shebang, run-from-anywhere, variables, parameters `$1`/`$@`, arithmetic expansion)

This is where commands become **automation**. A shell script is just a file of the
commands you already know, run top to bottom - the backbone of every deploy,
backup and CI job. Here you'll write your first scripts, parameterise them, and do
maths.

## How to use this set

```bash
# from the 04-shell-scripting/ folder
make build                       # once
make start  S=01-bash-basics     # shell with a clean ~/sandbox to write scripts in
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=01-bash-basics     # runs your scripts and grades them
make reset  S=01-bash-basics     # fresh start
```

The grader **runs your scripts**, so they have to actually work.

---

## Tier 1 - Your first scripts *(hint: `#!/bin/bash`, `chmod +x`, `$variable`)*

**1.1 (graded)** Write `~/sandbox/hello.sh` that prints `Hello, DevOps`. It must
start with a **shebang** and be **executable** (so `./hello.sh` runs it).

**1.2 (graded)** Write `~/sandbox/count.sh` that stores the number `3` in a
**variable** and uses it to print `Count is 3`.

## Tier 2 - Parameters & arithmetic *(think: `$1`, and `$(( ))` for maths)*

**2.1 (graded)** Write `~/sandbox/greet.sh` that greets the name passed as its
**first parameter** - e.g. `./greet.sh Sam` prints `Hello, Sam`.

**2.2 (graded)** Write `~/sandbox/add.sh` that takes **two numbers** as parameters
and prints their **sum** - e.g. `./add.sh 3 4` prints `7` (real addition, not
`34`).

## Tier 3 - Put it together *(goal only)*

**3.1 (graded)** Write `~/sandbox/rect.sh` that takes a **length** and a **width**
as parameters and prints both the **area** (length × width) and the **perimeter**
(2 × (length + width)). For `./rect.sh 5 8` that's area `40` and perimeter `26`.

## Self-check questions

1. What does the shebang line do, and why does the file need to be executable?
2. How do you read the first argument passed to a script? All arguments?
3. Why does `$((3 + 4))` give `7` but `"3 + 4"` doesn't?

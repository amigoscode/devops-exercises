# 02 · Conditions & Loops

> Maps to **Shell Scripting → Section 3: Conditions and Loops**
> (`if`/`elif`/`else`, comparison operators, `for`, `while`, `break`/`continue`)

Real scripts make decisions and repeat work - "if the disk is >90% full, alert",
"for every server, deploy". This is the control flow that turns a list of commands
into actual logic.

## How to use this set

```bash
make start  S=02-conditions-and-loops
make verify S=02-conditions-and-loops
make reset  S=02-conditions-and-loops
```

---

## Tier 1 - Decisions with `if` *(hint: `if [ $x -ge 18 ]; then … else … fi`)*

**1.1 (graded)** Write `~/sandbox/check.sh` that takes an age as its first
parameter and prints `adult` if it's **18 or more**, otherwise `minor`.

## Tier 2 - Loops *(think: `for` or `while` to repeat)*

**2.1 (graded)** Write `~/sandbox/countup.sh` that prints the numbers **1 to 5**
(using a loop, not five `echo`s).

**2.2 (graded)** Write `~/sandbox/sum.sh` that **adds up** every number from 1 to
its first parameter and prints the total - e.g. `./sum.sh 5` → `15`.

## Tier 3 - Loop + decision together *(goal only)*

**3.1 (graded)** Write `~/sandbox/sizes.sh` that loops from 1 to its first
parameter and, for each number, prints `small` if it's **3 or less** and `big`
otherwise. So `./sizes.sh 5` prints `small`, `small`, `small`, `big`, `big`.

## Self-check questions

1. What goes between `then` and `fi`, and what does the condition look like?
2. `-ge`, `-lt`, `-eq` - what do these comparison operators mean?
3. When would you reach for a `while` loop instead of a `for` loop?

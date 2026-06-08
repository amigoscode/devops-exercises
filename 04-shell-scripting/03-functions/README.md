# 03 · Functions

> Maps to **Shell Scripting → Section 4: Functions**
> (defining functions, parameters, local variables, reusable logic)

Functions turn a long script into named, reusable building blocks - `deploy`,
`rollback`, `notify`. Same idea as functions anywhere: define once, call many times,
pass in parameters.

## How to use this set

```bash
make start  S=03-functions
make verify S=03-functions
make reset  S=03-functions
```

---

## Tier 1 - Define & call *(hint: `name() { ... }`, then call it by `name`)*

**1.1 (graded)** Write `~/sandbox/hello-fn.sh` that **defines a function** which
prints `Hello from a function`, then **calls** it.

## Tier 2 - Functions with parameters *(think: inside a function, `$1` is its first arg)*

**2.1 (graded)** Write `~/sandbox/square.sh` with a function that takes a number and
prints its square. The script passes its own first parameter to the function - so
`./square.sh 6` prints `36`.

**2.2 (graded)** Write `~/sandbox/greet-fn.sh` with a function that takes a name and
prints `Hi, <name>`; the script passes `$1` to it - `./greet-fn.sh Sam` → `Hi, Sam`.

## Tier 3 - A function with its own logic *(goal only)*

**3.1 (graded)** Write `~/sandbox/maxof.sh` with a `max` function that takes **two**
numbers and prints the larger one (decide inside the function). The script passes
`$1` and `$2` - `./maxof.sh 3 8` → `8`.

## Self-check questions

1. What are the two ways to define a function in bash, and how do you call it?
2. Inside a function, how do you read the arguments it was called with?
3. Why use `local` for a variable inside a function?

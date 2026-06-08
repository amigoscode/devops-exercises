# 04 · Error Handling

> Maps to **Shell Scripting → Section 5: Error Handling**
> (exit codes, `$?`, `set -e`, `set -u`, `set -o pipefail`)

A script that fails silently is dangerous - it'll happily deploy half a release.
Production scripts **fail loudly and stop early**. This is the difference between a
toy script and one you'd trust in a pipeline.

## How to use this set

```bash
make start  S=04-error-handling
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=04-error-handling
make reset  S=04-error-handling
```

---

## Tier 1 - Exit codes *(hint: `exit N`)*

**1.1 (graded)** Write `~/sandbox/status.sh` that finishes with **exit code 42**.
(Every command returns a code - `0` means success, anything else is a failure.)

## Tier 2 - Strict mode & `$?` *(think: the safety preamble every script should have)*

**2.1 (graded)** Write `~/sandbox/safe.sh` that turns on **strict mode** - exit on
error, error on undefined variables, and fail a pipeline if any part fails - then
prints `running safely`.

**2.2 (graded)** Write `~/sandbox/report.sh` that runs a command which **fails**
(e.g. listing a directory that doesn't exist), then prints its exit code in the
form `exit code: 2`. *(Hint: the special variable that holds the last exit code.)*

## Tier 3 - Validate input like a real script *(goal only)*

**3.1 (graded)** Write `~/sandbox/deploy.sh` that:
- with **no argument**, prints a usage message and exits with a **non-zero** code;
- with an argument, prints `deploying <arg>` and exits successfully.

So `./deploy.sh` fails, and `./deploy.sh v1` prints `deploying v1`.

## Self-check questions

1. What does an exit code of `0` mean vs non-zero? How do you read the last one?
2. What do `set -e`, `set -u` and `set -o pipefail` each protect you from?
3. Why check for a missing argument before doing real work?

# 08 · File Permissions

> Maps to **Linux Fundamentals → Section 15: File Permissions**
> (`ls -l`, octal/symbolic notation, `chmod`, `chown`, `chgrp`)

Permissions are where Linux beginners get stuck and where DevOps engineers live.
A broken deploy is *very often* a permissions problem. By the end of this set you
should read `rwxr-xr--` at a glance and fix permission bugs without thinking.

---

## Learning objectives

- Read and interpret the 10-character permission string from `ls -l`
- Convert between **symbolic** (`rwx`) and **octal** (`755`) notation in your head
- Use `chmod` with both notations
- Use `chown` / `chgrp` to change ownership
- Diagnose and fix a real "permission denied" scenario

## How to use this set

Everything runs inside a disposable Ubuntu container, so destructive commands
(`rm -rf`, `chmod 000`, `chown root`) are completely safe - and you get real
Linux user tooling even on a Mac or Windows machine.

```bash
# from the linux-fundamentals/ folder
make build                            # once

make start  S=08-file-permissions     # drops you into Ubuntu, scenario seeded in ~/sandbox
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
# ...solve the exercises below...
make verify S=08-file-permissions     # ✅ / ❌ per task, instant feedback
make reset  S=08-file-permissions     # wipe and start fresh
make stop   S=08-file-permissions     # remove the container when done
```

Stuck? See `solutions.md` - but try first.

---

## Tier 1 - Warm-up *(hint: `chmod`, with symbolic `+`/`-`/`=` or octal)*

**1.1** Inside `sandbox/`, run `ls -l` and read who can write to `deploy.sh`. Then
make `deploy.sh` **executable by everyone**.

**1.2** `secret.env` is world-readable. Make it readable and writable **only by its
owner** - a secret should never be group- or world-readable.

**1.3** `notes.txt` should be **read-only for everyone**, including the owner.

## Tier 2 - Core *(work out the values yourself)*

**2.1** `app/run.sh` should be fully usable by its **owner** (read/write/execute),
read/execute for its **group**, and completely off-limits to **others**. Set it
using **octal** - work the number out before you type it.

**2.2** Give `app/config.yaml` the *same* effective permissions as 2.1 - but this
time using **symbolic** notation only.

**2.3** The `app/logs/` directory is wide open. Lock it down:
- the **directory** `app/logs` - owner can do everything, group can read + enter,
  others nothing (remember: a directory needs **execute** to be entered/listed)
- each **log file** inside - read/write for the owner, read-only for everyone else

> 💪 **Optional stretch (a tool taught later):** once you meet `find`, there's a
> one-liner to set every file at once. Not required here.

## Tier 3 - Challenge *(real DevOps scenario - figure out the fix)*

> **Scenario:** A teammate handed off a service. The startup script won't run,
> the app can't read its config, and a log file is owned by `root`.

**3.1** `service/start.sh` gives *Permission denied* when run with `./start.sh`.
Make it so the **owner can execute** it - and only the owner can write to it.

**3.2** `service/app.conf` is mode `000`. The service needs to **read** it (owner
and group); nobody should be able to write it.

**3.3** `service/app.log` is owned by `root:root`, so the service (running as you)
can't write to it. Make the **`student` user the owner**, then ensure the owner can
read and write. (Permissions and *ownership* are two different controls - and
reassigning a root-owned file needs elevated rights.)

When all three pass, you've done a real on-call permissions triage. 🎯

---

## Self-check questions (no terminal needed)

1. What octal is `rwxr-xr--`?  → `754`
2. What does `chmod a+x file` do that `chmod u+x file` doesn't?
3. Why does a *directory* need execute permission to be useful?
4. `chmod 644` on a shell script - can you run it with `./script.sh`? Why not?

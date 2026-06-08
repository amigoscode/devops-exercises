# 05 · Files & Automation

> Maps to **Shell Scripting → Sections 6-8: Environment Variables, File Operators, Sleep & Processes**
> (reading & writing files, checksums, `sleep`, and tying it all into a real script)

The payoff: scripts that touch the real system - write logs, read config, verify
downloads, and provision a whole directory layout in one command. This is what
"automation" actually looks like day to day.

## How to use this set

```bash
make start  S=05-files-and-automation
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=05-files-and-automation
make reset  S=05-files-and-automation
```

A couple of files (`names.txt`, `data.txt`) are seeded for you to work on.

---

## Tier 1 - Read & write files *(hint: `>` to write, a `while read` loop to read)*

**1.1 (graded)** Write `~/sandbox/writelog.sh` that writes the line
`deployment started` into `~/sandbox/deploy.log`.

**1.2 (graded)** Write `~/sandbox/readnames.sh` that reads `~/sandbox/names.txt`
**line by line** and prints each name prefixed with `- ` (so `alice` → `- alice`).

## Tier 2 - Checksums & timing *(think: `sha256sum`, and `sleep`)*

**2.1 (graded)** Write `~/sandbox/checksum.sh` that computes the **sha256 checksum**
of `~/sandbox/data.txt` and writes it to `~/sandbox/data.sha256`. (This is how you
verify a download wasn't corrupted or tampered with.)

**2.2 (graded)** Write `~/sandbox/timer.sh` that prints `start`, waits a moment,
then prints `done`.

## Tier 3 - A real provisioning script *(goal only - this is the whole course paying off)*

**3.1 (graded)** Write `~/sandbox/provision.sh` that sets up an app from scratch:
- create `~/sandbox/app` with sub-directories `bin`, `config` and `logs`
- write `1.0` into `~/sandbox/app/VERSION`
- print `provisioned` when it's done

Run it once and you've automated what used to take a dozen manual commands.

## Self-check questions

1. How do you append vs overwrite when writing to a file from a script?
2. What's a checksum for, and why would a deploy script verify one?
3. What makes a provisioning script better than running the commands by hand?

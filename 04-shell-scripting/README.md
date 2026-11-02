# Shell Scripting - Hands-On Exercises

Where the commands you've learned become **automation**. You'll write real bash
scripts - with variables, parameters, conditions, loops, functions and proper error
handling - and the grader **runs them** to check they actually work.

This is the course that turns "someone who knows Linux commands" into "someone who
automates Linux".

## Quick start

From the repo root:

```bash
./academy.sh        # macOS, Linux, WSL, Git Bash, Codespaces
academy.cmd         # Windows
```

Pick **Shell Scripting**, choose a section and press `enter`: you get a fresh Ubuntu
sandbox with the scenario already set up and the questions printed at the top.
Inside it, `questions` shows them again, `check` grades your work, and `exit`
takes you back with your progress saved.

**Docker is the only thing you need installed.** (Codespaces works too - zero install.)

## Sections

| # | Section | Course § | Skills |
|---|---------|----------|--------|
| 01 | [Bash Basics](01-bash-basics/) | 1 | shebang, `chmod +x`, variables, `$1`, `$(( ))` |
| 02 | [Conditions & Loops](02-conditions-and-loops/) | 3 | `if`/`elif`/`else`, `for`, `while` |
| 03 | [Functions](03-functions/) | 4 | defining/calling functions, params, `local` |
| 04 | [Error Handling](04-error-handling/) | 5 | exit codes, `$?`, `set -euo pipefail` |
| 05 | [Files & Automation](05-files-and-automation/) | 6-8 | read/write files, checksums, `sleep`, a provisioning script |

Each section: `README.md` (3-tier tasks) · `seed.sh` · `verify.sh` (runs your
scripts) · `solutions.md`.

## How grading works

Unlike a quiz, the grader **executes your scripts** with known inputs and checks the
output and exit codes - e.g. `add.sh 20 22` must print `42`, `deploy.sh` with no
argument must fail. So your scripts have to genuinely work, not just look right.
Stuck on the how? Each section's `solutions.md` has the full script.

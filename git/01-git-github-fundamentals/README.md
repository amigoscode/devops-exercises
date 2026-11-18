# Git & GitHub Fundamentals - Hands-On Exercises

Version control is the tool every engineer touches all day. Here you'll drive real
git - configure it, create repos, stage and commit, and push to a remote - all
auto-graded by inspecting actual git state.

Everything runs offline in a container: the "remote" is a local **bare repo**, so
you can push and clone without a GitHub account (real GitHub pushes are a drill).

## Quick start

From the repo root:

```bash
./academy.sh        # macOS, Linux, WSL, Git Bash, Codespaces
academy.cmd         # Windows
```

Pick **Git & GitHub Fundamentals**, choose a section and press `enter`: you get a fresh Ubuntu
sandbox with the scenario already set up and the questions printed at the top.
Inside it, `questions` shows them again, `check` grades your work, and `exit`
takes you back with your progress saved.

**Docker is the only thing you need installed.** (Codespaces works too - zero install.)

## Sections

| # | Section | Course § | Skills |
|---|---------|----------|--------|
| 01 | [Your First Repo](01-first-repo/) | 4-6 | `git config`, `init`, `add`, `commit`, `log` |
| 02 | [Tracking Changes](02-tracking-changes/) | 6 | staging area, `rm --cached`, `diff`, `log` |
| 03 | [Remote Repositories](03-remotes/) | 7 | `remote add`, `push`, `clone` (local bare remote) |
| 04 | [Capstone: Zero to Pushed](04-capstone/) | - | new project from empty folder to pushed |

Each section: `README.md` (3-tier tasks) · `seed.sh` · `verify.sh` · `solutions.md`.

## How grading works

The grader runs git commands against your repo (`git log`, `git status`,
`rev-list --count`) and the bare remote to check the real outcome - e.g. "the repo
has two commits", "origin points at the remote", "the push landed". So you have to
actually use git, not just know the commands. Stuck? Each `solutions.md` has the
full command sequence.

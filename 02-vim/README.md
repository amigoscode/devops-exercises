# Vim - Hands-On Exercises

Practice exercises for the **Vim** course. Vim is the editor that's on *every*
Linux server - when you SSH into a box to fix a config, Vim is what's there. These
exercises build real editing fluency, auto-graded inside a disposable container.

- 🐧 **Real Vim, real files** - edit in an actual terminal Vim, like on a server
- ✅ **Auto-graded** - the grader checks the file you produced
- 🔁 **Resettable** - `make reset` restores the starting files
- 🎯 **DevOps-flavoured** - every task is the kind of config edit you'll do for real

## Quick start

```bash
make build                              # build the Vim image once
make start  S=01-insert-and-save        # shell with files seeded; edit with vim
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=01-insert-and-save        # grade your edits
make reset  S=01-insert-and-save        # fresh start
```

You need **Docker** and **make** (both already provided in GitHub Codespaces).

## Sections

| # | Section | Skills |
|---|---------|--------|
| 01 | [Insert & Save](01-insert-and-save/) | modes, `i`/`o`, `:wq`, `:q!` |
| 02 | [Navigate & Edit](02-navigate-and-edit/) | `hjkl`, `gg`/`G`, `dd`, `yy`/`p`, `u` |
| 03 | [Search, Replace & .vimrc](03-search-replace-and-vimrc/) | `/`, `:%s/old/new/g`, `~/.vimrc` |

Each section: `README.md` (tasks) · `seed.sh` (starting files) · `verify.sh`
(auto-grader) · `solutions.md`.

## How grading works

Vim is interactive, so there's no way to grade keystrokes - instead each task asks
you to **transform a file**, and the grader checks the result. You genuinely have to
make the edits in Vim and save them. (Stuck on the keys? Each section's
`solutions.md` lists the exact sequence.)

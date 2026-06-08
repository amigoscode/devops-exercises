# 02 · The Shell

> Maps to **Linux Fundamentals → Section 8: The Shell**
> (`/etc/shells`, `echo $SHELL`, switching shells, `chsh`, zsh, `~/.zshrc`, themes, plugins, aliases)

The shell is the program that actually runs your commands (the terminal is just
the window around it). A DevOps engineer SSHes into dozens of machines - and the
first thing the good ones do is **make the shell theirs**: a better shell, the
aliases they live by, a config they can reproduce anywhere. That's this set.

## How to use this set

```bash
# from the linux-fundamentals/ folder
make build                       # once
make start  S=02-the-shell       # pristine Ubuntu shell (default shell reset to bash)
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
make verify S=02-the-shell       # grades your work
make reset  S=02-the-shell       # fresh start
```

> **Note on oh-my-zsh:** installing it needs internet (it git-clones from GitHub),
> so it's **not required** for grading. Everything graded here works with plain
> zsh. Installing oh-my-zsh is a labelled stretch at the end.

---

## Tier 1 - Discover the shells

**1.1 (graded)** Every installed login shell is listed in a single system file
(it's under `/etc`). Save that list to `~/sandbox/shells.txt`.

**1.2 (drill)** Switch into zsh by typing its name, check which shell you're now in,
then return to bash.

## Tier 2 - Configure your shell *(hint: `chsh`, and `~/.zshrc` for persistence)*

**2.1 (graded)** Make **zsh your default login shell**, so every new session starts
in zsh - not just when you type `zsh`.

**2.2 (graded)** Create `~/.zshrc` and add an alias `ll` that runs `ls -lah`. It must
actually load - the grader opens a zsh and checks `ll` resolves.

**2.3 (graded)** Pick a Zsh theme and set it in `~/.zshrc`.

## Tier 3 - Challenge: provision a fresh box *(goal only)*

> **Scenario:** You just landed on a brand-new server. Make it productive the way
> your team standardises every machine - zsh default (done in 2.1), the team's
> alias set, and the git plugin enabled.

**3.1 (graded)** Add your team's aliases to `~/.zshrc` so they resolve in zsh:
`gs` → `git status`, `k` → `kubectl get pods`, `dc` → `docker compose`.

**3.2 (graded)** Enable the **git plugin** in `~/.zshrc` (the plugins line oh-my-zsh
reads).

When it's all green, you've done what a DevOps engineer does on every new
machine - and you could commit this `.zshrc` to a dotfiles repo and reproduce it
anywhere.

---

## 💪 Optional stretch (needs internet) - install oh-my-zsh

The real framework that makes `.zshrc` themes and plugins come alive:
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
Then re-open zsh and watch your theme + git plugin activate. Not graded (CI has
no network), but do it on your own machine - it's the payoff for §8.

## Self-check questions

1. What's the difference between the **terminal** and the **shell**?
2. `echo $SHELL` vs typing `zsh` - why might they disagree right after you run `zsh`?
3. Where does zsh read its per-user config from?
4. Why set the default shell with `chsh` instead of just typing `zsh` each time?

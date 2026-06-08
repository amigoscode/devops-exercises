# 02 · Environment Variables

> Maps to **Linux for Professionals → Section 18: Environment Variables**
> (`export`, `$VAR`, `~/.bashrc` persistence, aliases, `PATH`, binaries)

Environment variables configure everything - secrets, app environments, where the
shell looks for commands. Knowing how to set them (and make them **persist**) is
day-one DevOps. The grader reads from a **fresh shell**, so everything here must be
saved in `~/.bashrc`, not just typed once.

## How to use this set

```bash
# from the 03-linux-for-professionals/ folder
make start  S=02-environment-variables
make verify S=02-environment-variables
make reset  S=02-environment-variables
```

> Set something, then `source ~/.bashrc` (or open a new shell) to load it.

---

## Tier 1 - Persistent environment variables *(hint: `export` in `~/.bashrc`, then reload)*

**1.1 (graded)** Set an environment variable `GREETING` to `hello world` so it
**survives new shell sessions** (not just the current one).

**1.2 (graded)** Add a second persistent variable, `APP_ENV`, set to `production`.

## Tier 2 - Aliases & PATH *(think: what makes settings stick + how the shell finds commands)*

**2.1 (graded)** Make a persistent alias `ll` that runs `ls -lah`.

**2.2 (graded)** Create a personal `~/bin` directory and get it onto your `PATH`
**persistently**, so any program placed there can be run from anywhere.

## Tier 3 - Challenge: make your own command *(goal only)*

> Because `~/bin` is on your `PATH`, anything executable you drop there becomes a
> command you can run from anywhere - exactly how you'd install a personal tool on
> a server.

**3.1 (graded)** Create an executable script `~/bin/greet` that prints exactly
`ready to deploy`, and make it runnable just by typing `greet` from any directory.

All green = you control your environment and how Linux resolves commands.

## Self-check questions

1. Why does a variable set with `export FOO=bar` vanish in a new terminal, and how
   do you make it stick?
2. What is `PATH` and what happens when you type a command?
3. You dropped a script in `~/bin` but `command not found` - what's likely wrong?

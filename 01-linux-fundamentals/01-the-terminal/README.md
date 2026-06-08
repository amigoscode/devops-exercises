# 01 · The Terminal

> Maps to **Linux Fundamentals → Section 7: The Terminal**
> (tab completion, command history, `Ctrl+R`, cursor movement, terminal control)

DevOps work happens in the terminal, on-call, under pressure. The engineers who
look like wizards aren't faster typists - they **never retype anything**. They
tab-complete, recall from history, and jump around a line with two keystrokes.
This set builds that fluency.

> **About the commands:** in this section the commands (`cd`, `echo`, `ls`,
> `grep`…) are just *props* - you learn them properly in later sections. So I
> give you the exact text to run. The thing you're practising is **controlling
> the terminal**, not the commands.

## How to use this set

```bash
# from the linux-fundamentals/ folder
make build                          # once
make start  S=01-the-terminal       # pristine Ubuntu shell, sandbox + history seeded
make verify S=01-the-terminal       # grades the auto-checkable tasks
make reset  S=01-the-terminal       # fresh start
```

Some tasks are **auto-graded** (✅/❌). The keyboard drills are **self-checked** -
there's no file to grade a keystroke, so you confirm those yourself.

---

## Tier 1 - Warm-up

**1.1 (drill)** Put junk on the screen (`ls -l`, then `ls -la`). Clear it two
ways: `Ctrl+L` (clears view, scrollback kept) then `clear` (wipes scrollback).
Notice the difference by scrolling up after each.

**1.2 (drill)** Start typing a long wrong command, then **abort it with
`Ctrl+C`** before pressing Enter. You should get a fresh prompt, nothing run.

**1.3 (graded)** A deep folder exists at
`~/sandbox/srv/var/log/nginx-application-server`. **Using only TAB completion**
(type a few letters and let Tab build each part of the path), `cd` into it and
create a file called `checked.txt`.

## Tier 2 - Core (history is the superpower)

**2.1 (graded)** Run these three commands as-is:
```bash
echo "step-1-build"
echo "step-2-test"
echo "step-3-deploy"
```
Then **save your shell history** to `~/sandbox/session.log`. *(Hint: the `history`
command, redirected to a file.)*

**2.2 (graded)** We planted a command in your history. **Without retyping it**, use
reverse-search (`Ctrl+R`) to find it - try the fragment `ctrl-r` - and run it. It
writes a file, which is how we know you found it.

## Tier 3 - Challenge (real on-call fluency)

> **Scenario:** An alert fires. An hour ago you ran a diagnostic that greps the
> logs for errors - you need to find it, re-run it, and document it for the team.

**3.1 (graded)** The diagnostic is in your history. Find it **without retyping**
(reverse-search for `ERROR`, or list history and re-run by number) and run it again.
It regenerates `~/sandbox/errors-found.txt`.

**3.2 (graded)** Document it: append the **exact command you just ran** to a runbook
at `~/sandbox/runbook.md` - recall it from history rather than retyping it.

---

## Muscle-memory drills (self-check - do these until they're automatic)

These can't be auto-graded, but they're the highest-leverage skills here. Type a
long line like `echo hello world foo bar baz` and practise:

| Goal | Keys |
|------|------|
| Jump to **start** of line | `Ctrl+A` |
| Jump to **end** of line | `Ctrl+E` |
| Back / forward one **word** | `Alt+B` / `Alt+F` |
| Back / forward one **char** | `Ctrl+B` / `Ctrl+F` |
| Cut a word, paste it back | `Alt+D` … `Ctrl+Y` |
| Abort current command | `Ctrl+C` |
| Suspend to background | `Ctrl+Z` |
| Reverse-search history | `Ctrl+R` |
| Clear screen | `Ctrl+L` |

**Drill:** type `echo the quick brown fox`, then - without arrow keys - jump to
the start (`Ctrl+A`), forward two words (`Alt+F` ×2), and keep going until it's
second nature. The transcript says it best: *"when I see people pressing the left
arrow to get to the beginning, it drives me crazy."*

## Self-check questions

1. Difference between `Ctrl+L` and `clear`?
2. You remember only part of a command from yesterday. Fastest way to find it?
3. What does `!42` do? What about `!!`?
4. `Ctrl+C` vs `Ctrl+Z` - what's the difference?

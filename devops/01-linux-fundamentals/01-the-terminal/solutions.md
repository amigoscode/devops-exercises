# Solutions - The Terminal

The point of this section is *how* you do it (keystrokes), not just the result.

## Tier 1

**1.1** `Ctrl+L` clears the visible screen but you can still scroll up to see old
output. `clear` (or `clear` then Enter) resets the scrollback too - scroll up and
there's nothing there.

**1.2** Type anything, then `Ctrl+C`. The line is abandoned, `^C` is shown, and
you get a clean prompt. Nothing executed.

**1.3** Let Tab do the typing:
```bash
cd ~/sandbox/srv/v   # press TAB -> var/
              l       # press TAB -> log/
              n       # press TAB -> nginx-application-server/
touch checked.txt
```
Each directory has a single child, so one Tab completes each level. That's the
whole point - you typed ~6 letters for a 4-level path.

## Tier 2

**2.1** Run the three echoes, then dump history to a file:
```bash
echo "step-1-build"
echo "step-2-test"
echo "step-3-deploy"
history > ~/sandbox/session.log
```
`history` prints your in-session command list; `>` redirects it into a file.

**2.2** Don't retype - recall:
```
Ctrl+R           # opens reverse-search:  (reverse-i-search)`':
ctrl-r           # type part of the planted command
<Enter>          # the matched command runs
```
It runs `echo "found-via-ctrl-r" > ~/sandbox/recall.txt`, creating the file.

## Tier 3

**3.1** Two equally good ways to find and re-run the diagnostic:
```bash
# Option A - reverse search
Ctrl+R  then type: ERROR   then <Enter>

# Option B - list & bang
history | grep ERROR       # note the line number, e.g. 6
!6                         # re-runs command #6
```
Either re-runs `grep -r "ERROR" ~/sandbox/logs > ~/sandbox/errors-found.txt`.

**3.2** Append the exact command to the runbook:
```bash
echo 'grep -r "ERROR" ~/sandbox/logs > ~/sandbox/errors-found.txt' >> ~/sandbox/runbook.md
```
Pro move: instead of typing it, recall it with `Ctrl+R`, then `Ctrl+A` to jump to
the start of the line and wrap it - pure terminal fluency.

---

### Answers to the self-check

1. `Ctrl+L` keeps scrollback; `clear` wipes it.
2. `Ctrl+R` and type any fragment you remember.
3. `!42` re-runs history command #42; `!!` re-runs the previous command.
4. `Ctrl+C` **terminates** the command; `Ctrl+Z` **suspends** it to the background
   (resume with `fg`).

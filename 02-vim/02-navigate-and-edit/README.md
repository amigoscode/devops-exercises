# 02 · Navigate & Edit

> Maps to **Vim → Navigating with Vim, Editing with Vim**

Speed in Vim comes from never reaching for the mouse. Move with `h j k l`, jump with
`gg`/`G`/`0`/`$`, and edit with `dd` (delete line), `yy`/`p` (copy/paste), `u` (undo),
`Ctrl-r` (redo).

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Vim → Navigate & Edit** and press `enter`. Inside the
sandbox, `questions` lists the tasks, `check` grades your work, and `exit` takes
you back with your progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - Delete a line *(hint: `dd` deletes the current line)*

**1.1 (graded)** `list.txt` has 5 fruit. Delete the `banana` line and keep the rest,
then save.

## Tier 2 - Copy a line *(hint: yank then paste; `u` undoes mistakes)*

**2.1 (graded)** In `dup.txt`, make the middle line `two` appear **twice** (keep
`one` and `three`), then save.

## Tier 3 - Clean up the task list *(goal only)*

**3.1 (graded)** `tasks.txt` has two `TODO:` lines mixed in with real work. Remove
**both** TODO lines, keep the three real tasks, and save.

## Self-check questions

1. How do you jump to the top of a file? The bottom?
2. What do `dd`, `yy` and `p` do?
3. You deleted the wrong line - how do you get it back?

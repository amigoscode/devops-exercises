# 01 · Insert & Save

> Maps to **Vim → Insert mode, Saving & Quitting**

On a real server there's no GUI editor - you edit configs over SSH with **Vim**.
First skill: get text in, and get out safely. Vim starts in **normal mode**; press
`i` to insert, `Esc` to go back, `:wq` to save & quit, `:q!` to bail without saving.

## How to use this set

```bash
# from the 02-vim/ folder
make build                          # once
make start  S=01-insert-and-save    # shell with files seeded in ~/sandbox
#   ...work in the container; when done, type 'exit' (or Ctrl+D) to leave, then:
# ...edit with vim...
make verify S=01-insert-and-save    # grade your work
make reset  S=01-insert-and-save    # fresh start
```

The grader checks the **resulting files**, so you must actually make the edits in
Vim and save them.

---

## Tier 1 - Create a file *(hint: `vim <file>`, `i` to insert, `Esc`, `:wq` to save)*

**1.1 (graded)** Create a brand-new file `~/sandbox/hello.txt` containing the single
line `Hello from Vim`, and save it.

## Tier 2 - Edit an existing file *(hint: `o` opens a new line below)*

**2.1 (graded)** `notes.txt` already has `line one` and `line two`. Add a third line
`line three` below them, and save.

## Tier 3 - Write a small config *(goal only)*

**3.1 (graded)** Create `~/sandbox/server.conf` containing exactly two lines:
```
host=0.0.0.0
port=8080
```

## 💪 Drill (self-check) - quit without saving

Open `keep.txt`, type some junk, then **discard it**: press `Esc`, type `:q!`,
Enter. Re-open it - your junk is gone, the original line intact. `:q!` is your
"undo everything and walk away" - muscle-memory worth having.

## Self-check questions

1. Which mode does Vim start in, and how do you start typing text?
2. `:wq` vs `:q!` - what's the difference?
3. `i` vs `o` for inserting - what does each do?

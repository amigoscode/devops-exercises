# Solutions - Navigate & Edit

## Tier 1
**1.1**
```
vim ~/sandbox/list.txt
j                 # move down to 'banana' (it's the 2nd line)
dd                # delete the whole line
:wq
```

## Tier 2
**2.1**
```
vim ~/sandbox/dup.txt
j                 # cursor onto 'two'
yy                # yank (copy) the line
p                 # paste it below -> 'two' now appears twice
:wq
```

## Tier 3
**3.1**
```
vim ~/sandbox/tasks.txt
# navigate to each line starting with TODO: and press dd (twice deletes both)
:wq
```

### Answers
1. `gg` jumps to the top, `G` to the bottom.
2. `dd` deletes the current line, `yy` copies (yanks) it, `p` pastes the yanked/
   deleted line after the cursor.
3. `u` to undo (and `Ctrl-r` to redo if you overshoot).

---

## Navigation cheat sheet

| Move | Key | Move | Key |
|------|-----|------|-----|
| left/down/up/right | `h` `j` `k` `l` | line start / end | `0` / `$` |
| top of file | `gg` | bottom of file | `G` |
| page fwd / back | `Ctrl-f` / `Ctrl-b` | undo / redo | `u` / `Ctrl-r` |
| delete line | `dd` | copy / paste line | `yy` / `p` |

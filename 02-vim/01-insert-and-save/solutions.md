# Solutions - Insert & Save

Keystrokes matter here - this is about doing it *in Vim*.

## Tier 1
**1.1**
```
vim ~/sandbox/hello.txt
i                       # insert mode
Hello from Vim
<Esc>
:wq<Enter>              # write + quit
```

## Tier 2
**2.1**
```
vim ~/sandbox/notes.txt
G                       # jump to last line
o                       # open a new line BELOW and enter insert mode
line three
<Esc>
:wq<Enter>
```

## Tier 3
**3.1**
```
vim ~/sandbox/server.conf
i
host=0.0.0.0
port=8080
<Esc>
:wq<Enter>
```

## Drill - quit without saving
```
vim ~/sandbox/keep.txt
i   ...type anything...   <Esc>
:q!<Enter>              # quit, discard ALL changes
```

### Answers
1. **Normal mode**; press `i` (or `a`, `o`) to start inserting.
2. `:wq` saves then quits; `:q!` quits and **throws away** unsaved changes.
3. `i` inserts **before the cursor** on the current line; `o` opens a **new line
   below** and starts inserting there.

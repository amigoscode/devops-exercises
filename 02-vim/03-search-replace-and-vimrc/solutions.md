# Solutions - Search, Replace & .vimrc

## Tier 1
**1.1**
```
vim ~/sandbox/config.txt
:%s/localhost/127.0.0.1/g
:wq
```
`%` = every line, `s` = substitute, `g` = all matches per line.

## Tier 2
**2.1**
```
vim ~/sandbox/app.env
:%s/DEBUG=true/DEBUG=false/
:wq
```
No `g` needed - there's only one match on the line.

## Tier 3
**3.1**
```
vim ~/.vimrc
i
set number
syntax on
<Esc>
:wq
```
Open any file afterwards and you'll see line numbers + colour.

### Answers
1. `:%s/foo/bar/g` replaces **every** `foo` with `bar` in the whole file. Without
   `g`, only the **first** match on each line. With `c` (`/gc`) Vim **asks you to
   confirm** each replacement.
2. Press `n` (and `N` for the previous match).
3. `~/.vimrc`. `set number` turns on line numbers.

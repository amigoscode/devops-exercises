# 03 · Search, Replace & .vimrc

> Maps to **Vim → Search and Replace, Customise Vim with .vimrc**

The payoff skills: find anything with `/`, change everything with `:%s/old/new/g`,
and make Vim your own with `~/.vimrc`. This is the bread and butter of editing
config files on a server.

## How to use this set

```bash
# from the 02-vim/ folder
make start  S=03-search-replace-and-vimrc
make verify S=03-search-replace-and-vimrc
make reset  S=03-search-replace-and-vimrc
```

---

## Tier 1 - Replace every occurrence *(hint: Vim's substitute - `:%s/old/new/g`)*

**1.1 (graded)** `config.txt` points everything at `localhost`. Replace **every**
occurrence with `127.0.0.1` in one go, then save.

## Tier 2 - Flip a single setting *(think: the same substitute, scoped to one match)*

**2.1 (graded)** In `app.env`, change `DEBUG=true` to `DEBUG=false`, leaving the
other lines untouched.

## Tier 3 - Make Vim yours *(goal only)*

**3.1 (graded)** Configure Vim via `~/.vimrc` so that **every** session shows line
numbers and syntax highlighting.

> Search tip: in normal mode, `/word` jumps to the next match, `n` repeats forward,
> `N` goes back.

## Self-check questions

1. What does `:%s/foo/bar/g` do? What changes if you drop the `g`? Add a `c`?
2. After `/error`, how do you jump to the next match?
3. Where does Vim read its per-user config, and what does `set number` do?

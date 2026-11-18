# Solutions - Redirection & Pipes

## Tier 1
```bash
ls /etc > ~/sandbox/etc.txt                       # 1.1
echo "Deploy started"  >  ~/sandbox/deploy.log    # 1.2
echo "Deploy finished" >> ~/sandbox/deploy.log    #     >> appends, doesn't overwrite
ls /nope 2> ~/sandbox/err.txt                      # 1.3  (2> captures stderr)
```

## Tier 2
```bash
cat ~/sandbox/access.log | grep ERROR > ~/sandbox/errors.txt   # 2.1
grep GET ~/sandbox/access.log | wc -l > ~/sandbox/get-count.txt # 2.2  -> 5
sort < ~/sandbox/names.txt > ~/sandbox/sorted.txt              # 2.3  ( < = stdin)
```

## Tier 3
```bash
find ~/sandbox/logs -name "*.log" > ~/sandbox/found.txt                       # 3.1
cat ~/sandbox/logs/*.log | grep ERROR | wc -l > ~/sandbox/error-count.txt     # 3.2 -> 3
grep -h ERROR ~/sandbox/logs/*.log | sort > ~/sandbox/errors-sorted.txt       # 3.3
```
`grep -h` hides the filename prefix so you get clean error lines; `sort` orders them.

### Answers
1. `>` overwrites the file; `>>` appends to the end.
2. Redirect stderr with `2>` (e.g. `cmd 2> errors.txt`) - separate from stdout's `>`.
3. The number of lines from `x` that contain `y`.
4. Pipes stream one command's output straight into the next with no temp files -
   you compose tiny tools into exactly the query you need.

---

## Quick reference

| Symbol | Does |
|--------|------|
| `>` | redirect stdout to a file (overwrite) |
| `>>` | append stdout to a file |
| `2>` | redirect stderr to a file |
| `&>` | redirect stdout **and** stderr |
| `<` | feed a file in as stdin |
| `\|` | pipe stdout of one command into another |

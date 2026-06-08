# Solutions - Conditions & Loops

## Tier 1
**1.1** `~/sandbox/check.sh`:
```bash
#!/bin/bash
if [ "$1" -ge 18 ]; then
  echo "adult"
else
  echo "minor"
fi
```

## Tier 2
**2.1** `~/sandbox/countup.sh`:
```bash
#!/bin/bash
for (( i=1; i<=5; i++ )); do
  echo "$i"
done
```

**2.2** `~/sandbox/sum.sh`:
```bash
#!/bin/bash
total=0
for (( i=1; i<=$1; i++ )); do
  total=$(( total + i ))
done
echo "$total"
```

## Tier 3
**3.1** `~/sandbox/sizes.sh`:
```bash
#!/bin/bash
for (( i=1; i<=$1; i++ )); do
  if [ "$i" -le 3 ]; then
    echo "small"
  else
    echo "big"
  fi
done
```

### Answers
1. The code to run when the condition is true sits between `then` and `fi`; the
   condition is usually a test in `[ ... ]` (e.g. `[ "$1" -ge 18 ]`).
2. `-ge` = greater-than-or-equal, `-lt` = less-than, `-eq` = equal (numeric).
3. Use `while` when you loop until a **condition** changes (unknown number of
   iterations); use `for` when you iterate a **known sequence** or list.

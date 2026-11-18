# Solutions - Error Handling

## Tier 1
**1.1** `~/sandbox/status.sh`:
```bash
#!/bin/bash
exit 42
```

## Tier 2
**2.1** `~/sandbox/safe.sh` - the strict-mode preamble you'll put at the top of
every serious script:
```bash
#!/bin/bash
set -euo pipefail        # -e exit on error, -u error on unset var, pipefail catches pipe failures
echo "running safely"
```

**2.2** `~/sandbox/report.sh` - `$?` holds the exit code of the previous command:
```bash
#!/bin/bash
ls /nonexistent 2>/dev/null
echo "exit code: $?"     # ls couldn't find it -> 2
```

## Tier 3
**3.1** `~/sandbox/deploy.sh`:
```bash
#!/bin/bash
if [ -z "$1" ]; then
  echo "usage: deploy.sh <version>" >&2
  exit 1
fi
echo "deploying $1"
```
(With `set -u` you'd guard with `${1:-}`; the simple form above is fine here.)

### Answers
1. `0` = success, non-zero = failure. The last command's code is in `$?`.
2. `set -e` stops the script on the first failing command; `set -u` errors if you
   use an unset variable (catches typos); `set -o pipefail` makes a pipeline fail
   if **any** stage fails, not just the last.
3. So the script stops with a clear message instead of running with missing data
   and doing something destructive or half-finished.

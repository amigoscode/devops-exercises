# Solutions - Files & Automation

## Tier 1
**1.1** `~/sandbox/writelog.sh`:
```bash
#!/bin/bash
echo "deployment started" > ~/sandbox/deploy.log
```

**1.2** `~/sandbox/readnames.sh` - the classic line-by-line read:
```bash
#!/bin/bash
while read -r name; do
  echo "- $name"
done < ~/sandbox/names.txt
```

## Tier 2
**2.1** `~/sandbox/checksum.sh`:
```bash
#!/bin/bash
sha256sum ~/sandbox/data.txt > ~/sandbox/data.sha256
```

**2.2** `~/sandbox/timer.sh`:
```bash
#!/bin/bash
echo "start"
sleep 1
echo "done"
```

## Tier 3
**3.1** `~/sandbox/provision.sh`:
```bash
#!/bin/bash
set -euo pipefail
mkdir -p ~/sandbox/app/bin ~/sandbox/app/config ~/sandbox/app/logs
echo "1.0" > ~/sandbox/app/VERSION
echo "provisioned"
```

### Answers
1. `>` overwrites the file; `>>` appends to the end of it.
2. A checksum (e.g. sha256) is a fingerprint of a file's contents - a deploy script
   compares it to an expected value to prove the file wasn't corrupted or tampered
   with in transit.
3. It's repeatable and identical every time, runs in one step, can't skip a command
   by mistake, and can be version-controlled and reused across many machines.

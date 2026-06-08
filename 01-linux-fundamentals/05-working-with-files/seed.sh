#!/usr/bin/env bash
# Runs INSIDE the Ubuntu container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"
mkdir -p "$SB/docs" "$SB/logs" "$SB/dump"

# Tier 1 - two halves to concatenate with cat
echo 'config part A' > "$SB/part1.txt"
echo 'config part B' > "$SB/part2.txt"

# Tier 2 - a config to back up, a draft to rename, loose logs to sweep up
printf 'env: prod\nport: 8080\n' > "$SB/app.conf"
echo 'rough draft'  > "$SB/draft.txt"
echo 'log alpha'    > "$SB/alpha.log"
echo 'log beta'     > "$SB/beta.log"
echo 'log gamma'    > "$SB/gamma.log"

# Tier 3 - a service dumped a mess of files into one folder
echo 'app running'  > "$SB/dump/app.log"
echo 'ERROR boom'   > "$SB/dump/error.log"
echo 'GET / 200'    > "$SB/dump/access.log"
echo 'binary junk'  > "$SB/dump/core.dump"
echo 'scratch'      > "$SB/dump/tmp123.tmp"
echo 'scratch'      > "$SB/dump/cache.tmp"
echo '# readme'     > "$SB/dump/README.md"
echo 'k: v'         > "$SB/dump/config.yaml"

# Clean any prior outputs so re-runs start fresh
rm -f  "$SB/logs.zip"
rm -rf "$SB/check"

echo "Sandbox ready at ~/sandbox  (mess to triage is in ~/sandbox/dump)"

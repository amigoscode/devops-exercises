#!/usr/bin/env bash
# Runs INSIDE the container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB"

# Tier 1 - a list to delete a line from
printf 'apple\nbanana\ncherry\ndate\nelderberry\n' > "$SB/list.txt"

# Tier 2 - a line to duplicate
printf 'one\ntwo\nthree\n' > "$SB/dup.txt"

# Tier 3 - a file with TODO lines mixed in
printf 'install nginx\nTODO: remove debug flag\nconfigure firewall\nTODO: rotate keys\nenable backups\n' > "$SB/tasks.txt"

echo "Sandbox ready at ~/sandbox. Navigate with h/j/k/l, edit with dd, yy, p, u."

#!/usr/bin/env bash
# Runs INSIDE the container. Seeds files for the scripts to read/checksum.
set -euo pipefail
SB="$HOME/sandbox"
rm -rf "$SB"; mkdir -p "$SB"

printf 'alice\nbob\ncarol\n'    > "$SB/names.txt"
printf 'release 1.0 payload\n'  > "$SB/data.txt"

echo "Sandbox ready at ~/sandbox (names.txt, data.txt). Write your scripts here."

#!/usr/bin/env bash
# Runs INSIDE the container. Clean place to write your scripts.
set -euo pipefail
SB="$HOME/sandbox"
rm -rf "$SB"; mkdir -p "$SB"
echo "Sandbox ready at ~/sandbox. Write your .sh scripts here."

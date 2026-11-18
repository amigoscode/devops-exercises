#!/usr/bin/env bash
# Runs INSIDE the Ubuntu container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"
mkdir -p "$SB/a/b/c/d"

# Clean up the shared /tmp marker so re-runs start fresh.
rm -f /tmp/student-was-here.txt

echo "Sandbox ready at ~/sandbox  (a deep path lives at ~/sandbox/a/b/c/d)"
echo "Reminder: the whole Linux tree starts at /  - explore it with cd, ls, pwd, tree."

#!/usr/bin/env bash
# Runs INSIDE the container. Builds a fresh ~/sandbox for the Vim exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB"

# A file to append to (Tier 2)
printf 'line one\nline two\n' > "$SB/notes.txt"

# A file to practise quitting WITHOUT saving (drill)
printf 'DO NOT CHANGE ME\n' > "$SB/keep.txt"

echo "Sandbox ready at ~/sandbox. Edit with: vim <file>"
echo "Reminder: i=insert, Esc=normal mode, :wq=save+quit, :q!=quit without saving"

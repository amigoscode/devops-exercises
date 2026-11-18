#!/usr/bin/env bash
# Runs INSIDE the Ubuntu container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"
mkdir -p "$SB/files"

# A small file tree, including a HIDDEN file (only `ls -a` reveals it).
echo 'env: prod'        > "$SB/files/app.conf"
echo 'GET / 200'        > "$SB/files/server.log"
echo '# runbook'        > "$SB/files/notes.md"
echo 'API_KEY=shhh'     > "$SB/files/.secret"

# Start the alias exercises from a clean slate.
rm -f "$HOME/.zshrc"

echo "Sandbox ready at ~/sandbox"
echo "Tip: you don't need to memorise flags - practise FINDING them (man, --help, apropos)."

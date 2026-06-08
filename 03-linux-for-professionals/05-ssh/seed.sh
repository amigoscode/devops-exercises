#!/usr/bin/env bash
# Runs INSIDE the container. Resets ~/.ssh for a fresh start.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB"
rm -rf "$HOME/.ssh"

echo "Sandbox ready. You'll generate keys and write an SSH config under ~/.ssh."

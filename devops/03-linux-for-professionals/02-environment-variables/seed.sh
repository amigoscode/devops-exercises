#!/usr/bin/env bash
# Runs INSIDE the container. Resets env-var state for a fresh start.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB"

# Reset ~/.bashrc to the clean default so the persistence tasks start fresh.
cp /etc/skel/.bashrc "$HOME/.bashrc" 2>/dev/null || true
rm -rf "$HOME/bin"

echo "Sandbox ready. Persist settings in ~/.bashrc (then 'source ~/.bashrc' or reopen)."

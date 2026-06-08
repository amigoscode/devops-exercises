#!/usr/bin/env bash
# Runs INSIDE the Ubuntu container. Resets shell state for a fresh start.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"
mkdir -p "$SB"

# Start every attempt from a clean slate:
#   - default login shell back to bash (so changing it to zsh is a real task)
#   - no ~/.zshrc yet (so creating/configuring it is a real task)
sudo chsh -s /bin/bash "$(whoami)" 2>/dev/null || true
rm -f "$HOME/.zshrc"

echo "Sandbox ready at ~/sandbox"
echo "Current default shell: $(getent passwd "$(whoami)" | cut -d: -f7)"
echo "zsh is installed at: $(command -v zsh)  (oh-my-zsh is NOT installed - optional stretch)"

#!/usr/bin/env bash
# Runs INSIDE the container. Clean slate: no git identity yet, an empty project dir.
set -euo pipefail
SB="$HOME/sandbox"
rm -rf "$SB"; mkdir -p "$SB/project"
rm -f "$HOME/.gitconfig"     # so configuring your identity is a real task

echo "Sandbox ready. Configure git, then turn ~/sandbox/project into a repository."

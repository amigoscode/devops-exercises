#!/usr/bin/env bash
# Runs INSIDE the container. An empty project dir + an empty remote to push to.
set -euo pipefail
SB="$HOME/sandbox"
rm -rf "$SB"; mkdir -p "$SB/myapp"
git config --global user.name  "Student"   >/dev/null 2>&1
git config --global user.email "student@example.com" >/dev/null 2>&1

git init -q --bare "$SB/origin.git"          # the empty "GitHub" repo

echo "Sandbox ready. Take ~/sandbox/myapp from nothing to pushed at ~/sandbox/origin.git"

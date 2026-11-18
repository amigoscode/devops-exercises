#!/usr/bin/env bash
# Runs INSIDE the container. Sets up a local "remote" (a bare repo) plus a working
# repo with one commit. A bare repo stands in for GitHub so this works offline.
set -euo pipefail
SB="$HOME/sandbox"
rm -rf "$SB"; mkdir -p "$SB"
git config --global user.name  "Student"   >/dev/null 2>&1
git config --global user.email "student@example.com" >/dev/null 2>&1

git init -q --bare "$SB/remote.git"          # the "GitHub" you'll push to

git init -q "$SB/project"
cd "$SB/project"
echo "hello" > app.txt
git add app.txt && git commit -q -m "initial"

echo "Sandbox ready. Your repo: ~/sandbox/project. Your remote: ~/sandbox/remote.git"

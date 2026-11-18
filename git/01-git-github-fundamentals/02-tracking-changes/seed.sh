#!/usr/bin/env bash
# Runs INSIDE the container. Seeds a repo with one commit, an untracked file,
# and a pre-staged file to practise the staging area on.
set -euo pipefail
SB="$HOME/sandbox"
rm -rf "$SB"; mkdir -p "$SB"
git config --global user.name  "Student"   >/dev/null 2>&1
git config --global user.email "student@example.com" >/dev/null 2>&1

git init -q "$SB/project"
cd "$SB/project"
echo "v1" > tracked.txt
git add tracked.txt && git commit -q -m "initial"

echo "a" > a.txt              # untracked - you'll stage this
echo "b" > b.txt && git add b.txt    # already staged - you'll UNstage this

echo "Sandbox ready. Work inside ~/sandbox/project."

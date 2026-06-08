#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Tracking Changes exercises.
set -uo pipefail
SB="$HOME/sandbox"; P="$SB/project"
[[ -d "$P/.git" ]] || { echo "No repo. Run 'make start S=02-tracking-changes' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
staged(){ git -C "$P" diff --cached --name-only 2>/dev/null | grep -qx "$1"; }

echo "Tier 1 - The staging area"
if staged a.txt; then
  ok "1.1 a.txt is staged (added to the index)"
else
  no "1.1 stage a.txt with 'git add a.txt'"
fi
if ! staged b.txt && [[ -f "$P/b.txt" ]]; then
  ok "1.2 b.txt unstaged but still on disk (git rm --cached)"
else
  no "1.2 unstage b.txt without deleting it (git rm --cached b.txt)"
fi

echo "Tier 2 - See your changes"
if [[ -f "$SB/changes.diff" ]] && grep -q 'tracked.txt' "$SB/changes.diff" && grep -qE '^\+' "$SB/changes.diff"; then
  ok "2.1 changes.diff captures a git diff of your edit to tracked.txt"
else
  no "2.1 edit tracked.txt, then save 'git diff' to ~/sandbox/changes.diff (it must show the added line)"
fi

echo "Tier 3 - Inspect history"
if [[ -f "$SB/history.txt" ]] && grep -q 'initial' "$SB/history.txt"; then
  ok "3.1 history.txt shows the commit history (the 'initial' commit)"
else
  no "3.1 save the commit history to ~/sandbox/history.txt (git log) - it should mention the 'initial' commit"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You understand the staging area, diffs and history - the heart of git."

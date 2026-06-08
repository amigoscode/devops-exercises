#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Git capstone.
set -uo pipefail
SB="$HOME/sandbox"; P="$SB/myapp"; R="$SB/origin.git"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=04-capstone' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
local_count(){ git -C "$P" rev-list --count HEAD 2>/dev/null || echo 0; }
remote_count(){ git -C "$R" rev-list --count main 2>/dev/null || echo 0; }

echo "Capstone - zero to pushed"
if [[ -d "$P/.git" ]] && [[ "$(local_count)" -ge 1 ]]; then
  ok "1. myapp is a repo with a first commit"
else
  no "1. git init ~/sandbox/myapp, add a file, and make the first commit"
fi
if [[ "$(local_count)" -ge 2 ]]; then
  ok "2. a second commit exists locally"
else
  no "2. add another file/change and make a second commit"
fi
if git -C "$P" remote -v 2>/dev/null | grep -q 'origin.git'; then
  ok "3. 'origin' remote points at ~/sandbox/origin.git"
else
  no "3. git remote add origin ~/sandbox/origin.git"
fi
if [[ "$(remote_count)" -ge 2 ]]; then
  ok "4. pushed - the remote has your commits on main"
else
  no "4. git push -u origin main (the remote should hold both commits)"
fi

echo
echo "Score: $pass passed, $fail failed."
if [[ $fail -eq 0 ]]; then
  echo
  echo "🎓 CAPSTONE COMPLETE - you took a project from an empty folder to a"
  echo "   version-controlled repo pushed to a remote. That's the daily git loop."
fi

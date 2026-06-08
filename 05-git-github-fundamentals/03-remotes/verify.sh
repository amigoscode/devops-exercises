#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Remotes exercises.
set -uo pipefail
SB="$HOME/sandbox"; P="$SB/project"; R="$SB/remote.git"
[[ -d "$P/.git" ]] || { echo "No repo. Run 'make start S=03-remotes' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
remote_count(){ git -C "$R" rev-list --count main 2>/dev/null || echo 0; }

echo "Tier 1 - Link to a remote"
if git -C "$P" remote -v 2>/dev/null | grep -q 'remote.git'; then
  ok "1.1 'origin' remote points at ~/sandbox/remote.git"
else
  no "1.1 add the remote: git remote add origin ~/sandbox/remote.git"
fi

echo "Tier 2 - Push"
if [[ "$(remote_count)" -ge 1 ]]; then
  ok "2.1 pushed your commit(s) to the remote's main branch"
else
  no "2.1 push to the remote: git push -u origin main"
fi
if [[ "$(remote_count)" -ge 2 ]]; then
  ok "2.2 made a new commit and pushed it (remote now has 2+ commits)"
else
  no "2.2 make another commit and push again (remote should have 2+ commits)"
fi

echo "Tier 3 - Clone"
if [[ -d "$SB/clone/.git" ]] && [[ -f "$SB/clone/app.txt" ]]; then
  ok "3.1 cloned the remote into ~/sandbox/clone (app.txt is there)"
else
  no "3.1 clone the remote: git clone ~/sandbox/remote.git ~/sandbox/clone"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can connect a repo to a remote, push, and clone - the basis of collaboration."

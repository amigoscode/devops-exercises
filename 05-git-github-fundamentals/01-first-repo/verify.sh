#!/usr/bin/env bash
# Runs INSIDE the container. Grades the First Repo exercises.
set -uo pipefail
SB="$HOME/sandbox"; P="$SB/project"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=01-first-repo' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
commits(){ git -C "$P" rev-list --count HEAD 2>/dev/null || echo 0; }

echo "Tier 1 - Set up"
gname="$(git config --global user.name 2>/dev/null || true)"
gemail="$(git config --global user.email 2>/dev/null || true)"
if [[ -n "$gname" && -n "$gemail" ]]; then
  ok "1.1 git identity configured (user.name + user.email)"
else
  no "1.1 set your global git user.name and user.email (git config --global ...)"
fi
if [[ -d "$P/.git" ]]; then
  ok "1.2 ~/sandbox/project is a git repository"
else
  no "1.2 turn ~/sandbox/project into a repo (cd into it and git init)"
fi

echo "Tier 2 - Your first commit"
if [[ "$(commits)" -ge 1 ]] && [[ -n "$(git -C "$P" ls-files 2>/dev/null)" ]]; then
  ok "2.1 a file is committed in the repo (at least one commit)"
else
  no "2.1 create a file in the repo, stage it (git add) and commit it (git commit -m ...)"
fi

echo "Tier 3 - Build some history"
if [[ "$(commits)" -ge 2 ]]; then
  ok "3.1 the repo has at least two commits"
else
  no "3.1 make a change and create a second commit (history should grow to 2)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can configure git, create a repo and build commit history."

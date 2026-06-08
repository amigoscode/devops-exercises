#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Search/Replace & .vimrc exercises.
set -uo pipefail
SB="$HOME/sandbox"
VRC="$HOME/.vimrc"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=03-search-replace-and-vimrc' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }

echo "Tier 1 - Replace every occurrence"
if [[ -f "$SB/config.txt" ]] && ! grep -q 'localhost' "$SB/config.txt" \
   && [[ "$(grep -c '127.0.0.1' "$SB/config.txt")" -ge 3 ]]; then
  ok "1.1 replaced all 'localhost' with 127.0.0.1 (:%s/localhost/127.0.0.1/g)"
else
  no "1.1 in config.txt replace every 'localhost' with 127.0.0.1 using :%s/localhost/127.0.0.1/g"
fi

echo "Tier 2 - Flip a single setting"
if [[ -f "$SB/app.env" ]] && grep -q '^DEBUG=false$' "$SB/app.env" \
   && ! grep -q 'DEBUG=true' "$SB/app.env" \
   && grep -q '^ENV=staging$' "$SB/app.env"; then
  ok "2.1 changed DEBUG=true to DEBUG=false"
else
  no "2.1 in app.env change DEBUG=true to DEBUG=false (:%s/DEBUG=true/DEBUG=false/), keep the rest"
fi

echo "Tier 3 - Customise Vim with ~/.vimrc"
if [[ -f "$VRC" ]] && grep -Eq '^[[:space:]]*set[[:space:]]+number' "$VRC" \
   && grep -Eq '^[[:space:]]*syntax[[:space:]]+on' "$VRC"; then
  ok "3.1 ~/.vimrc enables line numbers and syntax highlighting"
else
  no "3.1 create ~/.vimrc with 'set number' and 'syntax on' (vim ~/.vimrc)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Search, replace and a configured Vim - you can wrangle configs on any server."

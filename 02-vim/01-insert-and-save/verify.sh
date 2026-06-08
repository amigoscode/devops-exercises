#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Insert & Save exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=01-insert-and-save' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
has(){ grep -qF "$2" "$1" 2>/dev/null; }

echo "Tier 1 - Create a file"
if [[ -f "$SB/hello.txt" ]] && has "$SB/hello.txt" "Hello from Vim"; then
  ok "1.1 created hello.txt with the line via insert mode + :wq"
else
  no "1.1 create ~/sandbox/hello.txt containing 'Hello from Vim' (vim hello.txt, i, type, Esc, :wq)"
fi

echo "Tier 2 - Append to an existing file"
if has "$SB/notes.txt" "line one" && has "$SB/notes.txt" "line two" && has "$SB/notes.txt" "line three"; then
  ok "2.1 added 'line three' to notes.txt (kept the first two)"
else
  no "2.1 open notes.txt and add a third line 'line three' (use o to open a line below), then :wq"
fi

echo "Tier 3 - Write a small config"
if [[ -f "$SB/server.conf" ]] && has "$SB/server.conf" "host=0.0.0.0" && has "$SB/server.conf" "port=8080"; then
  ok "3.1 created server.conf with the host and port lines"
else
  no "3.1 create ~/sandbox/server.conf containing two lines: host=0.0.0.0 and port=8080"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can create, edit and save files in Vim."

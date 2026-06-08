#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Navigate & Edit exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=02-navigate-and-edit' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
has(){ grep -qx "$2" "$1" 2>/dev/null; }                 # exact-line match
count(){ local n; n=$(grep -cx "$2" "$1" 2>/dev/null || true); echo "${n:-0}"; }

echo "Tier 1 - Delete a line (dd)"
if [[ -f "$SB/list.txt" ]] && ! has "$SB/list.txt" "banana" \
   && has "$SB/list.txt" "apple" && has "$SB/list.txt" "cherry" \
   && has "$SB/list.txt" "date" && has "$SB/list.txt" "elderberry"; then
  ok "1.1 deleted the 'banana' line, kept the rest"
else
  no "1.1 in list.txt, navigate to 'banana' and press dd to delete it (keep the others)"
fi

echo "Tier 2 - Copy a line (yy / p)"
if [[ "$(count "$SB/dup.txt" "two")" -ge 2 ]] && has "$SB/dup.txt" "one" && has "$SB/dup.txt" "three"; then
  ok "2.1 duplicated the 'two' line with yy then p"
else
  no "2.1 in dup.txt, put the cursor on 'two', press yy then p so it appears twice"
fi

echo "Tier 3 - Clean up the task list"
todo_left=$(grep -c 'TODO' "$SB/tasks.txt" 2>/dev/null || true); todo_left=${todo_left:-0}
if [[ "$todo_left" -eq 0 ]] \
   && has "$SB/tasks.txt" "install nginx" \
   && has "$SB/tasks.txt" "configure firewall" \
   && has "$SB/tasks.txt" "enable backups"; then
  ok "3.1 removed both TODO lines, kept the three real tasks"
else
  no "3.1 delete every line containing TODO from tasks.txt (dd on each), keep the real tasks"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can navigate and edit in Vim without the mouse."

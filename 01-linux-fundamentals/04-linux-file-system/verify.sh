#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Linux File System exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=04-linux-file-system' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
content(){ cat "$1" 2>/dev/null; }

echo "Tier 1 - Orient yourself"
if [[ "$(content "$SB/root.txt")" == "/" ]]; then
  ok "1.1 captured the filesystem root with pwd"
else
  no "1.1 root.txt must contain '/' (cd / then: pwd > ~/sandbox/root.txt)"
fi
if [[ "$(content "$SB/home.txt")" == "$HOME" ]]; then
  ok "1.2 captured your home path via the variable"
else
  no "1.2 home.txt must contain $HOME (use: echo \$HOME > ~/sandbox/home.txt)"
fi
if [[ -f "$SB/tree.txt" ]] && grep -q 'etc' "$SB/tree.txt" && grep -q 'home' "$SB/tree.txt" \
   && grep -q 'usr' "$SB/tree.txt" && grep -q 'var' "$SB/tree.txt"; then
  ok "1.3 mapped the top level of / with tree"
else
  no "1.3 tree.txt should show /'s top level (try: tree -L 1 / > ~/sandbox/tree.txt)"
fi

echo "Tier 2 - Navigate"
if [[ -f /tmp/student-was-here.txt ]]; then
  ok "2.1 navigated into /tmp and left a marker there"
else
  no "2.1 cd into /tmp and create student-was-here.txt (the file proves where you were)"
fi
if [[ -f "$SB/a/b/here.txt" ]]; then
  ok "2.2 climbed exactly two levels with cd ../.. and dropped here.txt"
else
  no "2.2 from ~/sandbox/a/b/c/d, use cd ../.. then create here.txt (should land in a/b)"
fi
if [[ -f "$SB/etc-listing.txt" ]] && grep -q 'passwd' "$SB/etc-listing.txt"; then
  ok "2.3 listed /etc by absolute path without cd-ing there"
else
  no "2.3 etc-listing.txt should list /etc (try: ls /etc > ~/sandbox/etc-listing.txt)"
fi

echo "Tier 3 - Know the standard layout (FHS)"
f="$SB/fhs.txt"
if [[ -f "$f" ]] && grep -q '/etc' "$f" && grep -q '/var/log' "$f" \
   && grep -q '/root' "$f" && grep -q '/tmp' "$f"; then
  ok "3.1 fhs.txt maps config, logs, root-home and temp to the right paths"
else
  no "3.1 fhs.txt must list /etc, /var/log, /root and /tmp (one per line)"
fi
if [[ "$(content "$SB/at-logs.txt")" == "/var/log" ]]; then
  ok "3.2 navigated to the log directory and proved it with pwd"
else
  no "3.2 at-logs.txt must contain /var/log (cd there, then: pwd > ~/sandbox/at-logs.txt)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can find your way around any Linux box blindfolded."

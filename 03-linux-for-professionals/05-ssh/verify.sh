#!/usr/bin/env bash
# Runs INSIDE the container. Grades the SSH exercises (offline-gradable parts).
set -uo pipefail
SB="$HOME/sandbox"
SSHD="$HOME/.ssh"
CFG="$SSHD/config"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=05-ssh' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
ci(){ grep -qiE "$2" "$1" 2>/dev/null; }   # case-insensitive grep

echo "Tier 1 - Write an SSH config"
if [[ -f "$CFG" ]] && ci "$CFG" '^[[:space:]]*Host[[:space:]]+myserver' \
   && ci "$CFG" 'HostName' && ci "$CFG" 'User'; then
  ok "1.1 ~/.ssh/config defines Host 'myserver' with HostName and User"
else
  no "1.1 create ~/.ssh/config with a 'Host myserver' block (HostName + User + IdentityFile)"
fi

echo "Tier 2 - Lock it down"
if [[ -f "$CFG" ]] && [[ "$(stat -c '%a' "$CFG" 2>/dev/null)" == "600" ]]; then
  ok "2.1 ~/.ssh/config is set to 600 (the permission SSH requires)"
else
  no "2.1 chmod 600 ~/.ssh/config"
fi

echo "Tier 3 - A production host entry"
if [[ -f "$CFG" ]] && ci "$CFG" '^[[:space:]]*Host[[:space:]]+prod' \
   && ci "$CFG" 'User[[:space:]]+ubuntu'; then
  ok "3.1 added a 'Host prod' entry with User ubuntu"
else
  no "3.1 add a second 'Host prod' block (HostName <ip>, User ubuntu, Port, IdentityFile)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Keys + SSH config done - you can connect to servers the clean, secure way."
echo
echo "ℹ️  Cloud drills (not graded - need an AWS account): see README."

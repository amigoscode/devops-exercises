#!/usr/bin/env bash
# Runs INSIDE the container. Grades the SSH exercises (offline-gradable parts).
set -uo pipefail
SB="$HOME/sandbox"
SSHD="$HOME/.ssh"
CFG="$SSHD/config"
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# block HOST: the lines of the `Host HOST` block in ~/.ssh/config (up to the next Host/Match)
block(){ awk -v h="$1" 'tolower($1)=="host"{b=0; for(i=2;i<=NF;i++) if($i==h) b=1; next} tolower($1)=="match"{b=0; next} b' "$CFG" 2>/dev/null; }
# has HOST KEY [VALUE]: the block sets KEY (case-insensitive, "Key value" or "Key=value")
has(){ block "$1" | grep -qiE "^[[:space:]]*$2([[:space:]]*=[[:space:]]*|[[:space:]]+)${3:-[^[:space:]]}"; }

echo "Tier 1 - Write an SSH config"
if [[ -f "$CFG" ]] && has myserver HostName && has myserver User && has myserver IdentityFile; then
  ok "1.1 ~/.ssh/config defines Host 'myserver' with HostName, User and IdentityFile"
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
if [[ -f "$CFG" ]] && has prod HostName && has prod User 'ubuntu([[:space:]]|$)' \
   && has prod Port '[0-9]+' && has prod IdentityFile; then
  ok "3.1 added a 'Host prod' entry with HostName, User ubuntu, Port and IdentityFile"
else
  no "3.1 add a second 'Host prod' block (HostName <ip>, User ubuntu, Port, IdentityFile)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Keys + SSH config done - you can connect to servers the clean, secure way."
echo
echo "ℹ️  Cloud drills (not graded - need an AWS account): see README."

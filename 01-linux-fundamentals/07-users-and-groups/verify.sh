#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Users & Groups exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=07-users-and-groups' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
user_exists(){ getent passwd "$1" >/dev/null 2>&1; }
group_exists(){ getent group "$1" >/dev/null 2>&1; }
in_group(){ id -nG "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"; }

echo "Tier 1 - sudo & a new user"
if [[ -d /opt/acme ]]; then
  ok "1.1 used sudo to create /opt/acme (a root-only location)"
else
  no "1.1 sudo mkdir /opt/acme (you can't write under /opt without root)"
fi
if user_exists alice && [[ -d /home/alice ]]; then
  ok "1.2 created user 'alice' with a home directory"
else
  no "1.2 sudo useradd -m alice (the -m gives her a home dir)"
fi

echo "Tier 2 - Groups & privileges"
if group_exists developers; then
  ok "2.1 created the 'developers' group"
else
  no "2.1 sudo groupadd developers"
fi
if in_group alice developers; then
  ok "2.2 added alice to 'developers'"
else
  no "2.2 add alice to developers (sudo gpasswd -a alice developers)"
fi
if in_group alice sudo; then
  ok "2.3 granted alice sudo rights"
else
  no "2.3 give alice sudo (sudo adduser alice sudo)"
fi

echo "Tier 3 - Onboard a team, then offboard"
# Note: we assert the durable onboarding (accounts + group + the staying members).
# carol's ops membership is intentionally checked in 3.2, since she gets offboarded.
if user_exists bob && user_exists carol && group_exists ops \
   && in_group alice ops && in_group bob ops; then
  ok "3.1 onboarded bob & carol and stood up the 'ops' group"
else
  no "3.1 create bob & carol (useradd -m), create 'ops', add all three (gpasswd -M alice,bob,carol ops)"
fi
if user_exists carol && ! in_group carol ops && in_group bob ops; then
  ok "3.2 offboarded carol from 'ops' (account kept, bob still in)"
else
  no "3.2 remove carol from ops only (sudo gpasswd -d carol ops) - keep her account & keep bob"
fi
if ! group_exists legacy; then
  ok "3.3 deleted the unused 'legacy' group"
else
  no "3.3 delete the leftover group (sudo groupdel legacy)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can administer users, groups and privileges like a real sysadmin."

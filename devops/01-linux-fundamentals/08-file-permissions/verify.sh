#!/usr/bin/env bash
# Runs INSIDE the container. Auto-grades the File Permissions exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
perm() { stat -c '%a' "$1"; }           # plain Linux - no cross-platform hack needed
owner() { stat -c '%U' "$1"; }
check() { if [[ "$2" == "$3" ]]; then printf '  ✅ %s\n' "$1"; pass=$((pass+1));
          else printf '  ❌ %s  (want %s, got %s)\n' "$1" "$2" "$3"; fail=$((fail+1)); fi; }

echo "Tier 1 - Warm-up"
check "1.1 deploy.sh executable by all" "755" "$(perm "$SB/deploy.sh")"
check "1.2 secret.env owner-only rw"    "600" "$(perm "$SB/secret.env")"
check "1.3 notes.txt read-only all"     "444" "$(perm "$SB/notes.txt")"

echo "Tier 2 - Core"
check "2.1 app/run.sh = rwxr-x---"      "750" "$(perm "$SB/app/run.sh")"
check "2.2 app/config.yaml = rwxr-x---" "750" "$(perm "$SB/app/config.yaml")"
all644=true; for f in "$SB"/app/logs/*.log; do [[ "$(perm "$f")" == "644" ]] || all644=false; done
check "2.3 app/logs dir = rwxr-x---, every *.log = 644" "dir=750 logs644=true" \
  "dir=$(perm "$SB/app/logs") logs644=$all644"

echo "Tier 3 - Challenge"
# README allows any mode where the owner has rwx and group/others can't write (744, 755, 700...)
s31="$(stat -c '%A' "$SB/service/start.sh")"
[[ "$s31" =~ ^-rwx.-..-.$ ]] && s31="owner rwx, no group/other write"
check "3.1 start.sh owner exec, no group/other write" "owner rwx, no group/other write" "$s31"
check "3.2 app.conf readable owner+group only"        "440" "$(perm "$SB/service/app.conf")"
check "3.3 app.log owned by student, owner can rw"    "student rw" \
  "$(owner "$SB/service/app.log") $(stat -c '%A' "$SB/service/app.log" | cut -c2-3)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 All clear - you can triage permissions like a pro."

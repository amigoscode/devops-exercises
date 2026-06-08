#!/usr/bin/env bash
# Runs INSIDE the container. Grades the System Admin exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=03-system-admin' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
lines(){ wc -l < "$1" 2>/dev/null | tr -d ' '; }

echo "Tier 1 - Disk usage"
if [[ -f "$SB/disk.txt" ]] && grep -q '%' "$SB/disk.txt" && grep -q '/' "$SB/disk.txt"; then
  ok "1.1 captured filesystem usage with df -h"
else
  no "1.1 df -h > ~/sandbox/disk.txt"
fi
if [[ -f "$SB/data-size.txt" ]] && grep -Eq '[0-9]+(\.[0-9]+)?[KMG]' "$SB/data-size.txt" && grep -q 'data' "$SB/data-size.txt"; then
  ok "1.2 measured the data directory with du -sh"
else
  no "1.2 du -sh ~/sandbox/data > ~/sandbox/data-size.txt"
fi

echo "Tier 2 - Processes"
if [[ -f "$SB/processes.txt" ]] && grep -q 'PID' "$SB/processes.txt"; then
  ok "2.1 captured the process list with ps aux"
else
  no "2.1 ps aux > ~/sandbox/processes.txt"
fi
actual_pid="$(pgrep -x sleep | head -1)"
if [[ -n "$actual_pid" ]] && grep -qw "$actual_pid" "$SB/runaway-pid.txt" 2>/dev/null; then
  ok "2.2 identified the runaway sleep process and recorded its PID"
else
  no "2.2 use ps/top to find the runaway 'sleep' process and write its PID to ~/sandbox/runaway-pid.txt"
fi

echo "Tier 3 - jq: pull fields out of JSON"
if [[ -f "$SB/name.txt" ]] && grep -qx 'checkout-api' "$SB/name.txt"; then
  ok "3.1 extracted .service.name with jq"
else
  no "3.1 jq -r '.service.name' services.json > ~/sandbox/name.txt"
fi
if [[ -f "$SB/version.txt" ]] && grep -qx '2.3.1' "$SB/version.txt"; then
  ok "3.2 extracted .service.version with jq"
else
  no "3.2 jq -r '.service.version' services.json > ~/sandbox/version.txt (2.3.1)"
fi
if [[ -f "$SB/replicas.txt" ]] && grep -qx '3' "$SB/replicas.txt"; then
  ok "3.3 extracted the .replicas field with jq"
else
  no "3.3 jq '.replicas' services.json > ~/sandbox/replicas.txt (3)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Disk, processes and JSON wrangling - core sysadmin reflexes."

#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Files & Automation scripts by running them.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=05-files-and-automation' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }

echo "Tier 1 - Read & write files"
# 1.1 - a script writes to a log file
[[ -f "$SB/writelog.sh" ]] && bash "$SB/writelog.sh" >/dev/null 2>&1
if [[ -f "$SB/deploy.log" ]] && grep -q 'deployment started' "$SB/deploy.log"; then
  ok "1.1 writelog.sh: writes 'deployment started' to deploy.log"
else
  no "1.1 writelog.sh should write the line 'deployment started' into ~/sandbox/deploy.log"
fi
# 1.2 - a script reads names.txt line by line
out="$([[ -f "$SB/readnames.sh" ]] && bash "$SB/readnames.sh" 2>/dev/null)"
if [[ "$out" == *"- alice"* ]] && [[ "$out" == *"- bob"* ]] && [[ "$out" == *"- carol"* ]]; then
  ok "1.2 readnames.sh: prints each name from names.txt prefixed with '- '"
else
  no "1.2 readnames.sh should read names.txt and print each line as '- <name>' (while read loop)"
fi

echo "Tier 2 - Checksums & timing"
# 2.1 - checksum of data.txt
[[ -f "$SB/checksum.sh" ]] && bash "$SB/checksum.sh" >/dev/null 2>&1
expected="$(sha256sum "$SB/data.txt" | awk '{print $1}')"
if [[ -f "$SB/data.sha256" ]] && grep -q "$expected" "$SB/data.sha256"; then
  ok "2.1 checksum.sh: writes the sha256 of data.txt to data.sha256"
else
  no "2.1 checksum.sh should write the sha256 checksum of data.txt into ~/sandbox/data.sha256"
fi
# 2.2 - sleep timer
out="$([[ -f "$SB/timer.sh" ]] && bash "$SB/timer.sh" 2>/dev/null)"
if [[ "$out" == *start* ]] && [[ "$out" == *done* ]]; then
  ok "2.2 timer.sh: prints 'start', sleeps, then prints 'done'"
else
  no "2.2 timer.sh should echo 'start', sleep, then echo 'done' (use the sleep command)"
fi

echo "Tier 3 - A real provisioning script"
out="$([[ -f "$SB/provision.sh" ]] && bash "$SB/provision.sh" 2>/dev/null)"
if [[ -d "$SB/app/bin" && -d "$SB/app/config" && -d "$SB/app/logs" ]] \
   && [[ -f "$SB/app/VERSION" ]] && grep -q '1.0' "$SB/app/VERSION" \
   && [[ "$out" == *provisioned* ]]; then
  ok "3.1 provision.sh: builds app/{bin,config,logs} + VERSION and reports 'provisioned'"
else
  no "3.1 provision.sh should create ~/sandbox/app with bin, config, logs, write '1.0' to app/VERSION, and echo 'provisioned'"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Reading, writing, checksums and a real provisioning script - that's automation."

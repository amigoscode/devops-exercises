#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Working with Files exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=05-working-with-files' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
has(){ grep -q "$2" "$1" 2>/dev/null; }

echo "Tier 1 - Create & read"
if [[ -f "$SB/empty.txt" && ! -s "$SB/empty.txt" ]] && [[ -f "$SB/status.txt" ]] && has "$SB/status.txt" "deploy complete"; then
  ok "1.1 created an empty file (touch) and a file with content (echo >)"
else
  no "1.1 need empty.txt (empty) and status.txt containing 'deploy complete'"
fi
if [[ -f "$SB/full.txt" ]] && has "$SB/full.txt" "config part A" && has "$SB/full.txt" "config part B"; then
  ok "1.2 concatenated both parts into full.txt with cat"
else
  no "1.2 full.txt must contain both parts (cat part1.txt part2.txt > full.txt)"
fi

echo "Tier 2 - Copy, move, rename"
if [[ -f "$SB/app.conf.bak" ]] && cmp -s "$SB/app.conf" "$SB/app.conf.bak"; then
  ok "2.1 backed up app.conf -> app.conf.bak (identical copy)"
else
  no "2.1 cp app.conf to app.conf.bak (contents must match)"
fi
if [[ -f "$SB/docs/release-notes.md" ]] && [[ ! -e "$SB/draft.txt" ]]; then
  ok "2.2 renamed+moved draft.txt -> docs/release-notes.md"
else
  no "2.2 mv draft.txt to docs/release-notes.md (original should be gone)"
fi
root_logs=0; for f in "$SB"/*.log; do [[ -e "$f" ]] && root_logs=$((root_logs+1)); done
if [[ $root_logs -eq 0 ]] && [[ -f "$SB/logs/alpha.log" && -f "$SB/logs/beta.log" && -f "$SB/logs/gamma.log" ]]; then
  ok "2.3 swept all *.log from ~/sandbox into logs/ with a wildcard"
else
  no "2.3 move every *.log from ~/sandbox into logs/ (mv ~/sandbox/*.log ~/sandbox/logs/)"
fi

echo "Tier 3 - Triage the dump"
tmp_left=0; for f in "$SB"/dump/*.tmp; do [[ -e "$f" ]] && tmp_left=$((tmp_left+1)); done
if [[ $tmp_left -eq 0 ]] && [[ ! -e "$SB/dump/core.dump" ]] && [[ -f "$SB/dump/app.log" && -f "$SB/dump/README.md" ]]; then
  ok "3.1 deleted the junk (*.tmp + core.dump), kept the real files"
else
  no "3.1 rm the *.tmp files and core.dump from dump/ (keep logs, README, yaml)"
fi
if [[ -f "$SB/logs.zip" ]] && unzip -l "$SB/logs.zip" 2>/dev/null | grep -q 'app.log' \
   && unzip -l "$SB/logs.zip" 2>/dev/null | grep -q 'error.log' \
   && unzip -l "$SB/logs.zip" 2>/dev/null | grep -q 'access.log'; then
  ok "3.2 archived the three logs into logs.zip"
else
  no "3.2 zip dump's *.log files into ~/sandbox/logs.zip"
fi
if [[ -f "$SB/check/app.log" && -f "$SB/check/error.log" && -f "$SB/check/access.log" ]]; then
  ok "3.3 verified the archive by unzipping it into check/"
else
  no "3.3 unzip logs.zip into ~/sandbox/check (unzip logs.zip -d ~/sandbox/check)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can wrangle files like an engineer cleaning up after a bad deploy."

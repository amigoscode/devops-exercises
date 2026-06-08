#!/usr/bin/env bash
# Runs INSIDE the container. Grades the auto-checkable Terminal tasks.
# (The muscle-memory drills in the README are self-checked - no artifact to grade.)
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=01-the-terminal' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }

echo "Tier 1 - Tab completion"
if [[ -f "$SB/srv/var/log/nginx-application-server/checked.txt" ]]; then
  ok "1.3 reached the deep dir and created checked.txt"
else
  no "1.3 checked.txt not found - tab-complete your way into the deep path and create it"
fi

echo "Tier 2 - Command history"
if [[ -f "$SB/session.log" ]] \
   && grep -q "step-1-build" "$SB/session.log" \
   && grep -q "step-2-test"  "$SB/session.log" \
   && grep -q "step-3-deploy" "$SB/session.log"; then
  ok "2.1 session.log captured your command history"
else
  no "2.1 session.log missing the 3 build/test/deploy commands (use: history > ~/sandbox/session.log)"
fi
if [[ -f "$SB/recall.txt" ]] && grep -q "found-via-ctrl-r" "$SB/recall.txt"; then
  ok "2.2 recalled & ran the planted command (Ctrl+R)"
else
  no "2.2 recall.txt missing - use Ctrl+R to find the planted command and run it"
fi

echo "Tier 3 - On-call fluency"
if [[ -f "$SB/errors-found.txt" ]] && grep -q "ERROR" "$SB/errors-found.txt"; then
  ok "3.1 re-ran the diagnostic; errors captured"
else
  no "3.1 errors-found.txt missing - recall and re-run the ERROR-grep command from history"
fi
if [[ -f "$SB/runbook.md" ]] && grep -q 'grep -r "ERROR"' "$SB/runbook.md"; then
  ok "3.2 documented the command in runbook.md"
else
  no "3.2 runbook.md must contain the exact diagnostic command you ran"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You move around the terminal like it's home."
